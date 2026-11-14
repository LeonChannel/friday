// Resumo: Prova o script de hook de verdade: entrega ao servidor, sai 0 rápido com o Friday fechado e não trava com servidor parado.
// Tags: testes, sensor

import Darwin
import Foundation
import Testing
@testable import FridayInfrastructure

/// Resultado de rodar o script de hook como o agente faz.
struct HookRun {
    let status: Int32
    let elapsed: Duration
}

/// Roda o script com o JSON no stdin e o ambiente do Friday.
func runHookScript(_ script: URL, agent: String = "claude", session: String?, socket: String?, stdin: Data) throws -> HookRun {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/sh")
    process.arguments = [script.path, agent]
    var environment = ["PATH": "/usr/bin:/bin"]
    if let session { environment["FRIDAY_SESSION_ID"] = session }
    if let socket { environment["FRIDAY_HOOK_SOCKET"] = socket }
    process.environment = environment
    let input = Pipe()
    process.standardInput = input
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    let clock = ContinuousClock()
    let start = clock.now
    try process.run()
    input.fileHandleForWriting.write(stdin)
    try input.fileHandleForWriting.close()
    process.waitUntilExit()
    return HookRun(status: process.terminationStatus, elapsed: start.duration(to: clock.now))
}

@Suite("HookScript")
struct HookScriptTests {
    static let session = "11111111-2222-4333-8444-555555555555"

    @Test func deliversHeaderAndRawJSONToServer() async throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let socket = dir.url.appendingPathComponent("run/h.sock").path
        let server = HookSocketServer(socketPath: socket)
        let stream = try await server.start()
        let script = try HookScript.install(in: dir.url.appendingPathComponent("hooks"))
        let payload = try FixtureLoader.claude("pre-tool-use")

        let run = try runHookScript(script, session: Self.session, socket: socket, stdin: payload)
        let message = await nextMessage(stream)
        #expect(run.status == 0)
        #expect(message?.data == Data("claude \(Self.session)\n".utf8) + payload)
        await server.stop()
    }

    @Test func exitsZeroAndFastWhenFridayIsClosed() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let script = try HookScript.install(in: dir.url.appendingPathComponent("hooks"))
        let missing = dir.url.appendingPathComponent("nao-existe.sock").path

        let run = try runHookScript(script, session: Self.session, socket: missing, stdin: Data("{}".utf8))
        #expect(run.status == 0)
        #expect(run.elapsed < .milliseconds(1000))
    }

    @Test func exitsZeroWhenSocketFileIsStale() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let script = try HookScript.install(in: dir.url.appendingPathComponent("hooks"))
        let stale = dir.url.appendingPathComponent("velho.sock")
        close(try listenWithoutAccepting(at: stale.path))

        let run = try runHookScript(script, session: Self.session, socket: stale.path, stdin: Data("{}".utf8))
        #expect(run.status == 0)
        #expect(run.elapsed < .milliseconds(1000))
    }

    @Test func exitsZeroOutsideAFridaySession() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let script = try HookScript.install(in: dir.url.appendingPathComponent("hooks"))
        let run = try runHookScript(script, session: nil, socket: nil, stdin: Data("{}".utf8))
        #expect(run.status == 0)
        #expect(run.elapsed < .milliseconds(1000))
    }

    @Test func doesNotHangWhenServerAcceptsButNeverAnswers() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let script = try HookScript.install(in: dir.url.appendingPathComponent("hooks"))
        let socket = dir.url.appendingPathComponent("parado.sock").path
        let listener = try listenWithoutAccepting(at: socket)
        defer { close(listener) }

        let run = try runHookScript(script, session: Self.session, socket: socket, stdin: Data("{}".utf8))
        #expect(run.status == 0)
        #expect(run.elapsed < .milliseconds(2500))
    }

    @Test func installedScriptIsExecutableOnlyByOwner() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let script = try HookScript.install(in: dir.url.appendingPathComponent("hooks"))
        let mode = try FileManager.default.attributesOfItem(atPath: script.path)[.posixPermissions] as? Int
        #expect(mode == 0o700)
    }
}

/// Socket em escuta que nunca chama `accept`: a conexão entra na fila do kernel e fica sem resposta.
private func listenWithoutAccepting(at path: String) throws -> Int32 {
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    var address = sockaddr_un()
    address.sun_family = sa_family_t(AF_UNIX)
    withUnsafeMutableBytes(of: &address.sun_path) { buffer in
        buffer.copyBytes(from: path.utf8)
        buffer[path.utf8.count] = 0
    }
    let bound = withUnsafePointer(to: &address) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
    }
    guard bound == 0, listen(fd, 8) == 0 else { throw HookSocketError.system("bind", errno) }
    return fd
}

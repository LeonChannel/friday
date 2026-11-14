// Resumo: Integração com processo real curto no LocalProcess do SwiftTerm, sem view: a saída chega, a pasta é a certa e o término é detectado.
// Tags: terminal, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import SwiftTerm
import Testing

/// Junta a saída e o código de saída e avisa por `AsyncStream`, para o teste esperar o evento e não um prazo fixo.
private final class RecordingDelegate: LocalProcessDelegate, @unchecked Sendable {
    // SAFETY: todos os callbacks chegam na fila serial passada ao LocalProcess; o teste só lê depois do evento de saída.
    private(set) var output = Data()
    let exits: AsyncStream<Int32?>
    private let continuation: AsyncStream<Int32?>.Continuation

    init() { (exits, continuation) = AsyncStream.makeStream() }

    func processTerminated(_ source: LocalProcess, exitCode: Int32?) { continuation.yield(exitCode); continuation.finish() }
    func dataReceived(slice: ArraySlice<UInt8>) { output.append(contentsOf: slice) }
    func getWindowSize() -> winsize { winsize(ws_row: 24, ws_col: 80, ws_xpixel: 0, ws_ypixel: 0) }
}

@Suite(.tags(.integration))
struct LocalProcessIntegrationTests {
    private func run(_ plan: LaunchPlan) async throws -> (text: String, code: Int32?) {
        let delegate = RecordingDelegate()
        let process = LocalProcess(delegate: delegate, dispatchQueue: DispatchQueue(label: "friday.test.process"))
        process.startProcess(
            executable: plan.executable,
            args: plan.arguments,
            environment: plan.environment.map { "\($0.key)=\($0.value)" },
            currentDirectory: plan.workingDirectory
        )
        let code = try await withTimeout(seconds: 10) {
            for await code in delegate.exits { return code }
            return nil
        }
        return (String(decoding: delegate.output, as: UTF8.self), code)
    }

    @Test func echoOutputArrivesAndExitIsDetected() async throws {
        let plan = LaunchPlan(executable: "/bin/echo", arguments: ["friday-ok"], environment: ["TERM": "xterm-256color"], workingDirectory: "/tmp")
        let result = try await run(plan)
        #expect(result.text.contains("friday-ok"))
        #expect(result.code == 0)
    }

    @Test func processStartsInProjectFolderWithFridayVariables() async throws {
        let dir = try TemporaryFolder()
        defer { dir.remove() }
        let planner = DefaultLaunchPlanner(userShell: "/bin/sh")
        let session = AgentSessionID()
        let project = Project(name: "t", path: dir.path, kind: .folder, addedAt: .now)
        var plan = try planner.plan(agent: .shell, project: project, session: session)
        // Troca o shell interativo por um comando curto, mantendo pasta e ambiente do planner.
        plan.arguments = ["-c", "pwd -P; echo $FRIDAY_AGENT $FRIDAY_SESSION_ID"]
        let result = try await run(plan)
        #expect(result.text.contains(dir.path))
        #expect(result.text.contains("shell \(session)"))
        #expect(result.code == 0)
    }

    @Test func exitCodeIsReported() async throws {
        let plan = LaunchPlan(executable: "/bin/sh", arguments: ["-c", "exit 7"], environment: [:], workingDirectory: "/tmp")
        #expect(try await run(plan).code == 7)
    }

    @Test func terminateKillsLongRunningProcess() async throws {
        let delegate = RecordingDelegate()
        let process = LocalProcess(delegate: delegate, dispatchQueue: DispatchQueue(label: "friday.test.kill"))
        process.startProcess(executable: "/bin/sleep", args: ["60"], environment: [], currentDirectory: "/tmp")
        #expect(process.running)
        process.terminate()
        let code = try await withTimeout(seconds: 10) {
            for await code in delegate.exits { return code }
            return Int32?.none
        }
        #expect(code == nil) // morreu por sinal
        #expect(!process.running)
    }
}


private struct TimedOut: Error {}

private func withTimeout<T: Sendable>(seconds: Double, _ body: @escaping @Sendable () async -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { await body() }
        group.addTask { try await Task.sleep(for: .seconds(seconds)); throw TimedOut() }
        defer { group.cancelAll() }
        return try await group.next()!
    }
}

private struct TemporaryFolder {
    let path: String
    init() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("friday-term-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        path = url.resolvingSymlinksInPath().path
    }
    func remove() { try? FileManager.default.removeItem(atPath: path) }
}

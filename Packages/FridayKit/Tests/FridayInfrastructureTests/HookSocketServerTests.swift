// Resumo: Testa o servidor de socket dos hooks: ida e volta, permissões, lixo, limite de tamanho e cliente parado.
// Tags: testes, sensor

import Darwin
import Foundation
import Testing
@testable import FridayInfrastructure

/// Cliente de teste: conecta, envia bytes e fecha (ou não).
func sendToSocket(path: String, bytes: Data, closeAfterSend: Bool = true) -> Int32? {
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    guard fd >= 0 else { return nil }
    var address = sockaddr_un()
    address.sun_family = sa_family_t(AF_UNIX)
    withUnsafeMutableBytes(of: &address.sun_path) { buffer in
        buffer.copyBytes(from: path.utf8)
        buffer[path.utf8.count] = 0
    }
    let connected = withUnsafePointer(to: &address) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
    }
    guard connected == 0 else { close(fd); return nil }
    bytes.withUnsafeBytes { _ = write(fd, $0.baseAddress, bytes.count) }
    if closeAfterSend { close(fd); return 0 }
    return fd
}

/// Espera a próxima mensagem do fluxo, com limite de tempo.
func nextMessage(_ stream: AsyncStream<HookMessage>, timeout: Duration = .seconds(5)) async -> HookMessage? {
    await withTaskGroup(of: HookMessage?.self) { group in
        group.addTask {
            var iterator = stream.makeAsyncIterator()
            return await iterator.next()
        }
        group.addTask {
            try? await Task.sleep(for: timeout)
            return nil
        }
        let first = await group.next() ?? nil
        group.cancelAll()
        return first
    }
}

@Suite("HookSocketServer")
struct HookSocketServerTests {
    @Test func deliversOneMessagePerConnection() async throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let path = dir.url.appendingPathComponent("run/h.sock").path
        let server = HookSocketServer(socketPath: path)
        let stream = try await server.start()

        #expect(sendToSocket(path: path, bytes: Data("claude abc\n{\"a\":1}".utf8)) != nil)
        let message = await nextMessage(stream)
        #expect(message.map { String(decoding: $0.data, as: UTF8.self) } == "claude abc\n{\"a\":1}")
        await server.stop()
    }

    @Test func createsPrivateDirectoryAndSocket() async throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let runDir = dir.url.appendingPathComponent("run")
        let server = HookSocketServer(socketPath: runDir.appendingPathComponent("h.sock").path)
        _ = try await server.start()

        let dirMode = try FileManager.default.attributesOfItem(atPath: runDir.path)[.posixPermissions] as? Int
        let socketMode = try FileManager.default.attributesOfItem(atPath: runDir.appendingPathComponent("h.sock").path)[.posixPermissions] as? Int
        #expect(dirMode == 0o700)
        #expect(socketMode == 0o600)
        await server.stop()
        #expect(!FileManager.default.fileExists(atPath: runDir.appendingPathComponent("h.sock").path))
    }

    @Test func tightensLooseExistingDirectory() async throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let runDir = dir.url.appendingPathComponent("run")
        try FileManager.default.createDirectory(at: runDir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o755])
        let server = HookSocketServer(socketPath: runDir.appendingPathComponent("h.sock").path)
        _ = try await server.start()
        let mode = try FileManager.default.attributesOfItem(atPath: runDir.path)[.posixPermissions] as? Int
        #expect(mode == 0o700)
        await server.stop()
    }

    @Test func ignoresEmptyConnectionsAndKeepsServing() async throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let path = dir.url.appendingPathComponent("h.sock").path
        let server = HookSocketServer(socketPath: path)
        let stream = try await server.start()

        _ = sendToSocket(path: path, bytes: Data())
        _ = sendToSocket(path: path, bytes: Data("ok".utf8))
        let message = await nextMessage(stream)
        #expect(message.map { String(decoding: $0.data, as: UTF8.self) } == "ok")
        await server.stop()
    }

    @Test func dropsMessageOverSizeLimit() async throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let path = dir.url.appendingPathComponent("h.sock").path
        let server = HookSocketServer(socketPath: path, maxMessageBytes: 1024)
        let stream = try await server.start()

        _ = sendToSocket(path: path, bytes: Data(repeating: 0x41, count: 4096))
        _ = sendToSocket(path: path, bytes: Data("pequena".utf8))
        let message = await nextMessage(stream)
        #expect(message.map { String(decoding: $0.data, as: UTF8.self) } == "pequena")
        await server.stop()
    }

    @Test func cutsClientThatNeverFinishes() async throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let path = dir.url.appendingPathComponent("h.sock").path
        let server = HookSocketServer(socketPath: path, readTimeoutSeconds: 1)
        let stream = try await server.start()

        let stuck = sendToSocket(path: path, bytes: Data("parcial".utf8), closeAfterSend: false)
        #expect(stuck != nil)
        _ = sendToSocket(path: path, bytes: Data("inteira".utf8))
        let message = await nextMessage(stream)
        #expect(message.map { String(decoding: $0.data, as: UTF8.self) } == "inteira")
        if let stuck { close(stuck) }
        await server.stop()
    }

    @Test func rejectsPathLongerThanSunPath() async throws {
        let server = HookSocketServer(socketPath: "/tmp/" + String(repeating: "x", count: 120) + "/h.sock")
        await #expect(throws: HookSocketError.pathTooLong) { _ = try await server.start() }
    }

    @Test func liveLocationsAlwaysFitSocketLimit() throws {
        let locations = try SensorLocations.live()
        #expect(locations.socketPath.utf8.count <= SensorLocations.maxSocketPathBytes)
    }
}

// Resumo: Prova a cota de ponta a ponta: o script da statusline manda o JSON ao socket, o sensor grava a cota e devolve a statusline do usuário intacta.
// Tags: cota, sensor, testes

import FridayDomain
import Foundation
import GRDB
import Testing
@testable import FridayInfrastructure

@Suite("Cota", .tags(.integration))
struct UsageQuotaFlowTests {
    /// Roda a statusline do Friday como o Claude Code faz: JSON no stdin, ambiente da sessão; devolve o que ela imprimiu.
    private func runStatusline(_ script: URL, environment: [String: String], stdin: Data) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [script.path]
        process.environment = environment
        let input = Pipe(), output = Pipe()
        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        try process.run()
        input.fileHandleForWriting.write(stdin)
        try input.fileHandleForWriting.close()
        let printed = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(decoding: printed, as: UTF8.self)
    }

    @Test func statuslineFeedsQuotaAndKeepsUserStatusline() async throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let locations = SensorLocations(root: dir.url)
        let database = try AppDatabase.inMemory()
        let quotas = GRDBUsageQuotaRepository(database: database)
        let service = SensorService(server: HookSocketServer(socketPath: locations.socketPath), repository: GRDBAgentEventRepository(database: database), quotas: quotas)
        try await service.start()

        // statusline "do usuário" num home falso: prova que ela continua rodando com o mesmo JSON.
        let home = dir.url.appendingPathComponent("home")
        try FileManager.default.createDirectory(at: home.appendingPathComponent(".claude"), withIntermediateDirectories: true)
        try Data(#"{"statusLine":{"type":"command","command":"printf 'minha:'; wc -c | tr -d ' '"}}"#.utf8)
            .write(to: home.appendingPathComponent(".claude/settings.json"))
        let session = AgentSessionID()
        let hooks = ClaudeSessionHooks(locations: locations, home: home.path)
        _ = try hooks.extraArguments(agent: .claude, session: session)
        var environment = try hooks.extraEnvironment(agent: .claude, session: session)
        #expect(environment["FRIDAY_STATUSLINE_NEXT"] == "printf 'minha:'; wc -c | tr -d ' '")
        environment["FRIDAY_SESSION_ID"] = session.description
        environment["PATH"] = "/usr/bin:/bin"
        environment["TMPDIR"] = dir.url.path

        let settings = try JSONSerialization.jsonObject(with: Data(contentsOf: locations.sessionsDirectory.appendingPathComponent("\(session).settings.json"))) as? [String: Any]
        let statusLine = try #require(settings?["statusLine"] as? [String: String])
        #expect(statusLine["type"] == "command")
        let script = locations.hooksDirectory.appendingPathComponent(StatuslineScript.fileName)
        #expect(statusLine["command"] == "'\(script.path)'")

        let tests = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let payload = try Data(contentsOf: tests.appendingPathComponent("Fixtures/claude/statusline.json"))
        let stream = quotas.observeLatest()
        let printed = try runStatusline(script, environment: environment, stdin: payload)
        // O shell tira a quebra de linha final ($(cat)); o JSON que a statusline do usuário recebe é o mesmo.
        let jsonBytes = String(decoding: payload, as: UTF8.self).trimmingCharacters(in: .newlines).utf8.count
        #expect(printed.trimmingCharacters(in: .whitespacesAndNewlines) == "minha:\(jsonBytes)")

        var saved: UsageQuota?
        for try await quota in stream where quota != nil { saved = quota; break }
        #expect(saved?.fiveHour?.usedPercentage == 26 && saved?.sevenDay?.usedPercentage == 39)
        await service.stop()
    }

    @Test func withoutUserStatuslineOrFridayPrintsNothingAndExitsZero() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let script = try StatuslineScript.install(in: dir.url)
        #expect(try runStatusline(script, environment: ["PATH": "/usr/bin:/bin"], stdin: Data("{}".utf8)).isEmpty)
        #expect(StatuslineScript.userCommand(home: dir.url.path) == nil)
    }

    @Test func repositoryKeepsOnlyLatest() throws {
        let database = try AppDatabase.inMemory()
        let quotas = GRDBUsageQuotaRepository(database: database)
        let a = UsageQuota(fiveHour: QuotaWindow(usedPercentage: 10, resetsAt: Date(timeIntervalSince1970: 2_000)), sevenDay: nil, capturedAt: Date(timeIntervalSince1970: 1_000))
        let b = UsageQuota(fiveHour: nil, sevenDay: QuotaWindow(usedPercentage: 55, resetsAt: Date(timeIntervalSince1970: 9_000)), capturedAt: Date(timeIntervalSince1970: 1_500))
        try quotas.save(a)
        try quotas.save(b)
        #expect(try database.writer.read { try Int.fetchOne($0, sql: "SELECT COUNT(*) FROM usageQuota") } == 1)
    }
}

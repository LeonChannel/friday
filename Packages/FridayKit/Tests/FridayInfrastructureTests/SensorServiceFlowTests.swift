// Resumo: Teste de fluxo do sensor: o script de hook envia payloads reais do Claude pelo socket e eles aparecem gravados, sem lixo.
// Tags: testes, sensor, persistencia

import FridayDomain
import Foundation
import Testing
@testable import FridayInfrastructure

@Suite("SensorService")
struct SensorServiceFlowTests {
    @Test func realPayloadsSentByScriptEndUpRecorded() async throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let locations = SensorLocations(root: dir.url)
        let repository = GRDBAgentEventRepository(database: try .inMemory())
        let service = SensorService(server: HookSocketServer(socketPath: locations.socketPath), repository: repository)
        try await service.start()

        let session = AgentSessionID()
        let project = Project(name: "p", path: "/", kind: .folder, addedAt: .distantPast)
        let plan = try DefaultLaunchPlanner(customizer: ClaudeSessionHooks(locations: locations)).plan(agent: .claude, project: project, session: session)
        let script = locations.hooksDirectory.appendingPathComponent(HookScript.fileName)
        let stream = repository.observe(session: session)

        for name in ["session-start", "user-prompt-submit", "pre-tool-use", "post-tool-use", "stop", "future-event.synthetic"] {
            let run = try runHookScript(
                script, session: plan.environment["FRIDAY_SESSION_ID"], socket: plan.environment["FRIDAY_SOCKET"],
                stdin: try FixtureLoader.claude(name)
            )
            #expect(run.status == 0)
        }
        _ = sendToSocket(path: locations.socketPath, bytes: Data("lixo sem formato".utf8))

        var recorded: [AgentEvent] = []
        for try await events in stream {
            recorded = events
            if events.count == 6 { break }
        }
        #expect(Set(recorded.map(\.kind)) == [.sessionStart, .userPromptSubmit, .preToolUse, .postToolUse, .stop, .unknown("EventoDoFuturo")])
        #expect(recorded.first { $0.kind == .preToolUse }?.target == "echo oi")
        await service.stop()
    }
}

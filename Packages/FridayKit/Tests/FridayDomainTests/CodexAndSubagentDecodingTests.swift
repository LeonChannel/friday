// Resumo: Prova que o decoder entende os payloads reais do Codex e identifica subagentes do Claude pelo tipo e pela descrição.
// Tags: testes, sensor, agentes

import Foundation
import Testing
@testable import FridayDomain

@Suite("Decoder: Codex e subagentes")
struct CodexAndSubagentDecodingTests {
    static let sessionID = "11111111-2222-7333-8444-555555555555"
    static let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func codex(_ fixture: String) throws -> AgentEvent {
        try AgentEventDecoder.decode(Data("codex \(Self.sessionID)\n".utf8) + FixtureLoader.codex(fixture), receivedAt: Self.now)
    }

    private func claude(_ fixture: String) throws -> AgentEvent {
        try AgentEventDecoder.decode(
            Data("claude 11111111-2222-4333-8444-555555555555\n".utf8) + FixtureLoader.claude(fixture), receivedAt: Self.now
        )
    }

    @Test(arguments: [
        ("session-start", AgentEventKind.sessionStart),
        ("user-prompt-submit", .userPromptSubmit),
        ("pre-tool-use", .preToolUse),
        ("post-tool-use", .postToolUse),
        ("stop", .stop),
    ])
    func mapsCodexHookNames(fixture: String, expected: AgentEventKind) throws {
        let event = try codex(fixture)
        #expect(event.kind == expected)
        #expect(event.agent == .codex)
        #expect(event.sessionID.description == Self.sessionID)
    }

    @Test func readsCodexToolAndCommand() throws {
        let event = try codex("post-tool-use")
        #expect(event.toolName == "Bash")
        #expect(event.target == "echo oi")
    }

    @Test func mapsPermissionRequestAndKeepsUnmappedCodexNames() throws {
        #expect(AgentEventKind(hookName: "PermissionRequest") == .permissionRequest)
        #expect(AgentEventKind.permissionRequest.hookName == "PermissionRequest")
        #expect(AgentEventKind(hookName: "SubagentStart") == .unknown("SubagentStart"))
        let start = try claude("subagent-start")
        #expect(start.kind == .unknown("SubagentStart"))
        #expect(start.rawJSON.contains("general-purpose"))
    }

    @Test func identifiesClaudeSubagentByTypeAndDescription() throws {
        let event = try claude("subagent-stop")
        #expect(event.kind == .subagentStop)
        #expect(event.toolName == "general-purpose")
        #expect(event.target == "Dizer oi")
    }

    @Test func subagentWithoutTypeOrTaskStaysUnidentifiedButKept() throws {
        let event = try claude("subagent-stop.synthetic")
        #expect(event.kind == .subagentStop)
        #expect(event.toolName == nil)
        #expect(event.target == nil)
        #expect(event.rawJSON.contains("agente-exemplo"))
    }

    @Test func permissionRequestMakesTheSessionWaitForYou() {
        let event = AgentEvent(sessionID: AgentSessionID(), agent: .codex, kind: .permissionRequest, occurredAt: Self.now, rawJSON: "{}")
        #expect(SessionActivity(events: [event]).phase == .waitingForYou)
    }
}

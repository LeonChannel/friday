// Resumo: Testa a leitura de payloads reais do Claude Code (e de eventos desconhecidos) e a rejeição de mensagens inválidas.
// Tags: testes, sensor

import Foundation
import Testing
@testable import FridayDomain

@Suite("AgentEventDecoder")
struct AgentEventDecoderTests {
    static let sessionID = "11111111-2222-4333-8444-555555555555"
    static let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func message(agent: String = "claude", session: String = sessionID, fixture: String) throws -> Data {
        Data("\(agent) \(session)\n".utf8) + (try FixtureLoader.claude(fixture))
    }

    @Test(arguments: [
        ("session-start", AgentEventKind.sessionStart),
        ("user-prompt-submit", .userPromptSubmit),
        ("pre-tool-use", .preToolUse),
        ("post-tool-use", .postToolUse),
        ("stop", .stop),
        ("session-end", .sessionEnd),
        ("notification.synthetic", .notification),
        ("subagent-stop.synthetic", .subagentStop),
        ("pre-compact.synthetic", .preCompact),
    ])
    func mapsEveryKnownHookKind(fixture: String, expected: AgentEventKind) throws {
        let event = try AgentEventDecoder.decode(message(fixture: fixture), receivedAt: Self.now)
        #expect(event.kind == expected)
        #expect(event.agent == .claude)
        #expect(event.sessionID.description == Self.sessionID)
        #expect(event.occurredAt == Self.now)
    }

    @Test func extractsToolAndCommandFromPreToolUse() throws {
        let event = try AgentEventDecoder.decode(message(fixture: "pre-tool-use"), receivedAt: Self.now)
        #expect(event.toolName == "Bash")
        #expect(event.target == "echo oi")
    }

    @Test func keepsRawPayloadUntouched() throws {
        let raw = try FixtureLoader.claude("stop")
        let event = try AgentEventDecoder.decode(Data("claude \(Self.sessionID)\n".utf8) + raw, receivedAt: Self.now)
        #expect(event.rawJSON == String(decoding: raw, as: UTF8.self))
    }

    @Test func keepsUnknownEventInsteadOfDroppingIt() throws {
        let event = try AgentEventDecoder.decode(message(fixture: "future-event.synthetic"), receivedAt: Self.now)
        #expect(event.kind == .unknown("EventoDoFuturo"))
        #expect(event.kind.hookName == "EventoDoFuturo")
    }

    @Test func truncatesVeryLongTarget() throws {
        let long = String(repeating: "a", count: 5000)
        let body = #"{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"\#(long)"}}"#
        let event = try AgentEventDecoder.decode(Data("claude \(Self.sessionID)\n\(body)".utf8), receivedAt: Self.now)
        #expect(event.target?.count == AgentEventDecoder.maxTargetLength)
        #expect(event.rawJSON.contains(long))
    }

    @Test func rejectsGarbage() throws {
        let decode = { (data: Data) in try AgentEventDecoder.decode(data, receivedAt: Self.now) }
        #expect(throws: AgentEventDecodingError.malformedHeader) { try decode(Data("sem quebra de linha".utf8)) }
        #expect(throws: AgentEventDecodingError.malformedHeader) { try decode(Data("claude\n{}".utf8)) }
        #expect(throws: AgentEventDecodingError.unsupportedAgent) { try decode(Data("gemini \(Self.sessionID)\n{}".utf8)) }
        #expect(throws: AgentEventDecodingError.unsupportedAgent) { try decode(Data("shell \(Self.sessionID)\n{}".utf8)) }
        #expect(throws: AgentEventDecodingError.invalidSessionID) { try decode(Data("claude nao-e-uuid\n{}".utf8)) }
        #expect(throws: AgentEventDecodingError.payloadIsNotJSONObject) { try decode(Data("claude \(Self.sessionID)\nnão é json".utf8)) }
        #expect(throws: AgentEventDecodingError.payloadIsNotJSONObject) { try decode(Data("claude \(Self.sessionID)\n[1,2]".utf8)) }
    }
}

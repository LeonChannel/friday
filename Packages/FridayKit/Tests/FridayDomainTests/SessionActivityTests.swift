// Resumo: Prova que a fase da sessão, os arquivos alterados e as contagens saem certos de uma sequência de eventos.
// Tags: linha-do-tempo, testes

import FridayDomain
import Foundation
import Testing

struct SessionActivityTests {
    private let session = AgentSessionID()

    private func event(_ kind: AgentEventKind, at second: Double, tool: String? = nil, target: String? = nil) -> AgentEvent {
        AgentEvent(sessionID: session, agent: .claude, kind: kind, occurredAt: Date(timeIntervalSince1970: second), toolName: tool, target: target, rawJSON: "{}")
    }

    @Test func noEventsIsStarting() {
        #expect(SessionActivity(events: []).phase == .starting)
    }

    @Test(arguments: [
        ([AgentEventKind.sessionStart], SessionPhase.waitingForYou),
        ([.sessionStart, .userPromptSubmit], .working),
        ([.sessionStart, .userPromptSubmit, .preToolUse, .postToolUse], .working),
        ([.sessionStart, .userPromptSubmit, .stop], .waitingForYou),
        ([.userPromptSubmit, .notification], .waitingForYou),
        ([.userPromptSubmit, .stop, .sessionEnd], .finished),
        ([.userPromptSubmit, .unknown("Novo")], .working),
    ])
    func phaseFollowsTheLastMeaningfulEvent(kinds: [AgentEventKind], expected: SessionPhase) {
        let events = kinds.enumerated().map { event($1, at: Double($0)) }
        #expect(SessionActivity(events: events).phase == expected)
    }

    @Test func changedFilesComeOnlyFromWritingToolsWithoutRepeats() {
        let activity = SessionActivity(events: [
            event(.userPromptSubmit, at: 0),
            event(.postToolUse, at: 1, tool: "Read", target: "/p/a.swift"),
            event(.postToolUse, at: 2, tool: "Edit", target: "/p/b.swift"),
            event(.postToolUse, at: 3, tool: "Bash", target: "swift test"),
            event(.postToolUse, at: 4, tool: "Write", target: "/p/c.swift"),
            event(.postToolUse, at: 5, tool: "Edit", target: "/p/b.swift"),
        ])
        #expect(activity.changedFiles == ["/p/b.swift", "/p/c.swift"])
        #expect(activity.toolUses == 5)
        #expect(activity.prompts == 1)
        #expect(activity.lastEventAt == Date(timeIntervalSince1970: 5))
    }

    @Test func orderOfArrivalDoesNotMatter() {
        let events = [event(.stop, at: 3), event(.userPromptSubmit, at: 1), event(.preToolUse, at: 2)]
        #expect(SessionActivity(events: events).phase == .waitingForYou)
    }
}

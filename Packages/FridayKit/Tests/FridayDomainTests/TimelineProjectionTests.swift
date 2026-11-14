// Resumo: Prova o agrupamento de SubagentStop consecutivos na linha do tempo e que outros eventos quebram o grupo.
// Tags: testes, linha-do-tempo

import Foundation
import Testing
@testable import FridayDomain

@Suite("TimelineProjection")
struct TimelineProjectionTests {
    private let session = AgentSessionID()

    private func event(_ kind: AgentEventKind, at second: Double, type: String? = nil, description: String? = nil) -> AgentEvent {
        AgentEvent(
            id: Int64(second), sessionID: session, agent: .claude, kind: kind,
            occurredAt: Date(timeIntervalSince1970: second), toolName: type, target: description, rawJSON: "{}"
        )
    }

    @Test func groupsConsecutiveSubagentStopsIntoOneEntry() {
        let events = [
            event(.userPromptSubmit, at: 1),
            event(.subagentStop, at: 2, type: "Explore", description: "Mapear A"),
            event(.subagentStop, at: 3, type: "Explore", description: "Mapear B"),
            event(.subagentStop, at: 4, type: "Plan"),
            event(.stop, at: 5),
        ]
        let entries = TimelineProjection.entries(from: events)
        #expect(entries.count == 3)
        let group = entries[1]
        #expect(group.isSubagentGroup)
        #expect(group.count == 3)
        #expect(group.subagentTypes == ["Explore", "Plan"])
        #expect(group.subagentDescriptions == ["Mapear A", "Mapear B"])
        #expect(group.last.occurredAt == Date(timeIntervalSince1970: 4))
    }

    @Test func anotherEventBetweenSubagentsSplitsTheGroup() {
        let events = [event(.subagentStop, at: 1), event(.postToolUse, at: 2), event(.subagentStop, at: 3)]
        #expect(TimelineProjection.entries(from: events).map(\.count) == [1, 1, 1])
    }

    @Test func otherRepeatedEventsAreNotGrouped() {
        let events = [event(.postToolUse, at: 1), event(.postToolUse, at: 2)]
        #expect(TimelineProjection.entries(from: events).count == 2)
    }

    @Test func ordersByTimeBeforeGrouping() {
        let events = [event(.subagentStop, at: 3), event(.subagentStop, at: 1), event(.stop, at: 2)]
        #expect(TimelineProjection.entries(from: events).map(\.count) == [1, 1, 1])
    }

    @Test func fifteenStopsCollapseIntoOneLine() {
        let events = (1...15).map { event(.subagentStop, at: Double($0)) }
        let entries = TimelineProjection.entries(from: events)
        #expect(entries.count == 1)
        #expect(entries[0].count == 15)
    }

    @Test func entryIDsAreUnique() {
        let events = [event(.subagentStop, at: 1), event(.stop, at: 2), event(.subagentStop, at: 3)]
        let ids = TimelineProjection.entries(from: events).map(\.id)
        #expect(Set(ids).count == ids.count)
    }
}

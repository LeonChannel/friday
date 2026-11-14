// Resumo: Testa a gravação e a observação dos eventos dos agentes no banco em memória.
// Tags: testes, sensor, persistencia

import FridayDomain
import Foundation
import Testing
@testable import FridayInfrastructure

@Suite("GRDBAgentEventRepository")
struct GRDBAgentEventRepositoryTests {
    private func event(_ session: AgentSessionID, _ kind: AgentEventKind, at seconds: TimeInterval = 0) -> AgentEvent {
        AgentEvent(
            sessionID: session, agent: .claude, kind: kind,
            occurredAt: Date(timeIntervalSince1970: seconds), toolName: "Bash", target: "ls", rawJSON: "{\"k\":1}"
        )
    }

    private func first<T: Sendable>(_ stream: AsyncThrowingStream<T, any Error>, where predicate: @escaping @Sendable (T) -> Bool) async throws -> T? {
        for try await value in stream where predicate(value) { return value }
        return nil
    }

    @Test func recordAssignsIdAndRoundTripsFields() throws {
        let repository = GRDBAgentEventRepository(database: try .inMemory())
        let session = AgentSessionID()
        let saved = try repository.record(event(session, .unknown("Novo"), at: 42))
        #expect(saved.id != nil)
        #expect(saved.kind == .unknown("Novo"))
    }

    @Test func observeSessionYieldsOldestFirstAndFollowsNewEvents() async throws {
        let repository = GRDBAgentEventRepository(database: try .inMemory())
        let mine = AgentSessionID()
        try repository.record(event(mine, .sessionStart))
        try repository.record(event(AgentSessionID(), .stop))
        let stream = repository.observe(session: mine)
        try repository.record(event(mine, .stop))

        let events = try await first(stream) { $0.count == 2 }
        #expect(events?.map(\.kind) == [.sessionStart, .stop])
        #expect(events?.allSatisfy { $0.sessionID == mine } == true)
    }

    @Test func observeRecentYieldsNewestFirstWithLimit() async throws {
        let repository = GRDBAgentEventRepository(database: try .inMemory())
        let session = AgentSessionID()
        for kind in [AgentEventKind.sessionStart, .userPromptSubmit, .stop] { try repository.record(event(session, kind)) }

        let events = try await first(repository.observeRecent(limit: 2)) { _ in true }
        #expect(events?.map(\.kind) == [.stop, .userPromptSubmit])
    }
}

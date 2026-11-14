// Resumo: Guarda os eventos dos agentes no banco e avisa a tela a cada novo evento, por sessão ou os mais recentes de todas.
// Tags: sensor, persistencia

import FridayDomain
import Foundation
import GRDB

/// Eventos dos agentes no SQLite, com aviso ao vivo de cada mudança.
public struct GRDBAgentEventRepository: AgentEventRepository {
    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    @discardableResult
    public func record(_ event: AgentEvent) throws -> AgentEvent {
        var record = AgentEventRecord(event)
        try database.writer.write { db in try record.insert(db) }
        return record.event
    }

    public func observe(session: AgentSessionID) -> AsyncThrowingStream<[AgentEvent], any Error> {
        let id = session.description
        return stream(ValueObservation.tracking { db in
            try AgentEventRecord.filter(Column("sessionID") == id).order(Column("id")).fetchAll(db)
        })
    }

    public func observeRecent(limit: Int) -> AsyncThrowingStream<[AgentEvent], any Error> {
        stream(ValueObservation.tracking { db in
            try AgentEventRecord.order(Column("id").desc).limit(limit).fetchAll(db)
        })
    }

    private func stream(_ observation: ValueObservation<ValueReducers.Fetch<[AgentEventRecord]>>) -> AsyncThrowingStream<[AgentEvent], any Error> {
        let values = observation.values(in: database.writer)
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await records in values {
                        continuation.yield(records.map(\.event))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// Formato da linha no banco; existe para o tipo do Domain não depender do GRDB.
private struct AgentEventRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "agentEvent"

    var id: Int64?
    var sessionID: String
    var agent: String
    var kind: String
    var occurredAt: Date
    var toolName: String?
    var target: String?
    var rawJSON: String

    init(_ event: AgentEvent) {
        id = event.id
        sessionID = event.sessionID.description
        agent = event.agent.rawValue
        kind = event.kind.hookName
        occurredAt = event.occurredAt
        toolName = event.toolName
        target = event.target
        rawJSON = event.rawJSON
    }

    var event: AgentEvent {
        AgentEvent(
            id: id,
            sessionID: AgentSessionID(UUID(uuidString: sessionID) ?? UUID()),
            agent: AgentKind(rawValue: agent) ?? .claude,
            kind: AgentEventKind(hookName: kind),
            occurredAt: occurredAt,
            toolName: toolName,
            target: target,
            rawJSON: rawJSON
        )
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

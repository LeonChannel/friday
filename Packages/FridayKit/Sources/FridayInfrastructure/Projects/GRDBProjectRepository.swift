// Resumo: Guarda os projetos no banco e avisa a tela a cada mudança, sem ela precisar recarregar.
// Tags: projetos, persistencia

import FridayDomain
import Foundation
import GRDB

/// Projetos guardados no SQLite, com aviso ao vivo de cada mudança.
public struct GRDBProjectRepository: ProjectRepository {
    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func observeAll() -> AsyncThrowingStream<[Project], any Error> {
        let values = ValueObservation
            .tracking { db in try ProjectRecord.order(Column("lastOpenedAt").desc, Column("name").collating(.localizedCaseInsensitiveCompare)).fetchAll(db) }
            .values(in: database.writer)
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await records in values {
                        continuation.yield(records.map(\.project))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Todos os projetos agora, sem observar (a CLI usa para achar o projeto de uma pasta).
    public func all() throws -> [Project] {
        try database.writer.read { db in try ProjectRecord.fetchAll(db).map(\.project) }
    }

    public func contains(path: String) throws -> Bool {
        try database.writer.read { db in
            try ProjectRecord.filter(Column("path") == path).fetchCount(db) > 0
        }
    }

    @discardableResult
    public func insert(_ project: Project) throws -> Project {
        var record = ProjectRecord(project)
        try database.writer.write { db in try record.insert(db) }
        return record.project
    }

    public func delete(id: Int64) throws {
        _ = try database.writer.write { db in try ProjectRecord.deleteOne(db, key: id) }
    }

    public func markOpened(id: Int64, at date: Date) throws {
        try database.writer.write { db in
            try db.execute(sql: "UPDATE project SET lastOpenedAt = ? WHERE id = ?", arguments: [date, id])
        }
    }
}

/// Formato da linha no banco; existe para o tipo do Domain não depender do GRDB.
private struct ProjectRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "project"

    var id: Int64?
    var name: String
    var path: String
    var kind: ProjectKind
    var addedAt: Date
    var lastOpenedAt: Date?

    init(_ project: Project) {
        id = project.id
        name = project.name
        path = project.path
        kind = project.kind
        addedAt = project.addedAt
        lastOpenedAt = project.lastOpenedAt
    }

    var project: Project {
        Project(id: id, name: name, path: path, kind: kind, addedAt: addedAt, lastOpenedAt: lastOpenedAt)
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

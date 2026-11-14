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
            .tracking { db in try ProjectRecord.order(Column("name").collating(.localizedCaseInsensitiveCompare)).fetchAll(db) }
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
}

/// Formato da linha no banco; existe para o tipo do Domain não depender do GRDB.
private struct ProjectRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "project"

    var id: Int64?
    var name: String
    var path: String
    var kind: ProjectKind
    var addedAt: Date

    init(_ project: Project) {
        id = project.id
        name = project.name
        path = project.path
        kind = project.kind
        addedAt = project.addedAt
    }

    var project: Project {
        Project(id: id, name: name, path: path, kind: kind, addedAt: addedAt)
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

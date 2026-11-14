// Resumo: Banco SQLite do Friday: onde o arquivo fica no disco e as migrações que montam as tabelas.
// Tags: persistencia

import Foundation
import GRDB

/// O banco SQLite do Friday, já com todas as migrações aplicadas.
public struct AppDatabase: Sendable {
    let writer: any DatabaseWriter

    public init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try Self.migrator.migrate(writer)
    }

    /// Banco descartável em memória, para testes e prévias.
    public static func inMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue())
    }

    /// `~/Library/Application Support/Friday/friday.sqlite`
    public static func live() throws -> AppDatabase {
        let dir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Friday", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return try open(path: dir.appendingPathComponent("friday.sqlite").path)
    }

    /// Abre (e migra) o banco no caminho dado; app e CLI podem abrir o mesmo arquivo ao mesmo tempo (WAL, espera de até 5 s por trava).
    public static func open(path: String) throws -> AppDatabase {
        var configuration = Configuration()
        configuration.busyMode = .timeout(5)
        return try AppDatabase(DatabasePool(path: path, configuration: configuration))
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1-projects") { db in
            try db.create(table: "project") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("path", .text).notNull().unique()
                t.column("addedAt", .datetime).notNull()
            }
        }
        migrator.registerMigration("v2-project-kind") { db in
            try db.alter(table: "project") { t in
                t.add(column: "kind", .text).notNull().defaults(to: "folder")
            }
        }
        migrator.registerMigration("v3-agent-events") { db in
            try db.create(table: "agentEvent") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("sessionID", .text).notNull()
                t.column("agent", .text).notNull()
                t.column("kind", .text).notNull()
                t.column("occurredAt", .datetime).notNull()
                t.column("toolName", .text)
                t.column("target", .text)
                t.column("rawJSON", .text).notNull()
            }
            try db.create(index: "agentEvent_session", on: "agentEvent", columns: ["sessionID", "id"])
        }
        migrator.registerMigration("v4-subjects") { db in
            try db.create(table: "subject") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text).notNull()
                t.column("projectID", .integer).references("project", onDelete: .setNull)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("intent", .text).notNull()
                t.column("partsJSON", .text).notNull()
                t.column("turn", .text).notNull()
                t.column("turnReason", .text).notNull()
            }
            try db.create(index: "subject_turn", on: "subject", columns: ["turn", "updatedAt"])
        }
        migrator.registerMigration("v5-project-last-opened") { db in
            try db.alter(table: "project") { t in
                t.add(column: "lastOpenedAt", .datetime)
            }
        }
        return migrator
    }
}

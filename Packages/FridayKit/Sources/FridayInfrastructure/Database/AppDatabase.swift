import Foundation
import GRDB

public struct AppDatabase: Sendable {
    let writer: any DatabaseWriter

    public init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try Self.migrator.migrate(writer)
    }

    public static func inMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue())
    }

    /// `~/Library/Application Support/Friday/friday.sqlite`
    public static func live() throws -> AppDatabase {
        let dir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Friday", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return try AppDatabase(DatabasePool(path: dir.appendingPathComponent("friday.sqlite").path))
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
        return migrator
    }
}

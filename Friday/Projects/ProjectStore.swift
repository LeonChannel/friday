import Foundation
import GRDB
import Observation

enum ProjectStoreError: LocalizedError, Equatable {
    case notADirectory(String)
    case alreadyAdded(String)

    var errorDescription: String? {
        switch self {
        case .notADirectory(let path): "\(path) não é uma pasta."
        case .alreadyAdded(let path): "\(path) já está na lista."
        }
    }
}

@MainActor
@Observable
final class ProjectStore {
    private(set) var all: [Project] = []
    private let db: DatabaseQueue

    init(db: DatabaseQueue) throws {
        self.db = db
        try Self.migrator.migrate(db)
        try reload()
    }

    static func live() -> ProjectStore {
        do {
            let dir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("Friday", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return try ProjectStore(db: DatabaseQueue(path: dir.appendingPathComponent("friday.sqlite").path))
        } catch {
            fatalError("Não consegui abrir o banco do Friday: \(error)")
        }
    }

    @discardableResult
    func add(path rawPath: String) throws -> Project {
        let path = URL(fileURLWithPath: rawPath).standardizedFileURL.path
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
            throw ProjectStoreError.notADirectory(path)
        }
        guard !all.contains(where: { $0.path == path }) else { throw ProjectStoreError.alreadyAdded(path) }
        var project = Project(id: nil, name: (path as NSString).lastPathComponent, path: path, addedAt: Date())
        try db.write { try project.insert($0) }
        try reload()
        return project
    }

    func remove(_ id: Project.ID) throws {
        guard let id else { return }
        _ = try db.write { try Project.deleteOne($0, key: id) }
        try reload()
    }

    private func reload() throws {
        all = try db.read { try Project.order(Column("name").collating(.localizedCaseInsensitiveCompare)).fetchAll($0) }
    }

    private static var migrator: DatabaseMigrator {
        var m = DatabaseMigrator()
        m.registerMigration("v1-projects") { db in
            try db.create(table: "project") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("path", .text).notNull().unique()
                t.column("addedAt", .datetime).notNull()
            }
        }
        return m
    }
}

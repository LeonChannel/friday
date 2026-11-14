import Foundation
import GRDB

struct Project: Identifiable, Hashable, Codable, Sendable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var name: String
    var path: String
    var addedAt: Date

    static let databaseTableName = "project"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    var isGitRepository: Bool {
        FileManager.default.fileExists(atPath: (path as NSString).appendingPathComponent(".git"))
    }
}

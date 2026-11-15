// Resumo: Guarda os itens do backlog no banco, numera cada um dentro do projeto, confere a hierarquia na transação e avisa a tela de mudanças, mesmo as da CLI.
// Tags: backlog, persistencia

import FridayDomain
import Foundation
import GRDB

/// Itens do backlog no SQLite, uma linha por item.
public struct GRDBBacklogRepository: BacklogRepository {
    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func observeAll(projectID: Int64) -> AsyncThrowingStream<[BacklogItem], any Error> {
        DatabaseLiveStream.values(in: database.writer) { db in try Self.fetchAll(db, projectID: projectID) }
    }

    public func all(projectID: Int64) throws -> [BacklogItem] {
        try database.writer.read { db in try Self.fetchAll(db, projectID: projectID) }
    }

    private static func fetchAll(_ db: Database, projectID: Int64) throws -> [BacklogItem] {
        try BacklogItemRecord.filter(Column("projectID") == projectID).order(Column("number")).fetchAll(db).map { try $0.item() }
    }

    public func item(projectID: Int64, number: Int) throws -> BacklogItem? {
        try database.writer.read { db in
            try BacklogItemRecord.filter(Column("projectID") == projectID && Column("number") == number).fetchOne(db)?.item()
        }
    }

    public func item(id: Int64) throws -> BacklogItem? {
        try database.writer.read { db in try BacklogItemRecord.fetchOne(db, key: id)?.item() }
    }

    @discardableResult
    public func insert(_ item: BacklogItem) throws -> BacklogItem {
        try database.writer.write { db in
            var item = item
            try Self.checkParent(of: item, db)
            // Número calculado dentro da transação de escrita: app e CLI nunca ganham o mesmo.
            let last = try Int.fetchOne(db, sql: "SELECT MAX(number) FROM backlogItem WHERE projectID = ?", arguments: [item.projectID]) ?? 0
            item.number = last + 1
            var record = BacklogItemRecord(item)
            try record.insert(db)
            item.id = record.id
            return item
        }
    }

    @discardableResult
    public func update(id: Int64, _ change: @Sendable (inout BacklogItem) throws -> Void) throws -> BacklogItem {
        try database.writer.write { db in
            guard let current = try BacklogItemRecord.fetchOne(db, key: id)?.item() else { throw BacklogError.itemNotFound("#\(id)") }
            var item = current
            try change(&item)
            // Projeto, número e id não mudam por aqui: o código citado fora do Friday continua valendo.
            item.id = current.id
            item.projectID = current.projectID
            item.number = current.number
            if item.parentID != current.parentID || item.kind != current.kind { try Self.checkParent(of: item, db) }
            try BacklogItemRecord(item).update(db)
            return item
        }
    }

    public func delete(id: Int64) throws {
        try database.writer.write { db in
            guard let item = try BacklogItemRecord.fetchOne(db, key: id)?.item() else { return }
            let children = try BacklogItemRecord.filter(Column("parentID") == id).fetchCount(db)
            if children > 0 { throw BacklogError.hasChildren("#\(item.number)", count: children) }
            _ = try BacklogItemRecord.deleteOne(db, key: id)
        }
    }

    /// Confere o pai contra a hierarquia e, para não criar volta, que o pai não está dentro do próprio item.
    private static func checkParent(of item: BacklogItem, _ db: Database) throws {
        let parent = try item.parentID.flatMap { try BacklogItemRecord.fetchOne(db, key: $0)?.item() }
        if item.parentID != nil, parent == nil { throw BacklogError.itemNotFound("#\(item.parentID ?? 0)") }
        try BacklogItem.checkParent(parent, forChild: item)
        var ancestor = parent
        while let current = ancestor, let parentID = current.parentID {
            if parentID == item.id { throw BacklogError.invalidParent(child: item.kind, parent: parent?.kind ?? item.kind) }
            ancestor = try BacklogItemRecord.fetchOne(db, key: parentID)?.item()
        }
    }
}

/// Formato da linha no banco; existe para o tipo do Domain não depender do GRDB.
private struct BacklogItemRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "backlogItem"

    var id: Int64?
    var projectID: Int64?
    var number: Int
    var kind: String
    var title: String
    var detail: String
    var location: String?
    var grade: String?
    var priority: String
    var status: String
    var author: String
    var parentID: Int64?
    var externalRef: String?
    var createdAt: Date
    var updatedAt: Date

    init(_ item: BacklogItem) {
        id = item.id
        projectID = item.projectID
        number = item.number
        kind = item.kind.rawValue
        title = item.title
        detail = item.detail
        location = item.location
        grade = item.grade?.rawValue
        priority = item.priority.rawValue
        status = item.status.rawValue
        author = item.author.rawValue
        parentID = item.parentID
        externalRef = item.externalRef
        createdAt = item.createdAt
        updatedAt = item.updatedAt
    }

    /// Valor desconhecido (versão mais nova gravou) cai no padrão em vez de esconder o item.
    func item() throws -> BacklogItem {
        BacklogItem(
            id: id, projectID: projectID ?? 0, number: number, kind: BacklogKind(rawValue: kind) ?? .task, title: title, detail: detail,
            location: location, grade: grade.flatMap(EvidenceGrade.init(rawValue:)), priority: BacklogPriority(rawValue: priority) ?? .medium,
            status: BacklogStatus(rawValue: status) ?? .new, author: BacklogAuthor(rawValue: author) ?? .you, parentID: parentID,
            externalRef: externalRef, createdAt: createdAt, updatedAt: updatedAt
        )
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

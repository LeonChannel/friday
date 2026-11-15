// Resumo: Guarda os assuntos no banco (partes em JSON, vez e atualização em colunas) e avisa a tela de mudanças, mesmo as feitas pela CLI.
// Tags: assuntos, persistencia

import FridayDomain
import Foundation
import GRDB

/// Assuntos guardados no SQLite. As partes vão num JSON; vez e atualização ficam em colunas para consulta.
public struct GRDBSubjectRepository: SubjectRepository {
    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func observeAll() -> AsyncThrowingStream<[Subject], any Error> {
        stream(fetch: Self.fetchAll)
    }

    public func all() throws -> [Subject] {
        try database.writer.read(Self.fetchAll)
    }

    private static func fetchAll(_ db: Database) throws -> [Subject] {
        try SubjectRecord.order(Column("updatedAt").desc, Column("id").desc).fetchAll(db).map { try $0.subject() }
    }

    public func observe(id: Int64) -> AsyncThrowingStream<Subject?, any Error> {
        stream(fetch: { db in try SubjectRecord.fetchOne(db, key: id)?.subject() })
    }

    public func subject(id: Int64) throws -> Subject? {
        try database.writer.read { db in try SubjectRecord.fetchOne(db, key: id)?.subject() }
    }

    @discardableResult
    public func insert(_ subject: Subject) throws -> Subject {
        try database.writer.write { db in
            var record = try SubjectRecord(subject)
            try record.insert(db)
            return try record.subject()
        }
    }

    @discardableResult
    public func update(id: Int64, _ change: @Sendable (inout Subject) throws -> Void) throws -> Subject {
        try database.writer.write { db in
            guard let current = try SubjectRecord.fetchOne(db, key: id) else { throw SubjectError.subjectNotFound(id) }
            var subject = try current.subject()
            try change(&subject)
            let record = try SubjectRecord(subject)
            try record.update(db)
            return subject
        }
    }

    public func delete(id: Int64) throws {
        _ = try database.writer.write { db in try SubjectRecord.deleteOne(db, key: id) }
    }

    private func stream<Value: Sendable & Equatable>(fetch: @escaping @Sendable (Database) throws -> Value) -> AsyncThrowingStream<Value, any Error> {
        DatabaseLiveStream.values(in: database.writer, fetch: fetch)
    }
}

/// Formato da linha no banco; existe para o tipo do Domain não depender do GRDB.
private struct SubjectRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "subject"

    var id: Int64?
    var title: String
    var projectID: Int64?
    var createdAt: Date
    var updatedAt: Date
    var intent: String
    var partsJSON: String
    var turn: String
    var turnReason: String
    var activity: String?

    private struct Parts: Codable {
        var questions: [Question]
        var evidences: [Evidence]
        var alternatives: [Alternative]
        var decisions: [Decision]
        var fronts: [Front]
        var stages: [Stage]

        init(questions: [Question], evidences: [Evidence], alternatives: [Alternative], decisions: [Decision], fronts: [Front], stages: [Stage]) {
            self.questions = questions
            self.evidences = evidences
            self.alternatives = alternatives
            self.decisions = decisions
            self.fronts = fronts
            self.stages = stages
        }

        // Assunto gravado antes das jornadas não tem `stages` no JSON.
        init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            questions = try c.decode([Question].self, forKey: .questions)
            evidences = try c.decode([Evidence].self, forKey: .evidences)
            alternatives = try c.decode([Alternative].self, forKey: .alternatives)
            decisions = try c.decode([Decision].self, forKey: .decisions)
            fronts = try c.decode([Front].self, forKey: .fronts)
            stages = try c.decodeIfPresent([Stage].self, forKey: .stages) ?? []
        }
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }

    init(_ subject: Subject) throws {
        id = subject.id
        title = subject.title
        projectID = subject.projectID
        createdAt = subject.createdAt
        updatedAt = subject.updatedAt
        intent = subject.intent
        let parts = Parts(
            questions: subject.questions, evidences: subject.evidences, alternatives: subject.alternatives,
            decisions: subject.decisions, fronts: subject.fronts, stages: subject.stages
        )
        activity = subject.activity?.rawValue
        partsJSON = String(decoding: try Self.encoder.encode(parts), as: UTF8.self)
        let turn = subject.turn
        self.turn = turn.holder.rawValue
        turnReason = turn.reason
    }

    func subject() throws -> Subject {
        let parts = try Self.decoder.decode(Parts.self, from: Data(partsJSON.utf8))
        return Subject(
            id: id, title: title, projectID: projectID, intent: intent, createdAt: createdAt, updatedAt: updatedAt,
            questions: parts.questions, evidences: parts.evidences, alternatives: parts.alternatives,
            decisions: parts.decisions, fronts: parts.fronts,
            activity: activity.flatMap(ActivityKind.init(rawValue:)), stages: parts.stages
        )
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

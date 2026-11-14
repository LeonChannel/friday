// Resumo: Prova que o banco guarda os assuntos com todas as partes, altera em transação, consulta a vez e enxerga escrita de outro processo.
// Tags: assuntos, persistencia, testes

import FridayDomain
import Foundation
import GRDB
import Testing
@testable import FridayInfrastructure

struct GRDBSubjectRepositoryTests {
    private let now = Date(timeIntervalSince1970: 1_000)

    private func fullSubject() throws -> Subject {
        var subject = try Subject(title: "Cache", intent: "Cortar latência", createdAt: now)
        try subject.addEvidence(fact: "p95 840 ms", source: "trace", grade: .measured, at: now)
        try subject.addQuestion(text: "Tempo ou evento?", options: [QuestionOption(label: "Tempo", consequence: "simples")], waitsForYou: true, at: now)
        try subject.addAlternative(name: "TTL", gain: "g", risk: "r", effort: "e", reversibility: "v", at: now)
        try subject.recordDecision(text: "Evento", reason: "porque", changeIf: "custo", at: now)
        try subject.upsertFront(name: "Medir", criterion: "p95", steps: ["a", "b"], doneSteps: 1, at: now)
        return subject
    }

    @Test func insertThenReadReturnsEveryPart() throws {
        let repository = GRDBSubjectRepository(database: try .inMemory())
        let saved = try repository.insert(try fullSubject())
        let id = try #require(saved.id)
        #expect(try repository.subject(id: id) == saved)
        #expect(saved.questions.count == 1 && saved.fronts[0].steps.count == 2)
    }

    @Test func updateAppliesChangeAndRejectedChangeWritesNothing() throws {
        let repository = GRDBSubjectRepository(database: try .inMemory())
        let id = try #require(try repository.insert(try Subject(title: "A", createdAt: now)).id)
        let later = now.addingTimeInterval(60)
        try repository.update(id: id) { try $0.addEvidence(fact: "f", source: "s", grade: .inCode, at: later) }
        let tooLong = String(repeating: "x", count: 500)
        #expect(throws: SubjectError.self) {
            try repository.update(id: id) { subject in
                try subject.addEvidence(fact: "ok", source: "s", grade: .inCode, at: later)
                try subject.addEvidence(fact: tooLong, source: "s", grade: .inCode, at: later)
            }
        }
        let stored = try #require(try repository.subject(id: id))
        #expect(stored.evidences.map(\.fact) == ["f"])
        #expect(stored.updatedAt == later)
    }

    @Test func updateOfMissingSubjectFails() throws {
        let repository = GRDBSubjectRepository(database: try .inMemory())
        #expect(throws: SubjectError.subjectNotFound(42)) { try repository.update(id: 42) { _ in } }
    }

    @Test func turnAndUpdatedAtAreQueryableColumns() throws {
        let database = try AppDatabase.inMemory()
        let repository = GRDBSubjectRepository(database: database)
        try repository.insert(try fullSubject())
        try repository.insert(try Subject(title: "Parado", createdAt: now))
        let rows = try database.writer.read { db in
            try Row.fetchAll(db, sql: "SELECT turn, turnReason FROM subject WHERE turn = 'you'")
        }
        #expect(rows.count == 1)
        #expect(rows[0]["turnReason"] as String == "1 decisão esperando")
    }

    @Test func observationEmitsNewestFirstAfterChanges() async throws {
        let repository = GRDBSubjectRepository(database: try .inMemory())
        var iterator = repository.observeAll().makeAsyncIterator()
        #expect(try await iterator.next() == [])
        try repository.insert(try Subject(title: "Velho", createdAt: now))
        #expect(try await Self.next(&iterator, until: ["Velho"]))
        try repository.insert(try Subject(title: "Novo", createdAt: now.addingTimeInterval(10)))
        #expect(try await Self.next(&iterator, until: ["Novo", "Velho"]))
    }

    /// Lê emissões até chegar à lista esperada. Outros testes em paralelo disparam o aviso global entre processos,
    /// então a observação pode reemitir; o que importa é chegar ao estado certo, na ordem certa.
    private static func next(_ iterator: inout AsyncThrowingStream<[Subject], any Error>.AsyncIterator, until titles: [String]) async throws -> Bool {
        for _ in 0..<10 {
            guard let value = try await iterator.next() else { return false }
            if value.map(\.title) == titles { return true }
        }
        return false
    }

    @Test(.tags(.integration)) func observationSeesWriteFromAnotherConnectionAfterSignal() async throws {
        let dir = try TemporaryDirectory()
        defer { dir.remove() }
        let path = dir.url.appendingPathComponent("friday.sqlite").path
        let app = GRDBSubjectRepository(database: try .open(path: path))
        let cli = GRDBSubjectRepository(database: try .open(path: path))

        var iterator = app.observeAll().makeAsyncIterator()
        #expect(try await iterator.next() == [])
        // Segunda conexão faz o papel do processo da CLI: o GRDB do app não vê a escrita sozinho.
        try cli.insert(try Subject(title: "Veio da CLI", createdAt: now))
        SubjectChangeSignal.post()
        #expect(try await iterator.next()?.map(\.title) == ["Veio da CLI"])
    }
}

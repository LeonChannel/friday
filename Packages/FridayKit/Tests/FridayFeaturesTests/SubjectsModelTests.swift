// Resumo: Prova que a lista de assuntos e o assunto aberto na tela acompanham o banco e calculam vez e "Onde você parou".
// Tags: assuntos, interface, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing
@testable import FridayFeatures

@MainActor
struct SubjectsModelTests {
    private let now = Date(timeIntervalSince1970: 1_000)

    @Test func listGroupsRowsByTurn() async throws {
        let repository = GRDBSubjectRepository(database: try .inMemory())
        var waiting = try Subject(title: "Espera você", createdAt: now)
        try waiting.addQuestion(text: "q", waitsForYou: true, at: now)
        try repository.insert(waiting)
        try repository.insert(try Subject(title: "Parado", createdAt: now))

        let model = SubjectsModel(repository: repository)
        let task = Task { await model.observe() }
        defer { task.cancel() }
        while model.rows.count < 2 { await Task.yield() }

        #expect(model.rows(for: .you).map(\.subject.title) == ["Espera você"])
        #expect(model.rows(for: .idle).map(\.subject.title) == ["Parado"])
        #expect(model.rows(for: .claude).isEmpty)
    }

    @Test func subjectModelFollowsChangesAndProjectsResume() async throws {
        let repository = GRDBSubjectRepository(database: try .inMemory())
        let id = try #require(try repository.insert(try Subject(title: "A", intent: "Meta", createdAt: now)).id)
        let model = SubjectModel(id: id, repository: repository)
        let task = Task { await model.observe() }
        defer { task.cancel() }
        while model.subject == nil { await Task.yield() }
        #expect(model.resume?.goal == "Meta")

        try repository.update(id: id) { try $0.addEvidence(fact: "f", source: "s", grade: .measured, at: now) }
        while model.resume?.confirmed.isEmpty != false { await Task.yield() }
        #expect(model.resume?.sourceLine == "fonte: 1 evidências · 0 decisões")
    }
}

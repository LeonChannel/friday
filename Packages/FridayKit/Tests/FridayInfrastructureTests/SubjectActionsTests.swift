// Resumo: Prova as ações que a tela faz no assunto: responder pergunta vira decisão e passa a vez, e ligar a um projeto grava o projeto.
// Tags: assuntos, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing

struct SubjectActionsTests {
    @Test func answeringTheOnlyWaitingQuestionTakesTheTurnAwayFromYou() throws {
        let database = try AppDatabase.inMemory()
        let repository = GRDBSubjectRepository(database: database)
        var subject = try Subject(title: "Custo", createdAt: .distantPast)
        let question = try subject.addQuestion(text: "Liberar métricas?", options: [QuestionOption(label: "Liberar", consequence: "medição exata")], waitsForYou: true, at: .distantPast)
        let saved = try repository.insert(subject)
        let id = try #require(saved.id)
        #expect(saved.turn.holder == .you)

        let updated = try repository.update(id: id) { subject in
            _ = try subject.recordDecision(text: "Liberar", reason: "medição exata", answering: question.id, at: .now)
        }

        #expect(updated.turn.holder != .you)
        #expect(updated.decisions.map(\.text) == ["Liberar"])
        #expect(updated.questions.first?.isOpen == false)
    }

    @Test func linkingToAProjectIsSaved() throws {
        let database = try AppDatabase.inMemory()
        let project = try GRDBProjectRepository(database: database).insert(Project(name: "p", path: "/tmp/p", kind: .folder, addedAt: .distantPast))
        let repository = GRDBSubjectRepository(database: database)
        let id = try #require(try repository.insert(try Subject(title: "x", createdAt: .distantPast)).id)

        _ = try repository.update(id: id) { $0.projectID = project.id }

        #expect(try repository.subject(id: id)?.projectID == project.id)
    }
}

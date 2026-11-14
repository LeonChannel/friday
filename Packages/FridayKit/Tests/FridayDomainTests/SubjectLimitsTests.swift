// Resumo: Prova que cada texto do assunto é recusado acima do teto, com o tamanho na mensagem, e que o limite exato passa.
// Tags: assuntos, testes

import Foundation
import Testing
@testable import FridayDomain

struct SubjectLimitsTests {
    let now = Date(timeIntervalSince1970: 1_000)

    private func subject() throws -> Subject { try Subject(id: 1, title: "Cache", createdAt: now) }
    private func text(_ count: Int) -> String { String(repeating: "a", count: count) }

    @Test func titleAtLimitPassesAndAboveFailsWithSize() throws {
        _ = try Subject(title: text(SubjectLimits.title), createdAt: now)
        #expect(throws: SubjectError.tooLong(field: "Título", limit: 80, actual: 81)) {
            try Subject(title: text(81), createdAt: now)
        }
    }

    @Test func messageNamesFieldSizeAndLimit() {
        let message = SubjectError.tooLong(field: "Evidência", limit: 200, actual: 250).errorDescription
        #expect(message == "Evidência: 250 caracteres, o teto é 200. Encurte e tente de novo.")
    }

    @Test func rejectsEmptyTitle() {
        #expect(throws: SubjectError.empty(field: "Título")) { try Subject(title: "   ", createdAt: now) }
    }

    @Test func intentLimit() throws {
        #expect(throws: SubjectError.tooLong(field: "Intenção", limit: 300, actual: 301)) {
            try Subject(title: "x", intent: text(301), createdAt: now)
        }
        var subject = try subject()
        #expect(throws: SubjectError.tooLong(field: "Intenção", limit: 300, actual: 301)) { try subject.setIntent(text(301), at: now) }
    }

    @Test func evidenceQuestionDecisionLimits() throws {
        var subject = try subject()
        #expect(throws: SubjectError.tooLong(field: "Evidência", limit: 200, actual: 201)) {
            try subject.addEvidence(fact: text(201), source: "s", grade: .measured, at: now)
        }
        #expect(throws: SubjectError.tooLong(field: "Pergunta", limit: 240, actual: 241)) {
            try subject.addQuestion(text: text(241), at: now)
        }
        #expect(throws: SubjectError.tooLong(field: "Opção", limit: 60, actual: 61)) {
            try subject.addQuestion(text: "q", options: [QuestionOption(label: text(61), consequence: "c")], at: now)
        }
        #expect(throws: SubjectError.tooLong(field: "Consequência", limit: 140, actual: 141)) {
            try subject.addQuestion(text: "q", options: [QuestionOption(label: "A", consequence: text(141))], at: now)
        }
        #expect(throws: SubjectError.tooLong(field: "Decisão", limit: 200, actual: 201)) {
            try subject.recordDecision(text: text(201), reason: "r", at: now)
        }
        #expect(throws: SubjectError.tooLong(field: "Porquê", limit: 160, actual: 161)) {
            try subject.recordDecision(text: "d", reason: text(161), at: now)
        }
    }

    @Test func rejectedWriteLeavesSubjectUntouched() throws {
        var subject = try subject()
        _ = try? subject.addEvidence(fact: text(201), source: "s", grade: .measured, at: now.addingTimeInterval(5))
        #expect(subject.evidences.isEmpty)
        #expect(subject.updatedAt == now)
    }

    @Test func decisionAnswersQuestionAndRejectsUnknownOne() throws {
        var subject = try subject()
        let question = try subject.addQuestion(text: "q", waitsForYou: true, at: now)
        #expect(throws: SubjectError.unknownQuestion(9)) { try subject.recordDecision(text: "d", reason: "r", answering: 9, at: now) }
        try subject.recordDecision(text: "d", reason: "r", answering: question.id, at: now)
        #expect(subject.questions[0].isOpen == false)
    }

    @Test func newFrontNeedsCriterionButUpdateDoesNot() throws {
        var subject = try subject()
        #expect(throws: SubjectError.frontNeedsCriterion("Medir")) { try subject.upsertFront(name: "Medir", at: now) }
        try subject.upsertFront(name: "Medir", criterion: "p95", steps: ["a", "b"], at: now)
        try subject.upsertFront(name: "medir", state: .done, doneSteps: 2, at: now)
        #expect(subject.fronts.count == 1)
        #expect(subject.fronts[0].state == .done)
        #expect(subject.fronts[0].steps.allSatisfy { $0.isDone })
    }
}

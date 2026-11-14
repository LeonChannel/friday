// Resumo: Prova a vez (você, Claude, parado) e o "Onde você parou" com assuntos de exemplo fixos, incluindo linhas que ficam vazias.
// Tags: assuntos, testes

import Foundation
import Testing
@testable import FridayDomain

struct SubjectProjectionTests {
    private func date(_ n: Int) -> Date { Date(timeIntervalSince1970: TimeInterval(1_000 + n)) }
    private func empty() throws -> Subject { try Subject(id: 1, title: "Cache", createdAt: date(0)) }

    @Test func emptySubjectIsIdle() throws {
        #expect(try empty().turn == SubjectTurn(holder: .idle, reason: "nada em andamento"))
    }

    @Test func openQuestionWaitingForYouMakesItYourTurn() throws {
        var subject = try empty()
        try subject.addQuestion(text: "q", waitsForYou: true, at: date(1))
        #expect(subject.turn == SubjectTurn(holder: .you, reason: "1 decisão esperando"))
    }

    @Test func answeredQuestionNoLongerWaits() throws {
        var subject = try empty()
        try subject.addQuestion(text: "q", waitsForYou: true, at: date(1))
        try subject.recordDecision(text: "d", reason: "r", answering: 1, at: date(2))
        #expect(subject.turn.holder == .idle)
    }

    @Test func questionNotWaitingForYouDoesNotTakeTheTurn() throws {
        var subject = try empty()
        try subject.addQuestion(text: "q", at: date(1))
        #expect(subject.turn.holder == .idle)
    }

    @Test func frontWaitingForYouBeatsRunningFront() throws {
        var subject = try empty()
        try subject.upsertFront(name: "A", criterion: "c", state: .running, at: date(1))
        try subject.upsertFront(name: "B", criterion: "c", state: .waitingForYou, at: date(1))
        try subject.addQuestion(text: "q1", waitsForYou: true, at: date(1))
        try subject.addQuestion(text: "q2", waitsForYou: true, at: date(1))
        #expect(subject.turn == SubjectTurn(holder: .you, reason: "2 decisões esperando · 1 frente esperando você"))
    }

    @Test func runningFrontIsClaudesTurn() throws {
        var subject = try empty()
        try subject.upsertFront(name: "A", criterion: "c", at: date(1))
        try subject.upsertFront(name: "B", criterion: "c", at: date(1))
        try subject.upsertFront(name: "C", criterion: "c", state: .done, at: date(1))
        #expect(subject.turn == SubjectTurn(holder: .claude, reason: "2 frentes rodando"))
    }

    @Test func resumeOfEmptySubjectHasOnlyTheSourceLine() throws {
        let resume = SubjectResume(try empty())
        #expect(resume.goal == nil)
        #expect(resume.confirmed.isEmpty && resume.open.isEmpty && resume.yourTurn.isEmpty && resume.next.isEmpty)
        #expect(resume.sourceLine == "fonte: 0 evidências · 0 decisões")
    }

    @Test func resumeFillsFiveLinesFromState() throws {
        var subject = try Subject(id: 1, title: "Cache", intent: "Cortar a latência pela metade.", createdAt: date(0))
        try subject.addEvidence(fact: "velho", source: "s", grade: .measured, at: date(1))
        try subject.addEvidence(fact: "meio", source: "s", grade: .inCode, at: date(2))
        try subject.addEvidence(fact: "novo", source: "s", grade: .measured, at: date(3))
        try subject.addEvidence(fact: "talvez", source: "s", grade: .inferred, at: date(4))
        try subject.addQuestion(text: "aberta", at: date(5))
        try subject.addQuestion(text: "decida", options: [QuestionOption(label: "A", consequence: "rápido")], waitsForYou: true, at: date(6))
        try subject.recordDecision(text: "d", reason: "r", at: date(7))
        try subject.upsertFront(name: "Medir", criterion: "c", steps: ["coletar", "comparar"], doneSteps: 1, at: date(8))
        try subject.upsertFront(name: "Fim", criterion: "c", state: .done, steps: ["x"], at: date(8))

        let resume = SubjectResume(subject)
        #expect(resume.goal == "Cortar a latência pela metade.")
        #expect(resume.confirmed == [
            .init(text: "novo", grade: .measured), .init(text: "meio", grade: .inCode), .init(text: "velho", grade: .measured),
        ])
        #expect(resume.open == [.init(text: "aberta", grade: nil), .init(text: "talvez", grade: .inferred)])
        #expect(resume.yourTurn == [.init(text: "decida", options: [QuestionOption(label: "A", consequence: "rápido")])])
        #expect(resume.next == [.init(front: "Medir", step: "comparar")])
        #expect(resume.sourceLine == "fonte: 4 evidências · 1 decisões")
    }

    @Test func resumeCapsEachLine() throws {
        var subject = try empty()
        for n in 1...6 { try subject.addEvidence(fact: "f\(n)", source: "s", grade: .measured, at: date(n)) }
        #expect(SubjectResume(subject).confirmed.map(\.text) == ["f6", "f5", "f4"])
    }
}

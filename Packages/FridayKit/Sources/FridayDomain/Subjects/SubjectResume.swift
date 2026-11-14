// Resumo: Monta o "Onde você parou" (objetivo, confirmado, em aberto, sua vez, depois) só do estado gravado, sem inventar linha.
// Tags: assuntos

import Foundation

/// As cinco linhas de retorno de um assunto. Linha sem dado fica vazia, nunca preenchida.
public struct SubjectResume: Equatable, Sendable {
    /// Fato confirmado, com o grau.
    public struct ConfirmedFact: Equatable, Sendable {
        public var text: String
        public var grade: EvidenceGrade
    }

    /// Item em aberto: pergunta (`grade == nil`) ou evidência inferida.
    public struct OpenItem: Equatable, Sendable {
        public var text: String
        public var grade: EvidenceGrade?
    }

    /// O que espera o dev, com as consequências de cada opção.
    public struct YourTurnItem: Equatable, Sendable {
        public var text: String
        public var options: [QuestionOption]
    }

    /// Próximo passo de uma frente.
    public struct NextStep: Equatable, Sendable {
        public var front: String
        public var step: String
    }

    public var goal: String?
    public var confirmed: [ConfirmedFact]
    public var open: [OpenItem]
    public var yourTurn: [YourTurnItem]
    public var next: [NextStep]
    public var sourceLine: String

    /// Quantos itens de cada linha o resumo mostra (o resto fica no dossiê).
    public static let itemLimit = 3

    /// Projeta o resumo do assunto.
    public init(_ subject: Subject) {
        let limit = Self.itemLimit
        goal = subject.intent.isEmpty ? nil : subject.intent
        confirmed = subject.evidences
            .filter { $0.grade != .inferred }
            .sorted { ($0.recordedAt, $0.id) > ($1.recordedAt, $1.id) }
            .prefix(limit).map { ConfirmedFact(text: $0.fact, grade: $0.grade) }
        let openQuestions = subject.questions.filter { $0.isOpen && !$0.waitsForYou }.map { OpenItem(text: $0.text, grade: nil) }
        let inferred = subject.evidences
            .filter { $0.grade == .inferred }
            .sorted { ($0.recordedAt, $0.id) > ($1.recordedAt, $1.id) }
            .map { OpenItem(text: $0.fact, grade: .inferred) }
        open = Array((openQuestions + inferred).prefix(limit))
        yourTurn = subject.questions.filter { $0.isOpen && $0.waitsForYou }.map { YourTurnItem(text: $0.text, options: $0.options) }
            + subject.fronts.filter { $0.state == .waitingForYou }.map { YourTurnItem(text: "Frente \($0.name) esperando você", options: []) }
        next = subject.fronts
            .filter { $0.state != .done }
            .compactMap { front in front.nextStep.map { NextStep(front: front.name, step: $0) } }
            .prefix(limit).map { $0 }
        sourceLine = "fonte: \(subject.evidences.count) evidências · \(subject.decisions.count) decisões"
    }
}

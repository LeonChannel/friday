// Resumo: As partes de um assunto (evidência, pergunta, alternativa, decisão e frente) e o grau de cada evidência.
// Tags: assuntos

import Foundation

/// De onde veio um fato: o grau decide quanto ele pesa.
public enum EvidenceGrade: String, Codable, Sendable, CaseIterable {
    /// Número ou resultado observado de verdade.
    case measured
    /// Lido no código, sem executar.
    case inCode
    /// Dedução, ainda sem prova.
    case inferred

    /// Texto curto mostrado ao usuário.
    public var label: String {
        switch self {
        case .measured: "medido"
        case .inCode: "no código"
        case .inferred: "inferido"
        }
    }
}

/// Um fato com a fonte e o grau.
public struct Evidence: Codable, Equatable, Sendable, Identifiable {
    public var id: Int
    public var fact: String
    public var source: String
    public var grade: EvidenceGrade
    public var recordedAt: Date
}

/// Uma resposta possível a uma pergunta, com o que ela causa.
public struct QuestionOption: Codable, Equatable, Sendable {
    public var label: String
    public var consequence: String

    public init(label: String, consequence: String) {
        self.label = label
        self.consequence = consequence
    }
}

/// Algo a responder. Se `waitsForYou`, a vez é do dev enquanto estiver em aberto.
public struct Question: Codable, Equatable, Sendable, Identifiable {
    public var id: Int
    public var text: String
    public var options: [QuestionOption]
    public var waitsForYou: Bool
    public var askedAt: Date
    /// Quando foi respondida (por uma decisão); `nil` enquanto aberta.
    public var answeredAt: Date?

    public var isOpen: Bool { answeredAt == nil }
}

/// Uma opção comparada às outras por ganho, risco, esforço e reversibilidade.
public struct Alternative: Codable, Equatable, Sendable, Identifiable {
    public var id: Int
    public var name: String
    public var gain: String
    public var risk: String
    public var effort: String
    public var reversibility: String
}

/// O que foi decidido, por quê e o que faria mudar de ideia.
public struct Decision: Codable, Equatable, Sendable, Identifiable {
    public var id: Int
    public var text: String
    public var reason: String
    public var changeIf: String?
    public var decidedAt: Date
}

/// Em que ponto está uma frente de trabalho.
public enum FrontState: String, Codable, Sendable, CaseIterable {
    case running
    case waitingForYou
    case done
}

/// Um passo de uma frente.
public struct FrontStep: Codable, Equatable, Sendable {
    public var text: String
    public var isDone: Bool

    public init(text: String, isDone: Bool) {
        self.text = text
        self.isDone = isDone
    }
}

/// Trabalho em andamento (pesquisa ou execução) com passos e critério de conclusão.
public struct Front: Codable, Equatable, Sendable {
    public var name: String
    public var criterion: String
    public var state: FrontState
    public var steps: [FrontStep]
    public var updatedAt: Date

    /// Primeiro passo ainda não feito, se houver.
    public var nextStep: String? { steps.first { !$0.isDone }?.text }
}

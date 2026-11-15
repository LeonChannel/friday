// Resumo: A jornada de um tipo de atividade: o prompt, as skills e as etapas que o dev configura, vazia até ele preencher.
// Tags: jornadas

import Foundation

/// Como o Claude conduz um tipo de atividade. Nasce vazia: o Friday não decide o método, o dev decide nos Ajustes.
public struct Journey: Codable, Equatable, Sendable {
    public var kind: ActivityKind
    /// Instrução de como lidar com a solicitação, em texto livre.
    public var prompt: String
    /// Nomes das skills que a sessão deve usar (`skill` ou `plugin:skill`).
    public var skills: [String]
    /// Etapas, em ordem, que viram o trilho de progresso da lousa.
    public var stages: [String]

    public init(kind: ActivityKind, prompt: String = "", skills: [String] = [], stages: [String] = []) {
        self.kind = kind
        self.prompt = prompt
        self.skills = skills
        self.stages = stages
    }

    /// Teto do prompt da jornada, em caracteres.
    public static let promptLimit = 4000
    /// Máximo de etapas por jornada (a lousa precisa caber numa linha).
    public static let stageLimit = 8

    /// Verdadeiro quando o dev ainda não escreveu nada nesta jornada.
    public var isEmpty: Bool {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && cleanSkills.isEmpty && cleanStages.isEmpty
    }

    /// Skills sem vazio nem repetida, na ordem em que foram escolhidas.
    public var cleanSkills: [String] { Self.clean(skills) }

    /// Etapas sem vazio, aparadas e cortadas nos tetos.
    public var cleanStages: [String] {
        Self.clean(stages).prefix(Self.stageLimit).map { String($0.prefix(SubjectLimits.stageName)) }
    }

    private static func clean(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed).inserted else { return nil }
            return trimmed
        }
    }
}

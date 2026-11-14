// Resumo: Tetos de caracteres de cada texto do assunto e o erro que recusa texto grande demais, dizendo o tamanho.
// Tags: assuntos

import Foundation

/// Tetos de caracteres de cada campo do assunto. O assunto é uma lousa: texto curto ou não entra.
public enum SubjectLimits {
    public static let title = 80
    public static let intent = 300
    public static let question = 240
    public static let optionLabel = 60
    public static let optionConsequence = 140
    public static let evidence = 200
    public static let evidenceSource = 100
    public static let alternativeName = 60
    public static let alternativeDetail = 120
    public static let decision = 200
    public static let decisionReason = 160
    public static let decisionChangeIf = 160
    public static let frontName = 60
    public static let frontCriterion = 160
    public static let frontStep = 100

    /// Apara o texto e confere que não está vazio nem acima do teto.
    static func validated(_ text: String, field: String, limit: Int) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SubjectError.empty(field: field) }
        guard trimmed.count <= limit else { throw SubjectError.tooLong(field: field, limit: limit, actual: trimmed.count) }
        return trimmed
    }
}

/// Motivos para recusar uma escrita no assunto, com mensagem em português.
public enum SubjectError: LocalizedError, Equatable, Sendable {
    case empty(field: String)
    case tooLong(field: String, limit: Int, actual: Int)
    case unknownQuestion(Int)
    case frontNeedsCriterion(String)
    case subjectNotFound(Int64)

    public var errorDescription: String? {
        switch self {
        case .empty(let field): "\(field): o texto está vazio."
        case .tooLong(let field, let limit, let actual): "\(field): \(actual) caracteres, o teto é \(limit). Encurte e tente de novo."
        case .unknownQuestion(let id): "Não existe a pergunta \(id) neste assunto."
        case .frontNeedsCriterion(let name): "A frente \"\(name)\" é nova: informe o critério de conclusão."
        case .subjectNotFound(let id): "Não existe o assunto \(id)."
        }
    }
}

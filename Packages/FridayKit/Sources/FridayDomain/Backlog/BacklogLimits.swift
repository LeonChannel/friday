// Resumo: Tetos de caracteres do item do backlog e os erros que recusam uma escrita (texto grande, pai inválido, item inexistente).
// Tags: backlog

import Foundation

/// Tetos de caracteres de cada campo do item. O detalhe é maior que no assunto porque guarda como reproduzir.
public enum BacklogLimits {
    public static let title = 120
    public static let detail = 2_000
    public static let location = 200
    public static let externalRef = 200

    /// Apara o texto e confere que não está vazio nem acima do teto.
    static func validated(_ text: String, field: String, limit: Int) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw BacklogError.empty(field: field) }
        guard trimmed.count <= limit else { throw BacklogError.tooLong(field: field, limit: limit, actual: trimmed.count) }
        return trimmed
    }

    /// Como `validated`, mas texto vazio (ou nil) vira nil em vez de erro.
    static func optional(_ text: String?, field: String, limit: Int) throws -> String? {
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return try validated(text, field: field, limit: limit)
    }
}

/// Motivos para recusar uma escrita no backlog, com mensagem em português.
public enum BacklogError: LocalizedError, Equatable, Sendable {
    case empty(field: String)
    case tooLong(field: String, limit: Int, actual: Int)
    case invalidParent(child: BacklogKind, parent: BacklogKind)
    case needsParent(BacklogKind)
    case parentInOtherProject
    case itemNotFound(String)
    case hasChildren(String, count: Int)

    public var errorDescription: String? {
        switch self {
        case .empty(let field): "\(field): o texto está vazio."
        case .tooLong(let field, let limit, let actual): "\(field): \(actual) caracteres, o teto é \(limit). Encurte e tente de novo."
        case .invalidParent(let child, let parent):
            child.allowedParents.isEmpty
                ? "\(child.label) não fica dentro de outro item."
                : "\(child.label) não fica dentro de \(parent.label). Pode ficar dentro de: \(child.allowedParents.map(\.label).sorted().joined(separator: ", "))."
        case .needsParent(let kind): "\(kind.label) precisa estar dentro de outro item: informe o pai."
        case .parentInOtherProject: "O pai precisa ser do mesmo projeto."
        case .itemNotFound(let code): "Não existe o item \(code) neste projeto."
        case .hasChildren(let code, let count): "\(code) tem \(count) item(ns) dentro. Tire-os de dentro antes de apagar."
        }
    }
}

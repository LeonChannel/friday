// Resumo: Tetos da memória (resumo, título, estado da área, contexto de início) e os erros que recusam nota fora do formato.
// Tags: memoria

import Foundation

/// Tetos de tamanho da memória. O resumo é pago a cada sessão; o teto é o que mantém o custo baixo.
public enum MemoryLimits {
    /// Título de uma nota.
    public static let title = 80
    /// Resumo: o que entra no contexto.
    public static let summary = 300
    /// Estado da área de trabalho.
    public static let workAreaState = 1_200
    /// Contexto inteiro do início da sessão.
    public static let sessionStart = 12_000
    /// Uma nota inteira dentro do contexto de início.
    public static let inlineNote = 2_000
    /// Notas ancoradas entregues ao abrir um arquivo.
    public static let anchoredPerFile = 5
}

/// Por que uma nota foi recusada, com mensagem em português.
public enum MemoryNoteError: LocalizedError, Equatable, Sendable {
    case missingKind
    case unknownKind(String, layer: MemoryLayer)
    case missingSummary
    case tooLong(field: String, limit: Int, actual: Int)
    case emptyTitle
    case anchorsOutsideProject
    case invalidPath(String)

    public var errorDescription: String? {
        switch self {
        case .missingKind: "Falta o tipo da nota (tipo:)."
        case let .unknownKind(kind, layer):
            "Tipo \"\(kind)\" não existe na camada \(layer.displayName). Use: \(layer.kinds.map(\.rawValue).joined(separator: ", "))."
        case .missingSummary: "Falta o resumo da nota (resumo:): é ele que chega ao Claude."
        case let .tooLong(field, limit, actual): "\(field) tem \(actual) caracteres; o limite é \(limit). Encurte."
        case .emptyTitle: "A nota precisa de um título."
        case .anchorsOutsideProject: "Âncora só existe em nota de projeto."
        case let .invalidPath(path): "Caminho fora do vault: \(path)."
        }
    }

    /// Recusa texto acima do teto, dizendo o tamanho.
    static func checked(_ text: String, field: String, limit: Int) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= limit else { throw MemoryNoteError.tooLong(field: field, limit: limit, actual: trimmed.count) }
        return trimmed
    }
}

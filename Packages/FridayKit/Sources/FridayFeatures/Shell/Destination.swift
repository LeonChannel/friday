// Resumo: Para onde a janela está olhando (Mesa, Sua vez, um assunto ou um projeto) e como isso é lembrado entre aberturas do app.
// Tags: interface

/// Destino escolhido na lateral.
public enum Destination: Hashable, Sendable {
    case desk
    case yourTurn
    case subject(Int64)
    case project(Int64)

    /// Texto curto para guardar a escolha (`mesa`, `sua-vez`, `assunto:3`, `projeto:2`).
    public var storageKey: String {
        switch self {
        case .desk: "mesa"
        case .yourTurn: "sua-vez"
        case .subject(let id): "assunto:\(id)"
        case .project(let id): "projeto:\(id)"
        }
    }

    /// Lê o texto guardado; valor estranho vira `nil` e a janela abre na Mesa.
    public init?(storageKey: String) {
        switch storageKey {
        case "mesa": self = .desk
        case "sua-vez": self = .yourTurn
        default:
            let parts = storageKey.split(separator: ":", maxSplits: 1)
            guard parts.count == 2, let id = Int64(parts[1]) else { return nil }
            switch parts[0] {
            case "assunto": self = .subject(id)
            case "projeto": self = .project(id)
            default: return nil
            }
        }
    }
}

// Resumo: Para onde a janela está olhando dentro do projeto aberto (Mesa, Sua vez, um assunto ou um repositório) e como isso é lembrado.
// Tags: interface

/// Destino escolhido na lateral.
public enum Destination: Hashable, Sendable {
    case desk
    case yourTurn
    case subject(Int64)
    /// Uma pasta do projeto com terminal e arquivos: a raiz ou um dos repositórios, pelo caminho.
    case folder(String)

    /// Texto curto para guardar a escolha (`mesa`, `sua-vez`, `assunto:3`, `pasta:/caminho`).
    public var storageKey: String {
        switch self {
        case .desk: "mesa"
        case .yourTurn: "sua-vez"
        case .subject(let id): "assunto:\(id)"
        case .folder(let path): "pasta:\(path)"
        }
    }

    /// Lê o texto guardado; valor estranho vira `nil` e a janela abre na Mesa.
    public init?(storageKey: String) {
        switch storageKey {
        case "mesa": self = .desk
        case "sua-vez": self = .yourTurn
        default:
            let parts = storageKey.split(separator: ":", maxSplits: 1)
            guard parts.count == 2, !parts[1].isEmpty else { return nil }
            switch parts[0] {
            case "assunto":
                guard let id = Int64(parts[1]) else { return nil }
                self = .subject(id)
            case "pasta":
                guard parts[1].hasPrefix("/") else { return nil }
                self = .folder(String(parts[1]))
            default: return nil
            }
        }
    }
}

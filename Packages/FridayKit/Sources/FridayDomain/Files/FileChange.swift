// Resumo: Uma mudança observada no disco (arquivo criado, alterado, apagado ou renomeado) entregue em lotes pelo vigia.
// Tags: pastas, git

/// O que aconteceu com o caminho.
public enum FileChangeKind: String, Sendable {
    case created
    case modified
    case removed
    case renamed
    /// O sistema perdeu detalhes: quem escuta deve reler tudo.
    case requiresRescan
}

/// Mudança em um caminho absoluto. Caminhos de dentro de `.git/` só chegam quando afetam o status do git.
public struct FileChange: Hashable, Sendable {
    public var path: String
    public var kind: FileChangeKind

    public init(path: String, kind: FileChangeKind) {
        self.path = path
        self.kind = kind
    }
}

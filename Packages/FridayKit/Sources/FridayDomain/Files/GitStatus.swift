// Resumo: Retrato do git de um projeto: branch, quanto está à frente ou atrás do remoto e cada arquivo alterado com seu tipo.
// Tags: git

/// Tipo de alteração de um arquivo no git.
public enum GitChangeKind: String, Codable, Sendable, CaseIterable {
    case modified
    case added
    case deleted
    case renamed
    case untracked
    case conflicted
}

/// Um arquivo alterado, com caminho relativo à raiz do repositório.
public struct GitFileChange: Hashable, Sendable {
    public var path: String
    /// Caminho anterior, só quando `kind` é `.renamed`.
    public var originalPath: String?
    public var kind: GitChangeKind

    public init(path: String, originalPath: String? = nil, kind: GitChangeKind) {
        self.path = path
        self.originalPath = originalPath
        self.kind = kind
    }
}

/// Estado do repositório no momento da leitura.
public struct GitStatus: Equatable, Sendable {
    /// Nome da branch; `nil` com HEAD solto (detached).
    public var branch: String?
    /// Branch remota acompanhada, quando existe.
    public var upstream: String?
    /// Commits locais ainda não enviados; `nil` sem upstream.
    public var ahead: Int?
    /// Commits do remoto ainda não trazidos; `nil` sem upstream.
    public var behind: Int?
    public var changes: [GitFileChange]

    public init(branch: String?, upstream: String? = nil, ahead: Int? = nil, behind: Int? = nil, changes: [GitFileChange] = []) {
        self.branch = branch
        self.upstream = upstream
        self.ahead = ahead
        self.behind = behind
        self.changes = changes
    }
}

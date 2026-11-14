// Resumo: Um item do disco (arquivo ou pasta) como a árvore de arquivos do projeto o enxerga.
// Tags: pastas

/// Arquivo ou pasta de um projeto, identificado pelo caminho absoluto.
public struct FileNode: Identifiable, Hashable, Sendable {
    public var name: String
    public var path: String
    public var isDirectory: Bool

    public var id: String { path }

    public init(name: String, path: String, isDirectory: Bool) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
    }
}

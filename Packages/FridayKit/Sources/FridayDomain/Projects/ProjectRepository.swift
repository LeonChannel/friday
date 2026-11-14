// Resumo: Contratos que a lista de projetos usa: onde os projetos são guardados e como saber se uma pasta é repositório git.
// Tags: projetos, persistencia, pastas

/// Onde os projetos ficam guardados. Produção usa o banco; teste usa memória.
public protocol ProjectRepository: Sendable {
    /// Entrega a lista completa e ordenada agora e de novo a cada mudança.
    func observeAll() -> AsyncThrowingStream<[Project], any Error>
    func contains(path: String) throws -> Bool
    @discardableResult func insert(_ project: Project) throws -> Project
    func delete(id: Int64) throws
}

/// Consulta ao disco sobre uma pasta, separada para o domínio não fazer IO.
public protocol FolderInspecting: Sendable {
    /// Diz o tipo da pasta, ou `nil` quando o caminho não é uma pasta existente.
    func kind(ofFolderAt path: String) -> ProjectKind?
}

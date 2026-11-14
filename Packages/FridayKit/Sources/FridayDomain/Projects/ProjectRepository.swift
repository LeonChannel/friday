// Resumo: Contratos que a lista de projetos usa: onde os projetos são guardados e como saber se uma pasta é repositório git.
// Tags: projetos, persistencia, pastas

import Foundation

/// Onde os projetos ficam guardados. Produção usa o banco; teste usa memória.
public protocol ProjectRepository: Sendable {
    /// Entrega a lista completa e ordenada agora e de novo a cada mudança.
    func observeAll() -> AsyncThrowingStream<[Project], any Error>
    func contains(path: String) throws -> Bool
    @discardableResult func insert(_ project: Project) throws -> Project
    func delete(id: Int64) throws
    /// Registra que o projeto foi aberto agora.
    func markOpened(id: Int64, at date: Date) throws
}

/// Consulta ao disco sobre uma pasta, separada para o domínio não fazer IO.
public protocol FolderInspecting: Sendable {
    /// Diz o tipo da pasta, ou `nil` quando o caminho não é uma pasta existente.
    func kind(ofFolderAt path: String) -> ProjectKind?
}

/// Um repositório git dentro de um projeto (o próprio projeto, quando ele é um repositório).
public struct CodeRepository: Hashable, Sendable, Identifiable {
    public var name: String
    /// Caminho absoluto da pasta do repositório.
    public var path: String
    public var id: String { path }

    public init(name: String, path: String) {
        self.name = name
        self.path = path
    }
}

/// Descobre os repositórios git de um projeto. O dev decide o que é projeto; o Friday só enxerga o que há dentro.
public protocol RepositoryDiscovering: Sendable {
    func repositories(inProjectAt path: String) -> [CodeRepository]
}

/// Cria projetos novos no disco: pasta vazia ou clone de um repositório.
public protocol ProjectCreating: Sendable {
    /// Cria `name` dentro de `parent` e, se pedido, roda `git init`. Devolve o caminho criado.
    func createFolder(named name: String, in parent: String, initializeGit: Bool) async throws -> String
    /// Clona `url` dentro de `parent`. Devolve o caminho do clone.
    func clone(_ url: String, into parent: String) async throws -> String
}

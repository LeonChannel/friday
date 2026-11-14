// Resumo: Estado da lista de projetos na tela: adiciona com validação, remove e acompanha o banco ao vivo.
// Tags: projetos, interface

import FridayDomain
import Foundation
import Observation

/// Estado da lista de projetos que a interface mostra e altera.
@MainActor
@Observable
public final class ProjectsModel {
    public private(set) var projects: [Project] = []
    public private(set) var loadError: String?

    private let repository: any ProjectRepository
    private let inspector: any FolderInspecting
    private let creator: (any ProjectCreating)?
    private let now: @Sendable () -> Date

    public init(
        repository: any ProjectRepository,
        inspector: any FolderInspecting,
        creator: (any ProjectCreating)? = nil,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.repository = repository
        self.inspector = inspector
        self.creator = creator
        self.now = now
    }

    /// Registra que o projeto foi aberto, para ele subir na seleção.
    public func markOpened(_ project: Project) throws {
        guard let id = project.id else { return }
        try repository.markOpened(id: id, at: now())
    }

    /// Cria a pasta no disco (com `git init` se pedido) e a cadastra como projeto.
    public func createFolder(named name: String, in parent: String, initializeGit: Bool) async throws -> Project {
        guard let creator else { throw ProjectError.commandFailed("Criar pasta não está disponível.") }
        let path = try await creator.createFolder(named: name, in: parent, initializeGit: initializeGit)
        return try add(path: path)
    }

    /// Clona o repositório dentro de `parent` e cadastra o clone como projeto.
    public func clone(_ url: String, into parent: String) async throws -> Project {
        guard let creator else { throw ProjectError.commandFailed("Clonar não está disponível.") }
        let path = try await creator.clone(url, into: parent)
        return try add(path: path)
    }

    /// Espelha o banco até a tarefa que chamou ser cancelada (use dentro de `.task`).
    public func observe() async {
        do {
            for try await projects in repository.observeAll() {
                self.projects = projects
            }
        } catch is CancellationError {
        } catch {
            loadError = error.localizedDescription
        }
    }

    /// Cadastra a pasta: normaliza o caminho, confere se existe e se já não está na lista.
    @discardableResult
    public func add(path rawPath: String) throws -> Project {
        let path = Project.normalizedPath(rawPath)
        guard let kind = inspector.kind(ofFolderAt: path) else { throw ProjectError.notADirectory(path) }
        guard try !repository.contains(path: path) else { throw ProjectError.alreadyAdded(path) }
        return try repository.insert(Project(name: Project.defaultName(forPath: path), path: path, kind: kind, addedAt: now()))
    }

    /// Tira o projeto da lista. A pasta no disco não é tocada.
    public func remove(_ project: Project) throws {
        guard let id = project.id else { return }
        try repository.delete(id: id)
    }
}

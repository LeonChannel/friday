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
    private let now: @Sendable () -> Date

    public init(repository: any ProjectRepository, inspector: any FolderInspecting, now: @escaping @Sendable () -> Date = Date.init) {
        self.repository = repository
        self.inspector = inspector
        self.now = now
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

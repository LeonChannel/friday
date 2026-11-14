import FridayDomain
import Foundation
import Observation

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

    /// Mirrors the repository until the calling task is cancelled (use it from `.task`).
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

    @discardableResult
    public func add(path rawPath: String) throws -> Project {
        let path = Project.normalizedPath(rawPath)
        guard let kind = inspector.kind(ofFolderAt: path) else { throw ProjectError.notADirectory(path) }
        guard try !repository.contains(path: path) else { throw ProjectError.alreadyAdded(path) }
        return try repository.insert(Project(name: Project.defaultName(forPath: path), path: path, kind: kind, addedAt: now()))
    }

    public func remove(_ project: Project) throws {
        guard let id = project.id else { return }
        try repository.delete(id: id)
    }
}

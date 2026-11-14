// Resumo: Prova o cadastro de projetos na tela: normaliza caminho, recusa inválido e duplicado, espelha o banco.
// Tags: projetos, interface, testes

import FridayDomain
import FridayFeatures
import Foundation
import Testing

@MainActor
struct ProjectsModelTests {
    @Test func addNormalizesPathAndUsesInspectedKind() throws {
        let repository = InMemoryProjectRepository()
        let model = makeModel(repository, kinds: ["/tmp/repo": .git])

        let added = try model.add(path: "/tmp/repo/")

        #expect(added.path == "/tmp/repo")
        #expect(added.name == "repo")
        #expect(added.kind == .git)
    }

    @Test func rejectsNonDirectory() {
        let model = makeModel(InMemoryProjectRepository(), kinds: [:])
        #expect(throws: ProjectError.notADirectory("/tmp/missing")) { try model.add(path: "/tmp/missing") }
    }

    @Test func rejectsDuplicate() throws {
        let model = makeModel(InMemoryProjectRepository(), kinds: ["/tmp/dup": .folder])
        try model.add(path: "/tmp/dup")
        #expect(throws: ProjectError.alreadyAdded("/tmp/dup")) { try model.add(path: "/tmp/dup/") }
    }

    @Test func observeMirrorsRepository() async throws {
        let repository = InMemoryProjectRepository()
        let model = makeModel(repository, kinds: ["/tmp/a": .folder])
        let observing = Task { await model.observe() }
        defer { observing.cancel() }

        try model.add(path: "/tmp/a")

        try await waitUntil { model.projects.map(\.name) == ["a"] }
    }

    private func makeModel(_ repository: InMemoryProjectRepository, kinds: [String: ProjectKind]) -> ProjectsModel {
        ProjectsModel(repository: repository, inspector: FixedFolderInspector(kinds: kinds), now: { Date(timeIntervalSince1970: 0) })
    }

    /// Espera uma condição com prazo, em vez de dormir um tempo fixo.
    private func waitUntil(timeout: Duration = .seconds(2), _ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            guard ContinuousClock.now < deadline else {
                Issue.record("condition not met within \(timeout)")
                return
            }
            await Task.yield()
        }
    }
}

private struct FixedFolderInspector: FolderInspecting {
    let kinds: [String: ProjectKind]
    func kind(ofFolderAt path: String) -> ProjectKind? { kinds[path] }
}

private final class InMemoryProjectRepository: ProjectRepository, @unchecked Sendable {
    // SAFETY: todo acesso passa pelo `lock`.
    private let lock = NSLock()
    private var projects: [Project] = []
    private var nextId: Int64 = 1
    private var continuations: [UUID: AsyncThrowingStream<[Project], any Error>.Continuation] = [:]

    func observeAll() -> AsyncThrowingStream<[Project], any Error> {
        AsyncThrowingStream { continuation in
            let id = UUID()
            let snapshot: [Project] = lock.withLock {
                continuations[id] = continuation
                return projects
            }
            continuation.yield(snapshot)
            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock { _ = self?.continuations.removeValue(forKey: id) }
            }
        }
    }

    func contains(path: String) throws -> Bool {
        lock.withLock { projects.contains { $0.path == path } }
    }

    func insert(_ project: Project) throws -> Project {
        var saved = project
        let (snapshot, listeners) = lock.withLock {
            saved.id = nextId
            nextId += 1
            projects.append(saved)
            projects.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return (projects, Array(continuations.values))
        }
        listeners.forEach { $0.yield(snapshot) }
        return saved
    }

    func markOpened(id: Int64, at date: Date) throws {
        let (snapshot, listeners) = lock.withLock {
            if let index = projects.firstIndex(where: { $0.id == id }) { projects[index].lastOpenedAt = date }
            return (projects, Array(continuations.values))
        }
        listeners.forEach { $0.yield(snapshot) }
    }

    func delete(id: Int64) throws {
        let (snapshot, listeners) = lock.withLock {
            projects.removeAll { $0.id == id }
            return (projects, Array(continuations.values))
        }
        listeners.forEach { $0.yield(snapshot) }
    }
}

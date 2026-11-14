// Resumo: Prova que cada pasta (raiz do projeto ou repositório) mantém as mesmas sessões, arquivos e repositórios ao ir e voltar.
// Tags: terminal, interface, testes

import FridayDomain
import FridayFeatures
import Foundation
import Testing

@MainActor
struct WorkspaceModelTests {
    private let planner = StubPlanner()

    private func makeWorkspace() -> WorkspaceModel {
        WorkspaceModel(
            planner: planner, events: NoEvents(), subjects: NoSubjects(),
            makeRepositoriesModel: { ProjectRepositoriesModel(projectPath: $0.path, discoverer: NoRepositories(), gitReader: NoGit()) },
            makeFilesModel: { ProjectFilesModel(rootPath: $0.path, folderReader: EmptyFolders(), gitReader: NoGit(), watcher: SilentWatcher()) }
        )
    }

    @Test func returnsSameModelsForSameFolder() {
        let workspace = makeWorkspace()
        let project = Project(id: 1, name: "a", path: "/tmp/a", kind: .folder, addedAt: .distantPast)

        #expect(workspace.terminals(for: project) === workspace.terminals(for: project))
        #expect(workspace.files(for: project) === workspace.files(for: project))
        #expect(workspace.repositories(for: project) === workspace.repositories(for: project))
    }

    @Test func repositoryInsideProjectGetsItsOwnTerminals() {
        let workspace = makeWorkspace()
        let root = Project(id: 1, name: "evup", path: "/tmp/evup", kind: .folder, addedAt: .distantPast)
        let repository = Project(name: "api", path: "/tmp/evup/api", kind: .git, addedAt: .distantPast)

        #expect(workspace.terminals(for: root) !== workspace.terminals(for: repository))
        #expect(workspace.terminals(for: repository).project.path == "/tmp/evup/api")
    }
}

private struct StubPlanner: LaunchPlanning {
    func plan(agent: AgentKind, project: Project, session: AgentSessionID) throws -> LaunchPlan {
        LaunchPlan(executable: "/bin/sh", arguments: [], environment: [:], workingDirectory: project.path)
    }
}

private struct NoEvents: AgentEventRepository {
    func record(_ event: AgentEvent) throws -> AgentEvent { event }
    func observe(session: AgentSessionID) -> AsyncThrowingStream<[AgentEvent], any Error> { AsyncThrowingStream { $0.finish() } }
    func observeRecent(limit: Int) -> AsyncThrowingStream<[AgentEvent], any Error> { AsyncThrowingStream { $0.finish() } }
}

private struct EmptyFolders: FolderReading {
    func children(ofFolderAt path: String) async throws -> [FileNode] { [] }
}

private struct NoGit: GitStatusReading {
    func status(forFolderAt path: String) async throws -> GitStatus? { nil }
}

private struct SilentWatcher: ChangeWatching {
    func changes(inFolderAt path: String) async -> AsyncStream<[FileChange]> { AsyncStream { $0.finish() } }
}

private struct NoSubjects: SubjectRepository {
    func observeAll() -> AsyncThrowingStream<[Subject], any Error> { AsyncThrowingStream { $0.finish() } }
    func observe(id: Int64) -> AsyncThrowingStream<Subject?, any Error> { AsyncThrowingStream { $0.finish() } }
    func all() throws -> [Subject] { [] }
    func subject(id: Int64) throws -> Subject? { nil }
    func insert(_ subject: Subject) throws -> Subject { subject }
    func update(id: Int64, _ change: @Sendable (inout Subject) throws -> Void) throws -> Subject { throw CancellationError() }
    func delete(id: Int64) throws {}
}

private struct NoRepositories: RepositoryDiscovering {
    func repositories(inProjectAt path: String) -> [CodeRepository] { [] }
}

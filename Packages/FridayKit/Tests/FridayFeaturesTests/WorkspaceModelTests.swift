// Resumo: Prova que cada projeto mantém as mesmas sessões de terminal ao ir e voltar.
// Tags: terminal, interface, testes

import FridayDomain
import FridayFeatures
import Foundation
import Testing

@MainActor
struct WorkspaceModelTests {
    private let planner = StubPlanner()

    @Test func returnsSameModelForSameProject() throws {
        let workspace = WorkspaceModel(planner: planner, events: NoEvents(), subjects: NoSubjects()) { project in ProjectFilesModel(rootPath: project.path, folderReader: EmptyFolders(), gitReader: NoGit(), watcher: SilentWatcher()) }
        let project = Project(id: 1, name: "a", path: "/tmp/a", kind: .folder, addedAt: .distantPast)

        let first = try #require(workspace.terminals(for: project))
        #expect(workspace.terminals(for: project) === first)
        #expect(workspace.visitedProjectIDs == [1])
        #expect(workspace.files(for: project) === workspace.files(for: project))
    }

    @Test func unsavedProjectHasNoTerminals() {
        let workspace = WorkspaceModel(planner: planner, events: NoEvents(), subjects: NoSubjects()) { project in ProjectFilesModel(rootPath: project.path, folderReader: EmptyFolders(), gitReader: NoGit(), watcher: SilentWatcher()) }
        #expect(workspace.terminals(for: Project(name: "x", path: "/tmp/x", kind: .folder, addedAt: .distantPast)) == nil)
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

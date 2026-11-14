// Resumo: Prova a árvore de arquivos e o git na tela: abre pasta sob demanda, marca status e recarrega só o necessário quando o vigia avisa.
// Tags: pastas, git, interface, testes

import FridayDomain
import FridayFeatures
import Foundation
import Testing

@MainActor
struct ProjectFilesModelTests {
    private let root = "/proj"

    private func node(_ path: String, folder: Bool = false) -> FileNode {
        FileNode(name: (path as NSString).lastPathComponent, path: path, isDirectory: folder)
    }

    private func makeFixture(status: GitStatus? = GitStatus(branch: "main")) -> (ProjectFilesModel, FakeFolderReader, FakeGitReader, FakeWatcher) {
        let reader = FakeFolderReader(tree: [
            "/proj": [node("/proj/src", folder: true), node("/proj/docs", folder: true), node("/proj/README.md")],
            "/proj/src": [node("/proj/src/main.swift")],
            "/proj/docs": [node("/proj/docs/a.md")],
        ])
        let git = FakeGitReader(status: status)
        let watcher = FakeWatcher()
        return (ProjectFilesModel(rootPath: root, folderReader: reader, gitReader: git, watcher: watcher), reader, git, watcher)
    }

    @Test func loadsOnlyRootUntilFolderIsExpanded() async throws {
        let (model, reader, _, _) = makeFixture()
        let task = Task { await model.start() }
        defer { task.cancel() }

        try await eventually { model.rootNodes.count == 3 }
        #expect(await reader.readPaths == ["/proj"])

        await model.setExpanded("/proj/src", true)
        #expect(model.children(of: node("/proj/src", folder: true)).map(\.name) == ["main.swift"])
        #expect(await reader.readPaths == ["/proj", "/proj/src"])
    }

    @Test func marksChangedFilesAndTheirFolders() async throws {
        let status = GitStatus(branch: "main", changes: [GitFileChange(path: "src/main.swift", kind: .modified)])
        let (model, _, _, _) = makeFixture(status: status)
        let task = Task { await model.start() }
        defer { task.cancel() }

        try await eventually { model.gitStatus != nil }
        #expect(model.changeKind(of: node("/proj/src/main.swift")) == .modified)
        #expect(model.hasChanges(in: node("/proj/src", folder: true)))
        #expect(!model.hasChanges(in: node("/proj/docs", folder: true)))
    }

    @Test func nonGitFolderHasNoStatus() async throws {
        let (model, _, git, _) = makeFixture(status: nil)
        let task = Task { await model.start() }
        defer { task.cancel() }

        try await eventually { model.rootNodes.count == 3 }
        try await eventually { await git.callCount == 1 }
        #expect(model.gitStatus == nil)
        #expect(model.errorMessage == nil)
    }

    @Test func batchReloadsOnlyAffectedOpenFolderAndRefreshesGit() async throws {
        let (model, reader, git, watcher) = makeFixture()
        let task = Task { await model.start() }
        defer { task.cancel() }
        try await eventually { model.rootNodes.count == 3 }
        await model.setExpanded("/proj/src", true)
        await model.setExpanded("/proj/docs", true)
        let readsBefore = await reader.readPaths.count
        let gitBefore = await git.callCount

        await reader.add(node("/proj/src/new.swift"), toFolder: "/proj/src")
        await git.set(GitStatus(branch: "main", changes: [GitFileChange(path: "src/new.swift", kind: .untracked)]))
        watcher.send([FileChange(path: "/proj/src/new.swift", kind: .created)])

        try await eventually { model.children(of: node("/proj/src", folder: true)).count == 2 }
        try await eventually { model.changeKind(of: node("/proj/src/new.swift")) == .untracked }
        #expect(await reader.readPaths.count == readsBefore + 1)
        #expect(await reader.readPaths.last == "/proj/src")
        #expect(await git.callCount == gitBefore + 1)
    }

    @Test func changeInsideClosedFolderOnlyRefreshesGit() async throws {
        let (model, reader, git, watcher) = makeFixture()
        let task = Task { await model.start() }
        defer { task.cancel() }
        try await eventually { model.rootNodes.count == 3 }
        let readsBefore = await reader.readPaths.count

        watcher.send([FileChange(path: "/proj/docs/a.md", kind: .modified)])

        try await eventually { await git.callCount == 2 }
        #expect(await reader.readPaths.count == readsBefore)
    }

    @Test func gitMetadataChangeRefreshesGitWithoutReadingFolders() async throws {
        let (model, reader, git, watcher) = makeFixture()
        let task = Task { await model.start() }
        defer { task.cancel() }
        try await eventually { model.rootNodes.count == 3 }
        let readsBefore = await reader.readPaths.count

        watcher.send([FileChange(path: "/proj/.git/HEAD", kind: .modified)])

        try await eventually { await git.callCount == 2 }
        #expect(await reader.readPaths.count == readsBefore)
    }

    @Test func removedOpenFolderLeavesTheTree() async throws {
        let (model, reader, _, watcher) = makeFixture()
        let task = Task { await model.start() }
        defer { task.cancel() }
        try await eventually { model.rootNodes.count == 3 }
        await model.setExpanded("/proj/docs", true)
        await reader.remove(folder: "/proj/docs")

        watcher.send([FileChange(path: "/proj/docs", kind: .removed)])

        try await eventually { !model.expandedPaths.contains("/proj/docs") }
        #expect(model.children(of: node("/proj/docs", folder: true)).isEmpty)
    }
}

// MARK: - Falsos

private actor FakeFolderReader: FolderReading {
    private var tree: [String: [FileNode]]
    private(set) var readPaths: [String] = []

    init(tree: [String: [FileNode]]) { self.tree = tree }

    func children(ofFolderAt path: String) async throws -> [FileNode] {
        readPaths.append(path)
        guard let nodes = tree[path] else { throw CocoaError(.fileReadNoSuchFile) }
        return nodes
    }

    func add(_ node: FileNode, toFolder folder: String) { tree[folder, default: []].append(node) }
    func remove(folder: String) { tree[folder] = nil }
}

private actor FakeGitReader: GitStatusReading {
    private var status: GitStatus?
    private(set) var callCount = 0

    init(status: GitStatus?) { self.status = status }

    func status(forFolderAt path: String) async throws -> GitStatus? {
        callCount += 1
        return status
    }

    func set(_ status: GitStatus?) { self.status = status }
}

private final class FakeWatcher: ChangeWatching, @unchecked Sendable {
    // SAFETY: todo acesso à `continuation` passa pelo `lock`.
    private let lock = NSLock()
    private var continuation: AsyncStream<[FileChange]>.Continuation?

    func changes(inFolderAt path: String) async -> AsyncStream<[FileChange]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [FileChange].self)
        lock.withLock { self.continuation = continuation }
        return stream
    }

    func send(_ batch: [FileChange]) { _ = lock.withLock { continuation }?.yield(batch) }
}

struct EventuallyTimedOut: Error {}

/// Repete a condição cedendo a vez até ela ser verdadeira ou o prazo estourar; nunca dorme um tempo fixo.
@MainActor
private func eventually(timeout: Duration = .seconds(5), _ condition: () async -> Bool) async throws {
    let deadline = ContinuousClock.now + timeout
    while !(await condition()) {
        if ContinuousClock.now > deadline { throw EventuallyTimedOut() }
        await Task.yield()
    }
}

// Resumo: Fluxo ponta a ponta sem tela: repositório git temporário, leitor, git e vigia reais; mexer no disco muda o que o modelo mostra.
// Tags: pastas, git, interface, testes

import FridayDomain
import FridayFeatures
import FridayInfrastructure
import Foundation
import Testing

@MainActor
@Suite(.tags(.integration))
struct ProjectFilesFlowTests {
    @Test func diskChangesReachTheModelThroughRealWatcherAndGit() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("friday-flow-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try git(["init", "-q", "-b", "main"], in: root)
        try Data("um".utf8).write(to: root.appendingPathComponent("a.txt"))
        try git(["add", "-A"], in: root)
        try git(["-c", "user.name=Teste", "-c", "user.email=teste@example.invalid", "-c", "commit.gpgsign=false", "commit", "-q", "-m", "c"], in: root)

        let model = ProjectFilesModel(rootPath: root.path, folderReader: LocalFolderReader(), gitReader: GitStatusReader(), watcher: FolderChangeWatcher(latency: 0.1))
        let task = Task { await model.start() }
        defer { task.cancel() }
        try await eventually { model.gitStatus?.branch == "main" && model.rootNodes.count == 1 }

        try Data("dois".utf8).write(to: root.appendingPathComponent("a.txt"))
        try Data("novo".utf8).write(to: root.appendingPathComponent("b b.txt"))

        try await eventually { model.rootNodes.count == 2 }
        try await eventually { model.gitStatus?.changes.count == 2 }
        #expect(model.changeKind(of: FileNode(name: "a.txt", path: model.rootPath + "/a.txt", isDirectory: false)) == .modified)
        #expect(model.changeKind(of: FileNode(name: "b b.txt", path: model.rootPath + "/b b.txt", isDirectory: false)) == .untracked)
    }

    private func git(_ arguments: [String], in directory: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        process.environment = ["PATH": "/usr/bin:/bin", "HOME": directory.path, "GIT_CONFIG_NOSYSTEM": "1"]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw CocoaError(.executableLoad) }
    }
}

extension Tag {
    @Tag static var integration: Self
}

private struct FlowTimedOut: Error {}

/// Cede a vez até a condição valer ou o prazo estourar; nunca dorme um tempo fixo.
@MainActor
private func eventually(timeout: Duration = .seconds(10), _ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now + timeout
    while !condition() {
        if ContinuousClock.now > deadline { throw FlowTimedOut() }
        await Task.yield()
    }
}

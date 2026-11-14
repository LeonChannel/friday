// Resumo: Prova a detecção de pasta comum, clone git, worktree, caminho inexistente e arquivo.
// Tags: pastas, git, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing

struct LocalFolderInspectorTests {
    private let inspector = LocalFolderInspector()

    @Test func detectsPlainFolderAndGitClone() throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        let plain = try temp.makeDirectory("plain")
        let clone = try temp.makeDirectory("clone")
        try FileManager.default.createDirectory(at: clone.appendingPathComponent(".git"), withIntermediateDirectories: true)

        #expect(inspector.kind(ofFolderAt: plain.path) == .folder)
        #expect(inspector.kind(ofFolderAt: clone.path) == .git)
    }

    @Test func detectsGitWorktreeWhoseDotGitIsAFile() throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        let worktree = try temp.makeDirectory("worktree")
        try Data("gitdir: /elsewhere".utf8).write(to: worktree.appendingPathComponent(".git"))

        #expect(inspector.kind(ofFolderAt: worktree.path) == .git)
    }

    @Test func rejectsMissingPathAndRegularFile() throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        let file = temp.url.appendingPathComponent("file.txt")
        try Data().write(to: file)

        #expect(inspector.kind(ofFolderAt: temp.url.appendingPathComponent("missing").path) == nil)
        #expect(inspector.kind(ofFolderAt: file.path) == nil)
    }
}

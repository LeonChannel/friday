// Resumo: Prova a descoberta de repositórios: o projeto que é repositório, a pasta com vários (até dois níveis) e as pastas ignoradas.
// Tags: projetos, git, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing

struct LocalRepositoryDiscovererTests {
    private let discoverer = LocalRepositoryDiscoverer()

    private func makeRepo(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url.appendingPathComponent(".git"), withIntermediateDirectories: true)
    }

    @Test func projectThatIsARepositoryIsItsOnlyRepository() throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        let repo = try temp.makeDirectory("app")
        try makeRepo(repo)
        try makeRepo(repo.appendingPathComponent("vendor-sub"))

        #expect(discoverer.repositories(inProjectAt: repo.path).map(\.name) == ["app"])
    }

    @Test func folderWithManyRepositoriesFindsThemUpToTwoLevels() throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        let root = try temp.makeDirectory("EVUP")
        try makeRepo(root.appendingPathComponent("ELOS-API"))
        try makeRepo(root.appendingPathComponent("ELOS-UI"))
        try makeRepo(root.appendingPathComponent("grupo/ELOS-FUNC"))
        try makeRepo(root.appendingPathComponent("a/b/fundo-demais"))
        try makeRepo(root.appendingPathComponent("node_modules/pacote"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("docs"), withIntermediateDirectories: true)

        let names = discoverer.repositories(inProjectAt: root.path).map(\.name)
        #expect(names == ["ELOS-API", "ELOS-UI", "ELOS-FUNC"])
    }

    @Test func worktreeWhoseDotGitIsAFileCounts() throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        let root = try temp.makeDirectory("ws")
        let worktree = try temp.makeDirectory("ws/feature")
        try Data("gitdir: /elsewhere".utf8).write(to: worktree.appendingPathComponent(".git"))

        #expect(discoverer.repositories(inProjectAt: root.path).map(\.name) == ["feature"])
    }

    @Test func plainFolderHasNoRepositories() throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        #expect(discoverer.repositories(inProjectAt: try temp.makeDirectory("notas").path).isEmpty)
    }
}

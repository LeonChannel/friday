// Resumo: Prova a criação de projetos: pasta nova com e sem git init, nomes inválidos, e clone de um repositório local (sem rede).
// Tags: projetos, git, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing

struct GitProjectCreatorTests {
    private let creator = GitProjectCreator()

    @Test(.tags(.integration)) func createsFolderWithAndWithoutGit() async throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        let plain = try await creator.createFolder(named: "notas", in: temp.url.path, initializeGit: false)
        let repo = try await creator.createFolder(named: "app novo", in: temp.url.path, initializeGit: true)

        #expect(!FileManager.default.fileExists(atPath: plain + "/.git"))
        #expect(FileManager.default.fileExists(atPath: repo + "/.git"))
        await #expect(throws: ProjectError.alreadyExists(repo)) { _ = try await creator.createFolder(named: "app novo", in: temp.url.path, initializeGit: false) }
    }

    @Test(arguments: ["", "  ", "a/b", ".", ".."])
    func rejectsBadFolderNames(name: String) async throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        await #expect(throws: ProjectError.self) { _ = try await creator.createFolder(named: name, in: temp.url.path, initializeGit: false) }
    }

    @Test(.tags(.integration)) func clonesALocalRepository() async throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        let source = try await creator.createFolder(named: "origem", in: temp.url.path, initializeGit: true)
        try Data("oi".utf8).write(to: URL(fileURLWithPath: source).appendingPathComponent("a.txt"))
        try git(["add", "."], in: source)
        try git(["-c", "user.name=Teste", "-c", "user.email=teste@exemplo.invalid", "commit", "-qm", "inicial"], in: source)
        let destination = try temp.makeDirectory("clones")

        let clone = try await creator.clone(source, into: destination.path)

        #expect(clone == destination.appendingPathComponent("origem").path)
        #expect(FileManager.default.fileExists(atPath: clone + "/a.txt"))
    }

    @Test func cloneOfMissingRepositoryReportsGitError() async throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        await #expect(throws: ProjectError.self) { _ = try await creator.clone(temp.url.path + "/nao-existe", into: temp.url.path) }
    }

    @Test(arguments: [
        ("https://github.com/dono/repo.git", "repo"),
        ("git@github.com:dono/outro.git", "outro"),
        ("/caminho/local/projeto", "projeto"),
    ])
    func folderNameFollowsGit(url: String, expected: String) {
        #expect(GitProjectCreator.folderName(forRepositoryURL: url) == expected)
    }

    @Test func folderNameRejectsNonsense() {
        #expect(GitProjectCreator.folderName(forRepositoryURL: "") == nil)
        #expect(GitProjectCreator.folderName(forRepositoryURL: "não é url") == nil)
    }

    private func git(_ arguments: [String], in directory: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = URL(fileURLWithPath: directory)
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
    }
}

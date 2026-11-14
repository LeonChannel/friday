// Resumo: Roda o git de verdade num repositório temporário e prova modificado, novo, renomeado, apagado, não rastreado e pasta sem git.
// Tags: git, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing

@Suite(.tags(.integration))
struct GitStatusReaderTests {
    private let reader = GitStatusReader()

    @Test func reportsCleanRepositoryOnItsBranch() async throws {
        let repo = try TemporaryGitRepository()
        defer { repo.remove() }
        try repo.write("a.txt")
        try repo.commitAll()

        let status = try #require(await reader.status(forFolderAt: repo.path))
        #expect(status.branch == "main")
        #expect(status.changes.isEmpty)
        #expect(status.upstream == nil)
    }

    @Test func reflectsModifiedUntrackedRenamedAndDeletedFiles() async throws {
        let repo = try TemporaryGitRepository()
        defer { repo.remove() }
        try repo.write("modify me.txt", "one")
        try repo.write("rename-me.txt", "some content that git can match as a rename")
        try repo.write("delete-me.txt", "bye")
        try repo.commitAll()

        try repo.write("modify me.txt", "two")
        try repo.write("brand new.txt")
        try repo.write("dir/nested.txt")
        try repo.runGit(["mv", "rename-me.txt", "renamed file.txt"])
        try FileManager.default.removeItem(at: repo.directory.url.appendingPathComponent("delete-me.txt"))

        let status = try #require(await reader.status(forFolderAt: repo.path))
        let byPath = Dictionary(uniqueKeysWithValues: status.changes.map { ($0.path, $0) })
        #expect(byPath["modify me.txt"]?.kind == .modified)
        #expect(byPath["brand new.txt"]?.kind == .untracked)
        #expect(byPath["dir/nested.txt"]?.kind == .untracked)
        #expect(byPath["delete-me.txt"]?.kind == .deleted)
        #expect(byPath["renamed file.txt"]?.kind == .renamed)
        #expect(byPath["renamed file.txt"]?.originalPath == "rename-me.txt")
    }

    @Test func reportsStagedAdditionAsAdded() async throws {
        let repo = try TemporaryGitRepository()
        defer { repo.remove() }
        try repo.write("a.txt")
        try repo.commitAll()
        try repo.write("b.txt")
        try repo.runGit(["add", "b.txt"])

        let status = try #require(await reader.status(forFolderAt: repo.path))
        #expect(status.changes == [GitFileChange(path: "b.txt", kind: .added)])
    }

    @Test func returnsNilForFolderWithoutGit() async throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        #expect(try await reader.status(forFolderAt: temp.url.path) == nil)
    }
}

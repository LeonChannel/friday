// Resumo: Prova a leitura de pasta: um nível por vez, pastas primeiro, ordem alfabética e .git e .DS_Store escondidos.
// Tags: pastas, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing

struct LocalFolderReaderTests {
    private let reader = LocalFolderReader()

    @Test func listsFoldersFirstThenAlphabeticalHidingGitAndDSStore() async throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        for folder in ["zeta", "Alpha", ".git"] { _ = try temp.makeDirectory(folder) }
        for file in ["b.txt", "A.txt", ".DS_Store", ".gitignore", "file10.txt", "file2.txt"] {
            try Data().write(to: temp.url.appendingPathComponent(file))
        }

        let nodes = try await reader.children(ofFolderAt: temp.url.path)
        #expect(nodes.map(\.name) == ["Alpha", "zeta", ".gitignore", "A.txt", "b.txt", "file2.txt", "file10.txt"])
        #expect(nodes.prefix(2).allSatisfy { $0.isDirectory })
        #expect(nodes.dropFirst(2).allSatisfy { !$0.isDirectory })
    }

    @Test func readsOnlyOneLevel() async throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        let inner = try temp.makeDirectory("outer/inner")
        try Data().write(to: inner.appendingPathComponent("deep.txt"))

        let top = try await reader.children(ofFolderAt: temp.url.path)
        #expect(top.map(\.name) == ["outer"])
        let outer = try await reader.children(ofFolderAt: top[0].path)
        #expect(outer.map(\.name) == ["inner"])
    }

    @Test func treatsSymlinkToFolderAsFile() async throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        let target = try temp.makeDirectory("target")
        try FileManager.default.createSymbolicLink(at: temp.url.appendingPathComponent("link"), withDestinationURL: target)

        let nodes = try await reader.children(ofFolderAt: temp.url.path)
        #expect(nodes.first { $0.name == "link" }?.isDirectory == false)
    }
}

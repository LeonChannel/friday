import Foundation
import GRDB
import Testing
@testable import Friday

@MainActor
struct ProjectStoreTests {
    private func makeStore() throws -> ProjectStore {
        try ProjectStore(db: DatabaseQueue())
    }

    private func makeTempDir(_ name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("friday-tests-\(UUID().uuidString)/\(name)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func addsFolderAndDetectsGit() throws {
        let store = try makeStore()
        let plain = try makeTempDir("plain")
        let repo = try makeTempDir("repo")
        try FileManager.default.createDirectory(at: repo.appendingPathComponent(".git"), withIntermediateDirectories: true)

        try store.add(path: plain.path)
        try store.add(path: repo.path)

        #expect(store.all.map(\.name) == ["plain", "repo"])
        #expect(store.all.first { $0.name == "plain" }?.isGitRepository == false)
        #expect(store.all.first { $0.name == "repo" }?.isGitRepository == true)
    }

    @Test func rejectsDuplicateAndNonDirectory() throws {
        let store = try makeStore()
        let dir = try makeTempDir("dup")
        try store.add(path: dir.path)

        #expect(throws: ProjectStoreError.alreadyAdded(dir.standardizedFileURL.path)) { try store.add(path: dir.path + "/") }
        #expect(throws: ProjectStoreError.self) { try store.add(path: dir.appendingPathComponent("missing").path) }
    }

    @Test func removesProject() throws {
        let store = try makeStore()
        let project = try store.add(path: try makeTempDir("gone").path)
        try store.remove(project.id)
        #expect(store.all.isEmpty)
    }
}

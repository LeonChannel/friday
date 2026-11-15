// Resumo: Prova o espelho do backlog no vault: um arquivo por item e o índice, arquivo de item apagado sai, sem vault fica calado e a memória não lê a pasta.
// Tags: backlog, memoria, testes

import FridayDomain
import Foundation
import Testing
@testable import FridayInfrastructure

@Suite(.tags(.integration))
struct BacklogMirrorTests {
    private let now = Date(timeIntervalSince1970: 1_000)

    @Test func writesOneFilePerItemAndRemovesDeleted() throws {
        let dir = try TemporaryDirectory()
        defer { dir.remove() }
        let vault = try dir.makeDirectory("vault").path
        let database = try AppDatabase.inMemory()
        let project = try GRDBProjectRepository(database: database).insert(Project(name: "Friday", path: "/tmp/friday", kind: .git, addedAt: now))
        let projectID = try #require(project.id)
        let repository = MirroredBacklogRepository(
            inner: GRDBBacklogRepository(database: database),
            mirror: BacklogMirror(vaultRoot: { vault }, projectName: { $0 == projectID ? "Friday" : nil })
        )
        let epic = try repository.insert(BacklogItem(projectID: projectID, kind: .epic, title: "Login", createdAt: now))
        let bug = try repository.insert(BacklogItem(projectID: projectID, kind: .bug, title: "Token no log", author: .claude, createdAt: now))
        let folder = URL(fileURLWithPath: vault).appendingPathComponent("Projetos/Friday/Backlog")
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: folder.path)) == ["00 - Backlog.md", "FRI-1.md", "FRI-2.md"])
        #expect(try String(contentsOf: folder.appendingPathComponent("FRI-2.md"), encoding: .utf8).contains("estado: novo"))

        try repository.update(id: try #require(bug.id)) { try $0.setParent(epic, at: now) }
        #expect(try String(contentsOf: folder.appendingPathComponent("FRI-2.md"), encoding: .utf8).contains("pai: FRI-1"))

        try repository.update(id: try #require(bug.id)) { try $0.setParent(nil, at: now) }
        try repository.delete(id: try #require(bug.id))
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: folder.path)) == ["00 - Backlog.md", "FRI-1.md"])

        // A pasta do backlog não vira nota de memória (nem com problema de formato).
        let load = try FileMemoryVault(rootPath: vault).load(.project, projectName: "Friday")
        #expect(!load.notes.contains { $0.path.contains("/Backlog/") })
        #expect(!load.issues.contains { $0.path.contains("/Backlog/") })
    }

    @Test func withoutVaultMirrorIsSilent() throws {
        let mirror = BacklogMirror(vaultRoot: { nil }, projectName: { _ in "Friday" })
        try mirror.sync(projectID: 1, items: [try BacklogItem(projectID: 1, number: 1, kind: .bug, title: "x", createdAt: now)])
    }
}

// Resumo: Prova que o banco guarda, apaga e avisa mudanças de projetos na ordem certa.
// Tags: projetos, persistencia, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing

struct GRDBProjectRepositoryTests {
    private func makeRepository() throws -> GRDBProjectRepository {
        GRDBProjectRepository(database: try AppDatabase.inMemory())
    }

    private func project(_ name: String, kind: ProjectKind = .folder) -> Project {
        Project(name: name, path: "/tmp/\(name)", kind: kind, addedAt: Date(timeIntervalSince1970: 0))
    }

    @Test func insertAssignsIdAndKeepsKind() throws {
        let repository = try makeRepository()
        let saved = try repository.insert(project("repo", kind: .git))
        #expect(saved.id != nil)
        #expect(saved.kind == .git)
        #expect(try repository.contains(path: "/tmp/repo"))
    }

    @Test func deleteRemovesProject() throws {
        let repository = try makeRepository()
        let saved = try repository.insert(project("gone"))
        try repository.delete(id: try #require(saved.id))
        #expect(try !repository.contains(path: "/tmp/gone"))
    }

    @Test func observationEmitsSortedListAfterChanges() async throws {
        let repository = try makeRepository()
        var iterator = repository.observeAll().makeAsyncIterator()

        #expect(try await iterator.next() == [])
        try repository.insert(project("beta"))
        #expect(try await iterator.next()?.map(\.name) == ["beta"])
        try repository.insert(project("Alfa"))
        #expect(try await iterator.next()?.map(\.name) == ["Alfa", "beta"])
    }
}

struct GRDBProjectRepositoryOpenedTests {
    @Test func recentlyOpenedComeFirstThenByName() async throws {
        let repository = GRDBProjectRepository(database: try AppDatabase.inMemory())
        let beta = try repository.insert(Project(name: "beta", path: "/tmp/beta", kind: .folder, addedAt: .distantPast))
        try repository.insert(Project(name: "alfa", path: "/tmp/alfa", kind: .folder, addedAt: .distantPast))
        try repository.insert(Project(name: "gama", path: "/tmp/gama", kind: .folder, addedAt: .distantPast))

        try repository.markOpened(id: try #require(beta.id), at: Date(timeIntervalSince1970: 100))

        var iterator = repository.observeAll().makeAsyncIterator()
        let names = try await iterator.next()?.map(\.name)
        #expect(names == ["beta", "alfa", "gama"])
    }
}

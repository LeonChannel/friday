// Resumo: Prova o backlog no banco: número por projeto, hierarquia conferida na transação (inclusive volta), apagar com filhos e a lista ao vivo.
// Tags: backlog, persistencia, testes

import FridayDomain
import Foundation
import Testing
@testable import FridayInfrastructure

struct GRDBBacklogRepositoryTests {
    private let now = Date(timeIntervalSince1970: 1_000)

    private func setup() throws -> (GRDBBacklogRepository, Int64, Int64) {
        let database = try AppDatabase.inMemory()
        let projects = GRDBProjectRepository(database: database)
        let a = try projects.insert(Project(name: "Friday", path: "/tmp/a", kind: .git, addedAt: now))
        let b = try projects.insert(Project(name: "Outro", path: "/tmp/b", kind: .git, addedAt: now))
        return (GRDBBacklogRepository(database: database), try #require(a.id), try #require(b.id))
    }

    private func new(_ kind: BacklogKind, _ project: Int64, parent: Int64? = nil) throws -> BacklogItem {
        try BacklogItem(projectID: project, kind: kind, title: "\(kind.label) novo", parentID: parent, createdAt: now)
    }

    @Test func numbersAreSequentialPerProject() throws {
        let (repository, a, b) = try setup()
        #expect(try repository.insert(new(.bug, a)).number == 1)
        #expect(try repository.insert(new(.bug, a)).number == 2)
        #expect(try repository.insert(new(.bug, b)).number == 1)
        #expect(try repository.item(projectID: a, number: 2)?.number == 2)
        #expect(try repository.all(projectID: a).map(\.number) == [1, 2])
    }

    @Test func insertChecksParentInsideTransaction() throws {
        let (repository, a, b) = try setup()
        let epic = try repository.insert(new(.epic, a))
        let story = try repository.insert(new(.story, a, parent: epic.id))
        #expect(story.parentID == epic.id)
        #expect(throws: BacklogError.invalidParent(child: .epic, parent: .story)) { try repository.insert(new(.epic, a, parent: story.id)) }
        #expect(throws: BacklogError.parentInOtherProject) { try repository.insert(new(.story, b, parent: epic.id)) }
        #expect(throws: BacklogError.needsParent(.subtask)) { try repository.insert(new(.subtask, a)) }
        #expect(try repository.all(projectID: a).count == 2)
    }

    @Test func updateKeepsNumberAndRefusesLoop() throws {
        let (repository, a, _) = try setup()
        let task = try repository.insert(new(.task, a))
        let bug = try repository.insert(new(.bug, a))
        let sub = try repository.insert(new(.subtask, a, parent: bug.id))
        let moved = try repository.update(id: try #require(task.id)) { item in
            item.number = 99
            item.move(to: .doing, at: now)
        }
        #expect(moved.number == task.number && moved.status == .doing)
        // Subtask não pode virar pai de nada, e um item não pode ir para dentro de quem está dentro dele.
        #expect(throws: BacklogError.self) { try repository.update(id: try #require(bug.id)) { $0.parentID = sub.id } }
        #expect(try repository.item(id: try #require(bug.id))?.parentID == nil)
    }

    @Test func deleteRefusesItemWithChildren() throws {
        let (repository, a, _) = try setup()
        let epic = try repository.insert(new(.epic, a))
        let story = try repository.insert(new(.story, a, parent: epic.id))
        #expect(throws: BacklogError.hasChildren("#1", count: 1)) { try repository.delete(id: try #require(epic.id)) }
        try repository.delete(id: try #require(story.id))
        try repository.delete(id: try #require(epic.id))
        #expect(try repository.all(projectID: a).isEmpty)
    }

    @Test func observeEmitsOnWrite() async throws {
        let (repository, a, _) = try setup()
        var iterator = repository.observeAll(projectID: a).makeAsyncIterator()
        #expect(try await iterator.next()?.isEmpty == true)
        try repository.insert(new(.bug, a))
        #expect(try await iterator.next()?.count == 1)
    }
}

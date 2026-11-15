// Resumo: Prova o backlog na tela: quadro de bugs por coluna, árvore sem bug solto e sem feito (salvo pai de item aberto), arrastar pelo código e criar item pendurado.
// Tags: backlog, interface, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing
@testable import FridayFeatures

@MainActor
struct BacklogModelTests {
    private func makeModel() throws -> (BacklogModel, GRDBBacklogRepository, Int64) {
        let database = try AppDatabase.inMemory()
        let project = try GRDBProjectRepository(database: database).insert(Project(name: "Friday", path: "/tmp/friday", kind: .git, addedAt: .distantPast))
        let repository = GRDBBacklogRepository(database: database)
        let model = BacklogModel(project: project, repository: repository, now: { Date(timeIntervalSince1970: 1_000) })
        return (model, repository, try #require(project.id))
    }

    /// Espera o model refletir o banco cedendo a vez, sem sleep: a observação entrega logo após a escrita.
    private func until(_ condition: () -> Bool) async {
        while !condition() { await Task.yield() }
    }

    @Test(.timeLimit(.minutes(1))) func boardTreeAndDragByCode() async throws {
        let (model, repository, projectID) = try makeModel()
        let observing = Task { await model.observe() }
        defer { observing.cancel() }
        let epic = try model.create(kind: .epic, title: "Login")
        try model.create(kind: .story, title: "Entrar", parent: epic)
        try repository.insert(BacklogItem(projectID: projectID, kind: .bug, title: "Token no log", author: .claude, createdAt: .now))
        try repository.insert(BacklogItem(projectID: projectID, kind: .bug, title: "Erro de digitação", parentID: epic.id, createdAt: .now))
        await until { model.items.count == 4 }

        #expect(model.newBugCount == 1)
        #expect(model.board.map(\.status) == [.new, .todo, .doing, .review, .done])
        #expect(model.board[0].items.map(\.number) == [3])
        // Bug solto fica só no quadro; bug dentro do épico aparece na árvore.
        let tree = model.tree(includingDone: false)
        #expect(tree.map(\.item.number) == [1])
        #expect(tree[0].children?.map(\.item.number) == [2, 4])

        #expect(model.move(codes: ["FRI-3"], to: .doing))
        #expect(!model.move(codes: ["FRI-99", "lixo"], to: .doing))
        await until { model.newBugCount == 0 }
        #expect(model.newBugCount == 0 && model.board[2].items.map(\.number) == [3])

        // Épico feito com filho aberto continua na árvore, para o filho não ficar solto na raiz.
        try model.move(epic, to: .done)
        await until { model.items.first { $0.number == 1 }?.status == .done }
        #expect(model.tree(includingDone: false).map(\.item.number) == [1])
        let story = try #require(model.items.first { $0.number == 2 })
        let bug = try #require(model.items.first { $0.number == 4 })
        try model.move(story, to: .done)
        try model.move(bug, to: .done)
        await until { model.tree(includingDone: false).isEmpty }
        #expect(model.tree(includingDone: true).count == 1)
        #expect(model.possibleParents(for: .subtask).map(\.number) == [3])
    }
}

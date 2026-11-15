// Resumo: Estado do backlog do projeto aberto na tela: colunas do quadro de bugs, árvore de épicos e histórias, e as ações de criar, mover e editar.
// Tags: backlog, interface

import FridayDomain
import Foundation
import Observation

/// Um item com os filhos já pendurados, para a árvore da tela.
public struct BacklogNode: Identifiable, Equatable, Sendable {
    public var item: BacklogItem
    /// `nil` quando não tem filhos (a `List` não desenha a seta).
    public var children: [BacklogNode]?
    public var id: Int64 { item.id ?? -Int64(item.number) }
}

/// Backlog de um projeto, espelhando o banco ao vivo.
@MainActor
@Observable
public final class BacklogModel {
    public let project: Project
    public private(set) var items: [BacklogItem] = []
    public private(set) var loadError: String?

    private let repository: any BacklogRepository
    private let now: @Sendable () -> Date
    private var isObserving = false

    /// Colunas do quadro de bugs; descartado fica fora.
    public static let boardStatuses: [BacklogStatus] = [.new, .todo, .doing, .review, .done]

    public init(project: Project, repository: any BacklogRepository, now: @escaping @Sendable () -> Date = Date.init) {
        self.project = project
        self.repository = repository
        self.now = now
    }

    /// Sigla dos códigos do projeto (`FRI`).
    public var key: String { BacklogCode.key(forProjectName: project.name) }

    /// Código do item (`FRI-12`).
    public func code(_ item: BacklogItem) -> String { BacklogCode.format(key: key, number: item.number) }

    /// Espelha o banco até a tarefa que chamou ser cancelada. Uma segunda chamada simultânea volta na hora (a lateral e a tela pedem juntas).
    public func observe() async {
        guard !isObserving, let projectID = project.id else { return }
        isObserving = true
        defer { isObserving = false }
        do {
            for try await items in repository.observeAll(projectID: projectID) {
                self.items = items
            }
        } catch is CancellationError {
        } catch {
            loadError = error.localizedDescription
        }
    }

    // MARK: Projeções

    /// Bugs em cada coluna do quadro.
    public var board: [(status: BacklogStatus, items: [BacklogItem])] {
        BacklogProjection.columns(items.filter { $0.kind == .bug }, statuses: Self.boardStatuses)
    }

    /// Bugs que o Claude anotou e ainda esperam triagem.
    public var newBugCount: Int { items.count { $0.kind == .bug && $0.status == .new } }

    /// Bugs descartados (fora do quadro).
    public var discardedBugCount: Int { items.count { $0.kind == .bug && $0.status == .discarded } }

    /// Árvore de épicos, histórias, tasks e subtasks. Bug solto mora no quadro de bugs; bug dentro de um item aparece aqui também.
    /// Sem `includingDone`, item feito some, a não ser que ainda tenha algo aberto dentro (o filho não fica solto na raiz).
    public func tree(includingDone: Bool) -> [BacklogNode] {
        let visible = items.filter { $0.status != .discarded && !($0.kind == .bug && $0.parentID == nil) }
        let children = BacklogProjection.children(visible)
        func nodes(_ parent: Int64?) -> [BacklogNode] {
            (children[parent] ?? []).compactMap { item in
                let below = item.id.map(nodes) ?? []
                if !includingDone, item.status == .done, below.isEmpty { return nil }
                return BacklogNode(item: item, children: below.isEmpty ? nil : below)
            }
        }
        return nodes(nil)
    }

    /// Itens abertos que podem ser pai de um item novo do tipo dado.
    public func possibleParents(for kind: BacklogKind) -> [BacklogItem] {
        items.filter { kind.allowedParents.contains($0.kind) && !$0.status.isClosed }
    }

    /// O pai do item, se houver.
    public func parent(of item: BacklogItem) -> BacklogItem? {
        item.parentID.flatMap { id in items.first { $0.id == id } }
    }

    // MARK: Ações

    /// Cria um item do dev (já entra em "A fazer").
    @discardableResult
    public func create(kind: BacklogKind, title: String, parent: BacklogItem? = nil) throws -> BacklogItem {
        guard let projectID = project.id else { throw BacklogError.itemNotFound(key) }
        return try repository.insert(BacklogItem(projectID: projectID, kind: kind, title: title, author: .you, parentID: parent?.id, createdAt: now()))
    }

    /// Move o item para outro estado.
    public func move(_ item: BacklogItem, to status: BacklogStatus) throws {
        guard let id = item.id, item.status != status else { return }
        let date = now()
        try repository.update(id: id) { $0.move(to: status, at: date) }
    }

    /// Move pelos códigos arrastados no quadro. Devolve se algum item mudou.
    @discardableResult
    public func move(codes: [String], to status: BacklogStatus) -> Bool {
        var moved = false
        for code in codes {
            guard let number = BacklogCode.number(from: code), let item = items.first(where: { $0.number == number }), item.status != status else { continue }
            if (try? move(item, to: status)) != nil { moved = true }
        }
        return moved
    }

    /// Grava o que o dev mudou na ficha do item.
    public func save(_ item: BacklogItem, title: String, detail: String, location: String, priority: BacklogPriority, status: BacklogStatus, externalRef: String) throws {
        guard let id = item.id else { return }
        let date = now()
        try repository.update(id: id) { current in
            try current.setTitle(title, at: date)
            try current.setDetail(detail, at: date)
            try current.setLocation(location, at: date)
            try current.setExternalRef(externalRef, at: date)
            current.priority = priority
            current.move(to: status, at: date)
        }
    }
}

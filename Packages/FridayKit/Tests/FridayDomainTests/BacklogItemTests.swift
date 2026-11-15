// Resumo: Prova as regras do item do backlog: hierarquia de pais, tetos, estado inicial por autor, código legível, duplicata, colunas e árvore.
// Tags: backlog, testes

import Foundation
import Testing
@testable import FridayDomain

struct BacklogItemTests {
    private let now = Date(timeIntervalSince1970: 1_000)

    private func item(_ id: Int64, _ kind: BacklogKind, number: Int? = nil, project: Int64 = 1, parent: Int64? = nil,
                      status: BacklogStatus = .todo, priority: BacklogPriority = .medium, title: String? = nil) throws -> BacklogItem {
        try BacklogItem(id: id, projectID: project, number: number ?? Int(id), kind: kind, title: title ?? "Item \(id)",
                        priority: priority, status: status, parentID: parent, createdAt: now)
    }

    @Test func hierarchyAcceptsOnlyAllowedParents() throws {
        let epic = try item(1, .epic), story = try item(2, .story), task = try item(3, .task), bug = try item(4, .bug)
        try BacklogItem.checkParent(epic, forChild: story)
        try BacklogItem.checkParent(story, forChild: task)
        try BacklogItem.checkParent(story, forChild: bug)
        try BacklogItem.checkParent(bug, forChild: try item(5, .subtask))
        try BacklogItem.checkParent(nil, forChild: bug)
        #expect(throws: BacklogError.invalidParent(child: .epic, parent: .epic)) { try BacklogItem.checkParent(try item(9, .epic), forChild: epic) }
        #expect(throws: BacklogError.invalidParent(child: .story, parent: .task)) { try BacklogItem.checkParent(task, forChild: story) }
        #expect(throws: BacklogError.needsParent(.subtask)) { try BacklogItem.checkParent(nil, forChild: try item(5, .subtask)) }
        #expect(throws: BacklogError.parentInOtherProject) { try BacklogItem.checkParent(try item(7, .epic, project: 2), forChild: story) }
    }

    @Test func authorDecidesInitialStatus() throws {
        #expect(try BacklogItem(projectID: 1, kind: .bug, title: "x", author: .claude, createdAt: now).status == .new)
        #expect(try BacklogItem(projectID: 1, kind: .bug, title: "x", author: .you, createdAt: now).status == .todo)
    }

    @Test func rejectsEmptyAndLongTexts() throws {
        #expect(throws: BacklogError.empty(field: "Título")) { try BacklogItem(projectID: 1, kind: .task, title: "  ", createdAt: now) }
        let long = String(repeating: "a", count: BacklogLimits.title + 1)
        #expect(throws: BacklogError.tooLong(field: "Título", limit: BacklogLimits.title, actual: long.count)) {
            try BacklogItem(projectID: 1, kind: .task, title: long, createdAt: now)
        }
        let blank = try BacklogItem(projectID: 1, kind: .bug, title: "x", location: "   ", externalRef: "", createdAt: now)
        #expect(blank.location == nil && blank.externalRef == nil)
    }

    @Test(arguments: [("Friday", "FRI"), ("Lousa de Refinamento", "LDR"), ("Ação/API", "AA"), ("x", "X"), ("123", "ITEM"), ("ELOS-API", "EA")])
    func keyComesFromProjectName(name: String, key: String) {
        #expect(BacklogCode.key(forProjectName: name) == key)
    }

    @Test func codeParsesNumberFromAnyForm() {
        #expect(BacklogCode.number(from: "FRI-12") == 12)
        #expect(BacklogCode.number(from: "fri-12") == 12)
        #expect(BacklogCode.number(from: "#7") == 7)
        #expect(BacklogCode.number(from: "7") == 7)
        #expect(BacklogCode.number(from: "FRI-0") == nil)
        #expect(BacklogCode.number(from: "abc") == nil)
    }

    @Test func cliNamesAcceptAccents() {
        #expect(BacklogKind(cliName: "história") == .story)
        #expect(BacklogKind(cliName: "Epico") == .epic)
        #expect(BacklogStatus(cliName: "revisão") == .review)
        #expect(BacklogPriority(cliName: "critica") == .critical)
        #expect(BacklogPriority(cliName: "média") == .medium)
        #expect(BacklogKind(cliName: "feature") == nil)
    }

    @Test func duplicateIgnoresCaseAccentAndClosedItems() throws {
        let items = [
            try item(1, .bug, status: .done, title: "Lista pisca"),
            try item(2, .bug, status: .new, title: "Sessão  expira cedo"),
        ]
        #expect(BacklogProjection.openDuplicate(of: "lista pisca", kind: .bug, in: items) == nil)
        #expect(BacklogProjection.openDuplicate(of: "sessao expira cedo", kind: .bug, in: items)?.id == 2)
        #expect(BacklogProjection.openDuplicate(of: "sessao expira cedo", kind: .task, in: items) == nil)
    }

    @Test func columnsSortByPriorityThenAge() throws {
        let items = [
            try item(1, .bug, status: .todo, priority: .low),
            try item(2, .bug, status: .todo, priority: .critical),
            try item(3, .bug, status: .todo, priority: .low),
            try item(4, .bug, status: .doing),
        ]
        let columns = BacklogProjection.columns(items, statuses: [.todo, .doing, .done])
        #expect(columns.map(\.status) == [.todo, .doing, .done])
        #expect(columns[0].items.map(\.number) == [2, 1, 3])
        #expect(columns[1].items.map(\.number) == [4])
        #expect(columns[2].items.isEmpty)
    }

    @Test func orphanChildMovesToRoot() throws {
        let items = [try item(1, .epic), try item(2, .story, parent: 1), try item(3, .task, parent: 99)]
        let children = BacklogProjection.children(items)
        #expect(children[nil]?.map(\.number) == [1, 3])
        #expect(children[1]?.map(\.number) == [2])
    }

    @Test func markdownShowsCodeLocationAndChildren() throws {
        let epic = try item(1, .epic, title: "Login")
        let bug = try BacklogItem(id: 2, projectID: 1, number: 2, kind: .bug, title: "Token no log", location: "Auth.swift:88",
                                  grade: .inCode, priority: .critical, author: .claude, parentID: 1, externalRef: "AB#5", createdAt: now)
        let text = BacklogMarkdown.render(epic, key: "FRI", parent: nil, children: [bug])
        #expect(text.contains("codigo: FRI-1"))
        #expect(text.contains("- FRI-2 · Bug · Novo · crítica · → AB#5 · Token no log"))
        let bugText = BacklogMarkdown.render(bug, key: "FRI", parent: epic, children: [])
        #expect(bugText.contains("pai: FRI-1") && bugText.contains("**Onde:** `Auth.swift:88` (no código)") && bugText.contains("autor: claude"))
        let index = BacklogMarkdown.index([epic, bug], key: "FRI", projectName: "Friday")
        #expect(index.contains("## Bugs abertos · 1") && index.contains("- [[FRI-1]] Épico · A fazer · Login") && index.contains("  - [[FRI-2]] Bug"))
    }
}

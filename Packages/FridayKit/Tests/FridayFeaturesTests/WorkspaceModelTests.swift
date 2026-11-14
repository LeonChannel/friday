// Resumo: Prova que cada projeto mantém as mesmas sessões de terminal ao ir e voltar.
// Tags: terminal, interface, testes

import FridayDomain
import FridayFeatures
import Foundation
import Testing

@MainActor
struct WorkspaceModelTests {
    private let planner = StubPlanner()

    @Test func returnsSameModelForSameProject() throws {
        let workspace = WorkspaceModel(planner: planner)
        let project = Project(id: 1, name: "a", path: "/tmp/a", kind: .folder, addedAt: .distantPast)

        let first = try #require(workspace.terminals(for: project))
        #expect(workspace.terminals(for: project) === first)
        #expect(workspace.visitedProjectIDs == [1])
    }

    @Test func unsavedProjectHasNoTerminals() {
        let workspace = WorkspaceModel(planner: planner)
        #expect(workspace.terminals(for: Project(name: "x", path: "/tmp/x", kind: .folder, addedAt: .distantPast)) == nil)
    }
}

private struct StubPlanner: LaunchPlanning {
    func plan(agent: AgentKind, project: Project, session: AgentSessionID) throws -> LaunchPlan {
        LaunchPlan(executable: "/bin/sh", arguments: [], environment: [:], workingDirectory: project.path)
    }
}

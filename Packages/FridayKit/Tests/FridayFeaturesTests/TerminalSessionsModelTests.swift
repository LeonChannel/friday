// Resumo: Prova o estado das sessões de terminal: abrir, numerar títulos, selecionar, fechar e registrar o fim do processo.
// Tags: terminal, agentes, testes

import FridayDomain
import FridayFeatures
import Foundation
import Testing

@MainActor
struct TerminalSessionsModelTests {
    private struct FakePlanner: LaunchPlanning {
        struct Refusal: LocalizedError { var errorDescription: String? { "recusado" } }
        var fails = false
        func plan(agent: AgentKind, project: Project, session: AgentSessionID) throws -> LaunchPlan {
            if fails { throw Refusal() }
            return LaunchPlan(executable: "/bin/\(agent.rawValue)", arguments: [], environment: [:], workingDirectory: project.path)
        }
    }

    private let project = Project(name: "p", path: "/tmp/p", kind: .folder, addedAt: .distantPast)

    @Test func openSelectsNewSessionRunningInProjectFolder() throws {
        let model = TerminalSessionsModel(project: project, planner: FakePlanner())
        let session = try #require(model.open(agent: .claude))
        #expect(model.selection == session.id)
        #expect(session.state == .running)
        #expect(session.plan.workingDirectory == "/tmp/p")
    }

    @Test func numbersRepeatedTitlesPerAgent() {
        let model = TerminalSessionsModel(project: project, planner: FakePlanner())
        model.open(agent: .shell)
        model.open(agent: .shell)
        model.open(agent: .claude)
        #expect(model.sessions.map(\.title) == ["Terminal", "Terminal 2", "Claude Code"])
    }

    @Test func tabShowsProgramTitleAndFallsBackToAgentName() throws {
        let model = TerminalSessionsModel(project: project, planner: FakePlanner())
        let first = try #require(model.open(agent: .shell))
        let second = try #require(model.open(agent: .shell))
        #expect(model.sessions.map(\.displayTitle) == ["Terminal", "Terminal 2"])

        model.setProgramTitle(id: first.id, title: "  vim notas.md ")
        #expect(model.sessions.map(\.displayTitle) == ["vim notas.md", "Terminal 2"])

        model.setProgramTitle(id: first.id, title: "   ")
        #expect(model.sessions.map(\.displayTitle) == ["Terminal", "Terminal 2"])

        model.setProgramTitle(id: second.id, title: "htop")
        #expect(model.sessions.map(\.title) == ["Terminal", "Terminal 2"])
    }

    @Test func programTitleDoesNotBreakNumberingOfNewTabs() throws {
        let model = TerminalSessionsModel(project: project, planner: FakePlanner())
        let first = try #require(model.open(agent: .claude))
        model.setProgramTitle(id: first.id, title: "Trabalhando no bug")
        let second = try #require(model.open(agent: .claude))
        #expect(second.title == "Claude Code 2")
        #expect(second.displayTitle == "Claude Code 2")
    }

    @Test func markExitedKeepsTabWithCode() throws {
        let model = TerminalSessionsModel(project: project, planner: FakePlanner())
        let session = try #require(model.open(agent: .shell))
        model.markExited(id: session.id, code: 3)
        #expect(model.sessions.first?.state == .exited(code: 3))
    }

    @Test func closingSelectedMovesSelectionToNeighbor() throws {
        let model = TerminalSessionsModel(project: project, planner: FakePlanner())
        let first = try #require(model.open(agent: .shell))
        let second = try #require(model.open(agent: .claude))
        model.close(id: second.id)
        #expect(model.selection == first.id)
        model.close(id: first.id)
        #expect(model.selection == nil)
        #expect(model.sessions.isEmpty)
    }

    @Test func plannerFailureSetsMessageAndOpensNothing() {
        let model = TerminalSessionsModel(project: project, planner: FakePlanner(fails: true))
        #expect(model.open(agent: .codex) == nil)
        #expect(model.sessions.isEmpty)
        #expect(model.openError?.contains("Codex") == true)
        model.dismissOpenError()
        #expect(model.openError == nil)
    }
}

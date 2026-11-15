// Resumo: Prova a receita de cada agente: executável, argumentos, ambiente limpo e pasta do projeto.
// Tags: agentes, terminal, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing

struct DefaultLaunchPlannerTests {
    private let project = Project(name: "p", path: "/tmp/p", kind: .folder, addedAt: .distantPast)
    private let session = AgentSessionID(UUID(uuidString: "11111111-2222-3333-4444-555555555555")!)
    private let planner = DefaultLaunchPlanner(userShell: "/bin/zsh", home: "/Users/x", user: "x", language: "pt_BR.UTF-8")

    @Test func shellOpensInteractiveLoginShellInProjectFolder() throws {
        let plan = try planner.plan(agent: .shell, project: project, session: session)
        #expect(plan.executable == "/bin/zsh")
        #expect(plan.arguments == ["-l", "-i"])
        #expect(plan.workingDirectory == "/tmp/p")
    }

    @Test func claudeGetsSessionIDThroughLoginShell() throws {
        let plan = try planner.plan(agent: .claude, project: project, session: session)
        #expect(plan.arguments == ["-l", "-i", "-c", "exec claude --session-id 11111111-2222-3333-4444-555555555555"])
    }

    @Test func claudeGetsBriefingAsLastQuotedArgument() throws {
        let plan = try planner.plan(agent: .claude, project: project, session: session, initialPrompt: "Assunto 1: it's\nquebrado")
        #expect(plan.arguments.last == "exec claude --session-id 11111111-2222-3333-4444-555555555555 'Assunto 1: it'\\''s\nquebrado'")
    }

    @Test func briefingIsIgnoredForShellAndCodex() throws {
        #expect(try planner.plan(agent: .codex, project: project, session: session, initialPrompt: "x").arguments == ["-l", "-i", "-c", "exec codex"])
        #expect(try planner.plan(agent: .shell, project: project, session: session, initialPrompt: "x").arguments == ["-l", "-i"])
    }

    @Test func codexRunsBareThroughLoginShell() throws {
        let plan = try planner.plan(agent: .codex, project: project, session: session)
        #expect(plan.arguments == ["-l", "-i", "-c", "exec codex"])
    }

    @Test func environmentIsCleanAndCarriesFridayVariables() throws {
        let plan = try planner.plan(agent: .claude, project: project, session: session)
        #expect(plan.environment == [
            "HOME": "/Users/x", "USER": "x", "LOGNAME": "x", "SHELL": "/bin/zsh",
            "TERM": "xterm-256color", "COLORTERM": "truecolor", "LANG": "pt_BR.UTF-8",
            "FRIDAY_SESSION_ID": "11111111-2222-3333-4444-555555555555", "FRIDAY_AGENT": "claude",
        ])
    }

    @Test func relativeShellFallsBackToZsh() throws {
        let odd = DefaultLaunchPlanner(userShell: "zsh", home: "/h", user: "u", language: "en_US.UTF-8")
        #expect(try odd.plan(agent: .shell, project: project, session: session).executable == "/bin/zsh")
    }
}

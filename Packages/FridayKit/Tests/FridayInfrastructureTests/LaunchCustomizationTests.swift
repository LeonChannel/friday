// Resumo: Prova que os acréscimos por sessão chegam ao agente intactos, mesmo com espaço e aspas no caminho.
// Tags: agentes, terminal, testes

import FridayDomain
@testable import FridayInfrastructure
import Foundation
import Testing

struct LaunchCustomizationTests {
    private let project = Project(name: "p", path: "/tmp/p", kind: .folder, addedAt: .distantPast)
    private let session = AgentSessionID(UUID(uuidString: "11111111-2222-3333-4444-555555555555")!)

    @Test func claudeReceivesQuotedExtraArgumentsAndEnvironment() throws {
        let planner = DefaultLaunchPlanner(userShell: "/bin/zsh", home: "/h", user: "u", language: "en_US.UTF-8", customizer: FixedCustomizer())
        let plan = try planner.plan(agent: .claude, project: project, session: session)

        #expect(plan.arguments.last == "exec claude --session-id 11111111-2222-3333-4444-555555555555 --settings '/tmp/App Support/it'\\''s.json'")
        #expect(plan.environment["FRIDAY_HOOK_SOCKET"] == "/tmp/s.sock")
    }

    @Test func shellIsNeverCustomized() throws {
        let planner = DefaultLaunchPlanner(userShell: "/bin/zsh", home: "/h", user: "u", language: "en_US.UTF-8", customizer: FixedCustomizer())
        #expect(try planner.plan(agent: .shell, project: project, session: session).arguments == ["-l", "-i"])
    }

    @Test(arguments: ["simples", "com espaço", "it's", "$HOME", "a;b", "`x`", ""])
    func quotingSurvivesARealShell(word: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-f", "-c", "printf '%s' " + DefaultLaunchPlanner.shellQuoted(word)]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        #expect(String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self) == word)
    }
}

private struct FixedCustomizer: AgentLaunchCustomizing {
    func extraArguments(agent: AgentKind, session: AgentSessionID) throws -> [String] {
        agent == .claude ? ["--settings", "/tmp/App Support/it's.json"] : []
    }

    func extraEnvironment(agent: AgentKind, session: AgentSessionID) throws -> [String: String] {
        agent == .shell ? [:] : ["FRIDAY_HOOK_SOCKET": "/tmp/s.sock"]
    }
}

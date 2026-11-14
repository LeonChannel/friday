// Resumo: Prova que toda sessão recebe o friday no PATH e que só o Claude recebe o plugin, passando por um shell real.
// Tags: agentes, terminal, testes

import FridayDomain
@testable import FridayInfrastructure
import Foundation
import Testing

struct FridayToolsCustomizerTests {
    private let session = AgentSessionID()

    @Test func onlyClaudeGetsThePlugin() throws {
        let tools = FridayToolsCustomizer(binDirectory: "/app/bin", pluginDirectory: "/app/claude plugin")
        #expect(try tools.extraArguments(agent: .claude, session: session) == ["--plugin-dir", "/app/claude plugin"])
        #expect(try tools.extraArguments(agent: .codex, session: session).isEmpty)
        #expect(try tools.extraArguments(agent: .shell, session: session).isEmpty)
        for agent in AgentKind.allCases {
            #expect(try tools.extraEnvironment(agent: agent, session: session) == ["PATH": "/app/bin"])
        }
    }

    @Test func withoutPluginClaudeGetsNoArguments() throws {
        let tools = FridayToolsCustomizer(binDirectory: "/app/bin", pluginDirectory: nil)
        #expect(try tools.extraArguments(agent: .claude, session: session).isEmpty)
    }

    @Test(.tags(.integration)) func loginShellKeepsFridayOnPath() throws {
        let bin = FileManager.default.temporaryDirectory.appendingPathComponent("friday-bin-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: bin) }
        let tool = bin.appendingPathComponent("friday")
        try Data("#!/bin/sh\necho friday-ok\n".utf8).write(to: tool)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tool.path)

        let project = Project(name: "p", path: NSTemporaryDirectory(), kind: .folder, addedAt: .distantPast)
        let planner = DefaultLaunchPlanner(userShell: "/bin/zsh", customizer: FridayToolsCustomizer(binDirectory: bin.path, pluginDirectory: nil))
        let plan = try planner.plan(agent: .shell, project: project, session: session)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: plan.executable)
        // Mesmo shell de login do plano, rodando só o `friday` (sem `-i` para não depender de TTY).
        process.arguments = ["-l", "-c", "friday"]
        process.environment = plan.environment
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        #expect(String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self).contains("friday-ok"))
    }
}

// Resumo: Prova que o Codex só ganha hooks do Friday com a preferência ligada, e que os argumentos chegam intactos ao shell.
// Tags: testes, sensor, agentes, configuracoes

import FridayDomain
import Foundation
import Testing
@testable import FridayInfrastructure

@Suite("CodexSessionHooks")
struct CodexSessionHooksTests {
    private let project = Project(name: "p", path: "/p", kind: .folder, addedAt: .distantPast)

    @Test func disabledPreferenceAddsNothingAndWritesNothing() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let hooks = CodexSessionHooks(locations: SensorLocations(root: dir.url), isEnabled: { false })
        #expect(try hooks.extraArguments(agent: .codex, session: AgentSessionID()).isEmpty)
        #expect(try hooks.extraEnvironment(agent: .codex, session: AgentSessionID()).isEmpty)
        #expect(!FileManager.default.fileExists(atPath: dir.url.appendingPathComponent("hooks").path))
    }

    @Test func enabledPreferenceHooksEveryEventAndBypassesTrust() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let locations = SensorLocations(root: dir.url)
        let hooks = CodexSessionHooks(locations: locations, isEnabled: { true })
        let arguments = try hooks.extraArguments(agent: .codex, session: AgentSessionID())

        let script = locations.hooksDirectory.appendingPathComponent(HookScript.fileName).path
        let configs = stride(from: 0, to: CodexSessionHooks.hookEvents.count * 2, by: 2).map { arguments[$0 + 1] }
        #expect(stride(from: 0, to: CodexSessionHooks.hookEvents.count * 2, by: 2).allSatisfy { arguments[$0] == "-c" })
        #expect(configs.count == CodexSessionHooks.hookEvents.count)
        for (event, config) in zip(CodexSessionHooks.hookEvents, configs) {
            #expect(config == "hooks.\(event)=[{hooks=[{type=\"command\",command=\"'\(script)' codex\",timeout=5}]}]")
        }
        #expect(arguments.last == "--dangerously-bypass-hook-trust")
        #expect(try hooks.extraEnvironment(agent: .codex, session: AgentSessionID()) == ["FRIDAY_HOOK_SOCKET": locations.socketPath])
        #expect(FileManager.default.isExecutableFile(atPath: script))
    }

    @Test func preferenceIsReadOnEverySession() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let flag = LockedFlag()
        let hooks = CodexSessionHooks(locations: SensorLocations(root: dir.url), isEnabled: { flag.value })
        #expect(try hooks.extraArguments(agent: .codex, session: AgentSessionID()).isEmpty)
        flag.value = true
        #expect(!(try hooks.extraArguments(agent: .codex, session: AgentSessionID()).isEmpty))
    }

    @Test(arguments: [AgentKind.shell, .claude])
    func otherAgentsGetNothingEvenWhenEnabled(agent: AgentKind) throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let hooks = CodexSessionHooks(locations: SensorLocations(root: dir.url), isEnabled: { true })
        #expect(try hooks.extraArguments(agent: agent, session: AgentSessionID()).isEmpty)
        #expect(try hooks.extraEnvironment(agent: agent, session: AgentSessionID()).isEmpty)
    }

    @Test func tomlStringEscapesBackslashAndQuote() {
        #expect(CodexSessionHooks.tomlString(#"a\b"c"#) == #""a\\b\"c""#)
    }

    @Test func plannedCodexCommandReachesTheShellIntact() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let locations = SensorLocations(root: dir.url.appendingPathComponent("Application Support", isDirectory: true))
        let customizer = CompositeLaunchCustomizer([
            ClaudeSessionHooks(locations: locations, home: dir.url.path),
            CodexSessionHooks(locations: locations, isEnabled: { true }),
        ])
        let planner = DefaultLaunchPlanner(userShell: "/bin/zsh", home: "/h", user: "u", language: "en_US.UTF-8", customizer: customizer)
        let plan = try planner.plan(agent: .codex, project: project, session: AgentSessionID())

        let command = try #require(plan.arguments.last).replacingOccurrences(of: "exec codex", with: "printf '%s\\n'")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-f", "-c", command]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        let words = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self).split(separator: "\n").map(String.init)

        let script = locations.hooksDirectory.appendingPathComponent(HookScript.fileName).path
        #expect(words.count == CodexSessionHooks.hookEvents.count * 2 + 1)
        #expect(words.first == "-c")
        #expect(words[1].contains("command=\"'\(script)' codex\""))
        #expect(words.last == "--dangerously-bypass-hook-trust")
        #expect(plan.environment["FRIDAY_HOOK_SOCKET"] == locations.socketPath)
    }

    @Test func compositeMergesArgumentsAndEnvironmentInOrder() throws {
        struct Fixed: AgentLaunchCustomizing {
            var arguments: [String]
            var environment: [String: String]
            func extraArguments(agent: AgentKind, session: AgentSessionID) throws -> [String] { arguments }
            func extraEnvironment(agent: AgentKind, session: AgentSessionID) throws -> [String: String] { environment }
        }
        let composite = CompositeLaunchCustomizer([
            Fixed(arguments: ["a"], environment: ["K": "1", "X": "x"]),
            Fixed(arguments: ["b"], environment: ["K": "2"]),
        ])
        #expect(try composite.extraArguments(agent: .codex, session: AgentSessionID()) == ["a", "b"])
        #expect(try composite.extraEnvironment(agent: .codex, session: AgentSessionID()) == ["K": "2", "X": "x"])
    }
}

private final class LockedFlag: @unchecked Sendable {
    // SAFETY: todo acesso passa pelo lock.
    private let lock = NSLock()
    private var stored = false
    var value: Bool {
        get { lock.withLock { stored } }
        set { lock.withLock { stored = newValue } }
    }
}

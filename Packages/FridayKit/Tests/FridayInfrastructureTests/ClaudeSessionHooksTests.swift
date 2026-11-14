// Resumo: Prova que o Claude recebe --settings e o socket, que o comando final passa pelo shell intacto e que o settings cobre todos os hooks.
// Tags: testes, sensor, agentes

import FridayDomain
import Foundation
import Testing
@testable import FridayInfrastructure

@Suite("ClaudeSessionHooks")
struct ClaudeSessionHooksTests {
    private let project = Project(name: "p", path: "/p", kind: .folder, addedAt: .distantPast)

    @Test func claudeGetsSettingsAndSocketOthersGetNothing() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let locations = SensorLocations(root: dir.url)
        let hooks = ClaudeSessionHooks(locations: locations)
        let session = AgentSessionID()

        let settingsPath = locations.sessionsDirectory.appendingPathComponent("\(session).settings.json").path
        #expect(try hooks.extraArguments(agent: .claude, session: session) == ["--settings", settingsPath])
        #expect(try hooks.extraEnvironment(agent: .claude, session: session) == ["FRIDAY_SOCKET": locations.socketPath])
        #expect(try hooks.extraArguments(agent: .codex, session: session).isEmpty)
        #expect(try hooks.extraEnvironment(agent: .shell, session: session).isEmpty)
    }

    @Test func plannedClaudeCommandReachesTheShellIntact() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let locations = SensorLocations(root: dir.url.appendingPathComponent("Application Support", isDirectory: true))
        let session = AgentSessionID()
        let planner = DefaultLaunchPlanner(userShell: "/bin/zsh", home: "/h", user: "u", language: "en_US.UTF-8", customizer: ClaudeSessionHooks(locations: locations))
        let plan = try planner.plan(agent: .claude, project: project, session: session)

        // Troca `exec claude` por um printf que mostra como o shell separou os argumentos.
        let command = try #require(plan.arguments.last).replacingOccurrences(of: "exec claude", with: "printf '%s\\n'")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-f", "-c", command]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        let words = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self).split(separator: "\n").map(String.init)

        let settingsPath = locations.sessionsDirectory.appendingPathComponent("\(session).settings.json").path
        #expect(words == ["--session-id", session.description, "--settings", settingsPath])
        #expect(plan.environment["FRIDAY_SOCKET"] == locations.socketPath)
        #expect(plan.environment["FRIDAY_SESSION_ID"] == session.description)
        #expect(FileManager.default.fileExists(atPath: settingsPath))
    }

    @Test func settingsFileHooksEveryEventToTheScript() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let locations = SensorLocations(root: dir.url)
        let session = AgentSessionID()
        let arguments = try ClaudeSessionHooks(locations: locations).extraArguments(agent: .claude, session: session)

        let data = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
        let root = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let hooks = try #require(root["hooks"] as? [String: Any])
        #expect(Set(hooks.keys) == Set(ClaudeSessionHooks.hookEvents))
        let script = locations.hooksDirectory.appendingPathComponent(HookScript.fileName).path
        for (_, value) in hooks {
            let groups = try #require(value as? [[String: Any]])
            let commands = try #require(groups.first?["hooks"] as? [[String: Any]])
            #expect(commands.first?["command"] as? String == "'\(script)' claude")
        }
        #expect(FileManager.default.isExecutableFile(atPath: script))
    }

    @Test func quotesScriptPathsWithSpacesAndQuotes() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let odd = dir.url.appendingPathComponent("Application Support/it's", isDirectory: true)
        let locations = SensorLocations(root: odd)
        let data = try ClaudeSessionHooks(locations: locations).settingsData(script: odd.appendingPathComponent("s.sh"))
        let text = String(decoding: data, as: UTF8.self)
        #expect(text.contains("it'\\\\''s"))
    }

    @Test func eachSessionGetsItsOwnSettingsFile() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let hooks = ClaudeSessionHooks(locations: SensorLocations(root: dir.url))
        let a = try hooks.extraArguments(agent: .claude, session: AgentSessionID())
        let b = try hooks.extraArguments(agent: .claude, session: AgentSessionID())
        #expect(a[1] != b[1])
    }
}

// Resumo: Testa que o plano do Claude ganha --settings e as variáveis do Friday, e que o settings gerado cobre os hooks sem tocar na config global.
// Tags: testes, sensor, agentes

import FridayDomain
import Foundation
import Testing
@testable import FridayInfrastructure

@Suite("ClaudeSessionHooks")
struct ClaudeSessionHooksTests {
    @Test func claudeGetsSettingsFlagAndSocketVariable() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let locations = SensorLocations(root: dir.url)
        let session = AgentSessionID()
        let hooks = ClaudeSessionHooks(locations: locations)

        let settingsPath = locations.sessionsDirectory.appendingPathComponent("\(session).settings.json").path
        #expect(try hooks.extraArguments(agent: .claude, session: session) == ["--settings", settingsPath])
        #expect(try hooks.extraEnvironment(agent: .claude, session: session) == ["FRIDAY_HOOK_SOCKET": locations.socketPath])
    }

    @Test func otherAgentsGetNothing() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let hooks = ClaudeSessionHooks(locations: SensorLocations(root: dir.url))
        for agent in [AgentKind.shell, .codex] {
            #expect(try hooks.extraArguments(agent: agent, session: AgentSessionID()).isEmpty)
            #expect(try hooks.extraEnvironment(agent: agent, session: AgentSessionID()).isEmpty)
        }
        #expect(!FileManager.default.fileExists(atPath: dir.url.appendingPathComponent("sessions").path))
    }

    @Test func settingsFileHooksEveryEventToTheScript() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let locations = SensorLocations(root: dir.url)
        let arguments = try ClaudeSessionHooks(locations: locations).extraArguments(agent: .claude, session: AgentSessionID())

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

    @Test func removesOldSettingsButKeepsRecentOnes() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let locations = SensorLocations(root: dir.url)
        let hooks = ClaudeSessionHooks(locations: locations)
        let old = try hooks.extraArguments(agent: .claude, session: AgentSessionID())[1]
        let recent = try hooks.extraArguments(agent: .claude, session: AgentSessionID())[1]
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -8 * 24 * 3600)], ofItemAtPath: old)

        _ = try hooks.extraArguments(agent: .claude, session: AgentSessionID())
        #expect(!FileManager.default.fileExists(atPath: old))
        #expect(FileManager.default.fileExists(atPath: recent))
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

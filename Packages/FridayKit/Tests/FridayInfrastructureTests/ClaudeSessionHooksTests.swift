// Resumo: Testa que o plano do Claude ganha --settings e as variáveis do Friday, e que o settings gerado cobre os hooks sem tocar na config global.
// Tags: testes, sensor, agentes

import FridayDomain
import Foundation
import Testing
@testable import FridayInfrastructure

@Suite("ClaudeSessionHooks")
struct ClaudeSessionHooksTests {
    private func makePlan() -> LaunchPlan {
        LaunchPlan(executable: "/usr/local/bin/claude", arguments: ["--session-id", "x"], environment: ["HOME": "/h"], workingDirectory: "/p")
    }

    @Test func addsSettingsFlagAndEnvironment() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let locations = SensorLocations(root: dir.url)
        let session = AgentSessionID()
        let plan = try ClaudeSessionHooks(locations: locations).apply(to: makePlan(), session: session)

        let settingsPath = locations.sessionsDirectory.appendingPathComponent("\(session).settings.json").path
        #expect(plan.arguments == ["--settings", settingsPath, "--session-id", "x"])
        #expect(plan.environment["FRIDAY_SESSION_ID"] == session.description)
        #expect(plan.environment["FRIDAY_SOCKET"] == locations.socketPath)
        #expect(plan.environment["HOME"] == "/h")
        #expect(plan.executable == "/usr/local/bin/claude")
        #expect(plan.workingDirectory == "/p")
    }

    @Test func settingsFileHooksEveryEventToTheScript() throws {
        let dir = try ShortTemporaryDirectory()
        defer { dir.remove() }
        let locations = SensorLocations(root: dir.url)
        let session = AgentSessionID()
        let plan = try ClaudeSessionHooks(locations: locations).apply(to: makePlan(), session: session)

        let data = try Data(contentsOf: URL(fileURLWithPath: plan.arguments[1]))
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
        let a = try hooks.apply(to: makePlan(), session: AgentSessionID())
        let b = try hooks.apply(to: makePlan(), session: AgentSessionID())
        #expect(a.arguments[1] != b.arguments[1])
    }
}

// Resumo: Prepara uma sessão do Claude Code para reportar hooks ao Friday: grava o settings da sessão e entrega o --settings e o socket ao planner.
// Tags: sensor, agentes

import FridayDomain
import Foundation

/// Liga os hooks do Friday a uma sessão do Claude, sem tocar em `~/.claude`.
/// Os hooks de `--settings` somam aos do usuário e do projeto; não os substituem (verificado com `claude -p`).
public struct ClaudeSessionHooks: AgentLaunchCustomizing {
    /// Eventos que o Friday acompanha.
    static let hookEvents = [
        "SessionStart", "UserPromptSubmit", "PreToolUse", "PostToolUse", "Notification",
        "Stop", "SubagentStop", "SessionEnd", "PreCompact",
    ]

    private let locations: SensorLocations

    public init(locations: SensorLocations) {
        self.locations = locations
    }

    /// Para o Claude: instala o script, grava o settings da sessão e devolve `--settings <arquivo>`.
    public func extraArguments(agent: AgentKind, session: AgentSessionID) throws -> [String] {
        guard agent == .claude else { return [] }
        let script = try HookScript.install(in: locations.hooksDirectory)
        return ["--settings", try writeSettings(session: session, script: script).path]
    }

    /// Caminho do socket para o script de hook. `FRIDAY_SESSION_ID` já vem do planner.
    public func extraEnvironment(agent: AgentKind, session: AgentSessionID) throws -> [String: String] {
        agent == .claude ? ["FRIDAY_SOCKET": locations.socketPath] : [:]
    }

    /// Conteúdo do settings da sessão: um hook de comando por evento, todos chamando o mesmo script.
    func settingsData(script: URL) throws -> Data {
        let command = "\(Self.shellQuoted(script.path)) claude"
        let entry: [String: Any] = ["hooks": [["type": "command", "command": command, "timeout": 5]]]
        let hooks = Dictionary(uniqueKeysWithValues: Self.hookEvents.map { ($0, [entry]) })
        return try JSONSerialization.data(withJSONObject: ["hooks": hooks], options: [.prettyPrinted, .sortedKeys])
    }

    private func writeSettings(session: AgentSessionID, script: URL) throws -> URL {
        try FileManager.default.createDirectory(
            at: locations.sessionsDirectory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700]
        )
        let url = locations.sessionsDirectory.appendingPathComponent("\(session).settings.json")
        try settingsData(script: script).write(to: url, options: .atomic)
        return url
    }

    private static func shellQuoted(_ text: String) -> String {
        "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

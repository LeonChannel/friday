// Resumo: Prepara uma sessão do Claude Code para reportar hooks ao Friday: settings próprio da sessão, variáveis de ambiente e o flag --settings.
// Tags: sensor, agentes

import FridayDomain
import Foundation

/// Acrescenta a um `LaunchPlan` do Claude os hooks do Friday, sem tocar em `~/.claude`.
/// Os hooks de `--settings` somam aos do usuário e do projeto; não os substituem.
public struct ClaudeSessionHooks: Sendable {
    /// Eventos que o Friday acompanha.
    static let hookEvents = [
        "SessionStart", "UserPromptSubmit", "PreToolUse", "PostToolUse", "Notification",
        "Stop", "SubagentStop", "SessionEnd", "PreCompact",
    ]

    private let locations: SensorLocations

    public init(locations: SensorLocations) {
        self.locations = locations
    }

    /// Devolve o plano com `--settings <arquivo da sessão>` e as variáveis `FRIDAY_SESSION_ID` e `FRIDAY_SOCKET`.
    /// Quem monta o plano continua responsável por passar `--session-id` com o mesmo valor de `session`.
    public func apply(to plan: LaunchPlan, session: AgentSessionID) throws -> LaunchPlan {
        let script = try HookScript.install(in: locations.hooksDirectory)
        let settings = try writeSettings(session: session, script: script)
        var result = plan
        result.arguments = ["--settings", settings.path] + plan.arguments
        result.environment["FRIDAY_SESSION_ID"] = session.description
        result.environment["FRIDAY_SOCKET"] = locations.socketPath
        return result
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

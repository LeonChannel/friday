// Resumo: Prepara uma sessão do Claude Code para reportar hooks ao Friday: settings próprio da sessão, variáveis de ambiente e o flag --settings.
// Tags: sensor, agentes

import FridayDomain
import Foundation

/// Dá ao planner os acréscimos do Claude (`--settings` e ambiente) para reportar hooks ao Friday, sem tocar em `~/.claude`.
/// Os hooks de `--settings` somam aos do usuário e do projeto; não os substituem.
public struct ClaudeSessionHooks: AgentLaunchCustomizing {
    /// Settings de sessões com mais de 7 dias são apagados.
    static let settingsMaxAge: TimeInterval = 7 * 24 * 3600

    /// Eventos que o Friday acompanha.
    static let hookEvents = [
        "SessionStart", "UserPromptSubmit", "PreToolUse", "PostToolUse", "Notification",
        "Stop", "SubagentStop", "SessionEnd", "PreCompact",
    ]

    private let locations: SensorLocations

    public init(locations: SensorLocations) {
        self.locations = locations
    }

    /// `["--settings", <arquivo da sessão>]` só para o Claude; grava o script e o settings e apaga settings antigos.
    public func extraArguments(agent: AgentKind, session: AgentSessionID) throws -> [String] {
        guard agent == .claude else { return [] }
        let script = try HookScript.install(in: locations.hooksDirectory)
        let settings = try writeSettings(session: session, script: script)
        removeStaleSettings(keeping: settings)
        return ["--settings", settings.path]
    }

    /// `FRIDAY_HOOK_SOCKET` para o script de hook achar o socket. `FRIDAY_SESSION_ID` já vem do planner.
    public func extraEnvironment(agent: AgentKind, session: AgentSessionID) throws -> [String: String] {
        agent == .claude ? ["FRIDAY_HOOK_SOCKET": locations.socketPath] : [:]
    }

    private func removeStaleSettings(keeping current: URL) {
        let fm = FileManager.default
        let limit = Date(timeIntervalSinceNow: -Self.settingsMaxAge)
        let files = (try? fm.contentsOfDirectory(at: locations.sessionsDirectory, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        for file in files where file != current && file.lastPathComponent.hasSuffix(".settings.json") {
            let modified = (try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantFuture
            if modified < limit { try? fm.removeItem(at: file) }
        }
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

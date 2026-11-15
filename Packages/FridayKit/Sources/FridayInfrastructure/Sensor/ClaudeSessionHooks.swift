// Resumo: Prepara uma sessão do Claude Code para reportar hooks e cota ao Friday: settings próprio da sessão (hooks e statusline), variáveis de ambiente e o flag --settings.
// Tags: sensor, agentes, cota

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
    private let home: String

    /// `home` é onde a statusline do usuário é procurada (só leitura); o padrão é a pasta do usuário.
    public init(locations: SensorLocations, home: String = NSHomeDirectory()) {
        self.locations = locations
        self.home = home
    }

    /// `["--settings", <arquivo da sessão>]` só para o Claude; grava o script e o settings e apaga settings antigos.
    public func extraArguments(agent: AgentKind, session: AgentSessionID) throws -> [String] {
        guard agent == .claude else { return [] }
        let script = try HookScript.install(in: locations.hooksDirectory)
        let statusline = try StatuslineScript.install(in: locations.hooksDirectory)
        let settings = try writeSettings(session: session, script: script, statusline: statusline)
        removeStaleSettings(keeping: settings)
        return ["--settings", settings.path]
    }

    /// `FRIDAY_HOOK_SOCKET` para os scripts acharem o socket e `FRIDAY_STATUSLINE_NEXT` com a statusline do usuário,
    /// que a do Friday roda em seguida (a da sessão substitui a do usuário; sem isso ela sumiria). `FRIDAY_SESSION_ID` já vem do planner.
    public func extraEnvironment(agent: AgentKind, session: AgentSessionID) throws -> [String: String] {
        guard agent == .claude else { return [:] }
        var environment = ["FRIDAY_HOOK_SOCKET": locations.socketPath]
        if let next = StatuslineScript.userCommand(home: home) { environment["FRIDAY_STATUSLINE_NEXT"] = next }
        return environment
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

    /// Conteúdo do settings da sessão: um hook de comando por evento, todos chamando o mesmo script, e a statusline do Friday.
    func settingsData(script: URL, statusline: URL? = nil) throws -> Data {
        let command = HookScript.commandLine(script: script, agent: "claude")
        let entry: [String: Any] = ["hooks": [["type": "command", "command": command, "timeout": 5]]]
        let hooks = Dictionary(uniqueKeysWithValues: Self.hookEvents.map { ($0, [entry]) })
        var settings: [String: Any] = ["hooks": hooks]
        if let statusline {
            settings["statusLine"] = ["type": "command", "command": "'" + statusline.path.replacingOccurrences(of: "'", with: "'\\''") + "'"]
        }
        return try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted, .sortedKeys])
    }

    private func writeSettings(session: AgentSessionID, script: URL, statusline: URL) throws -> URL {
        try FileManager.default.createDirectory(
            at: locations.sessionsDirectory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700]
        )
        let url = locations.sessionsDirectory.appendingPathComponent("\(session).settings.json")
        try settingsData(script: script, statusline: statusline).write(to: url, options: .atomic)
        return url
    }
}

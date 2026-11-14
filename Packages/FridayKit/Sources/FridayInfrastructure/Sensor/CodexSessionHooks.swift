// Resumo: Liga os hooks do Friday numa sessão do Codex, só quando o dev ativou a linha do tempo do Codex, sem tocar em ~/.codex.
// Tags: sensor, agentes, configuracoes

import FridayDomain
import Foundation

/// Dá ao planner os acréscimos do Codex: hooks por `-c` apontando para o script do Friday e o socket no ambiente.
/// Exige `--dangerously-bypass-hook-trust` (o Codex não confia em hooks de `-c` sozinho), o que também libera
/// hooks do usuário ainda não aprovados; por isso só age com a preferência ligada.
public struct CodexSessionHooks: AgentLaunchCustomizing {
    /// Eventos do Codex que o Friday acompanha (`SubagentStart` fica de fora: o fim do subagente basta).
    static let hookEvents = [
        "SessionStart", "UserPromptSubmit", "PreToolUse", "PermissionRequest", "PostToolUse", "SubagentStop", "Stop",
    ]

    private let locations: SensorLocations
    private let isEnabled: @Sendable () -> Bool

    /// `isEnabled` é lido a cada sessão aberta, então ligar ou desligar vale para a próxima sessão.
    public init(locations: SensorLocations, isEnabled: @escaping @Sendable () -> Bool) {
        self.locations = locations
        self.isEnabled = isEnabled
    }

    /// `-c hooks.<Evento>=...` por evento e `--dangerously-bypass-hook-trust`; vazio para outro agente ou com a preferência desligada.
    public func extraArguments(agent: AgentKind, session: AgentSessionID) throws -> [String] {
        guard agent == .codex, isEnabled() else { return [] }
        let script = try HookScript.install(in: locations.hooksDirectory)
        let command = Self.tomlString(HookScript.commandLine(script: script, agent: "codex"))
        let hooks = Self.hookEvents.flatMap { ["-c", "hooks.\($0)=[{hooks=[{type=\"command\",command=\(command),timeout=5}]}]"] }
        return hooks + ["--dangerously-bypass-hook-trust"]
    }

    /// `FRIDAY_HOOK_SOCKET` só quando a preferência está ligada; sem ele o script de hook não envia nada.
    public func extraEnvironment(agent: AgentKind, session: AgentSessionID) throws -> [String: String] {
        agent == .codex && isEnabled() ? ["FRIDAY_HOOK_SOCKET": locations.socketPath] : [:]
    }

    /// Literal de string TOML entre aspas duplas.
    static func tomlString(_ text: String) -> String {
        "\"" + text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }
}

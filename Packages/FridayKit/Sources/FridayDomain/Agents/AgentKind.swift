// Resumo: Quais programas o Friday sabe abrir num terminal: shell comum, Claude Code e Codex.
// Tags: agentes, terminal

/// Programa que uma sessão de terminal roda.
public enum AgentKind: String, Codable, Sendable, CaseIterable {
    case shell
    case claude
    case codex

    /// Nome que aparece na interface.
    public var displayName: String {
        switch self {
        case .shell: "Terminal"
        case .claude: "Claude Code"
        case .codex: "Codex"
        }
    }
}

// Resumo: Um acontecimento numa sessão de agente (prompt enviado, ferramenta usada, fim de turno...) já separado do JSON bruto do hook.
// Tags: sensor, agentes

import Foundation

/// Tipo de acontecimento que um hook do agente reporta. Nome novo que o Friday não conhece vira `.unknown`, nunca é descartado.
public enum AgentEventKind: Hashable, Sendable {
    case sessionStart
    case userPromptSubmit
    case preToolUse
    case postToolUse
    case notification
    /// Pedido de permissão do Codex (`PermissionRequest`): o agente espera o dev decidir.
    case permissionRequest
    case stop
    case subagentStop
    case sessionEnd
    case preCompact
    /// Evento que esta versão do Friday não reconhece; guarda o nome como veio.
    case unknown(String)

    /// Converte o `hook_event_name` do Claude Code ou do Codex (os dois usam os mesmos nomes).
    public init(hookName: String) {
        switch hookName {
        case "SessionStart": self = .sessionStart
        case "UserPromptSubmit": self = .userPromptSubmit
        case "PreToolUse": self = .preToolUse
        case "PostToolUse": self = .postToolUse
        case "Notification": self = .notification
        case "PermissionRequest": self = .permissionRequest
        case "Stop": self = .stop
        case "SubagentStop": self = .subagentStop
        case "SessionEnd": self = .sessionEnd
        case "PreCompact": self = .preCompact
        default: self = .unknown(hookName)
        }
    }

    /// Nome do evento como o agente o escreve; é o que vai para o banco.
    public var hookName: String {
        switch self {
        case .sessionStart: "SessionStart"
        case .userPromptSubmit: "UserPromptSubmit"
        case .preToolUse: "PreToolUse"
        case .postToolUse: "PostToolUse"
        case .notification: "Notification"
        case .permissionRequest: "PermissionRequest"
        case .stop: "Stop"
        case .subagentStop: "SubagentStop"
        case .sessionEnd: "SessionEnd"
        case .preCompact: "PreCompact"
        case .unknown(let name): name
        }
    }
}

/// Um evento de hook de uma sessão, guardado com o JSON original para nada se perder.
public struct AgentEvent: Equatable, Sendable, Identifiable {
    /// `nil` até gravar no banco.
    public var id: Int64?
    public var sessionID: AgentSessionID
    public var agent: AgentKind
    public var kind: AgentEventKind
    /// Momento em que o Friday recebeu o evento (o payload do hook não traz horário).
    public var occurredAt: Date
    /// Ferramenta envolvida (`Bash`, `Edit`...), quando o evento é de ferramenta; no `SubagentStop`, o tipo do subagente.
    public var toolName: String?
    /// Arquivo ou comando que a ferramenta usou, quando houver; no `SubagentStop`, a descrição do subagente.
    public var target: String?
    /// Payload completo como o agente enviou.
    public var rawJSON: String

    public init(
        id: Int64? = nil,
        sessionID: AgentSessionID,
        agent: AgentKind,
        kind: AgentEventKind,
        occurredAt: Date,
        toolName: String? = nil,
        target: String? = nil,
        rawJSON: String
    ) {
        self.id = id
        self.sessionID = sessionID
        self.agent = agent
        self.kind = kind
        self.occurredAt = occurredAt
        self.toolName = toolName
        self.target = target
        self.rawJSON = rawJSON
    }
}

// Resumo: Resume uma sessão a partir dos eventos gravados (fase atual, arquivos alterados, ferramentas usadas) sem pedir nada à IA.
// Tags: linha-do-tempo, agentes

import Foundation

/// Em que pé a sessão está, deduzido só dos eventos.
public enum SessionPhase: Equatable, Sendable {
    /// Nenhum evento chegou ainda.
    case starting
    /// O agente está processando um pedido.
    case working
    /// O agente parou e espera o dev (fim de turno, pedido de permissão ou aviso).
    case waitingForYou
    /// A sessão terminou.
    case finished
}

/// Projeção de uma sessão: o que a interface mostra como status e resumo.
public struct SessionActivity: Equatable, Sendable {
    public var phase: SessionPhase
    /// Arquivos que o agente escreveu ou editou, na ordem da primeira alteração.
    public var changedFiles: [String]
    /// Quantas ferramentas o agente usou com sucesso.
    public var toolUses: Int
    /// Quantos pedidos o dev enviou.
    public var prompts: Int
    public var lastEventAt: Date?

    /// Ferramentas do Claude que alteram arquivo; o alvo delas é o caminho.
    public static let fileWritingTools: Set<String> = ["Edit", "Write", "MultiEdit", "NotebookEdit"]

    /// Monta a projeção a partir dos eventos, em qualquer ordem.
    public init(events: [AgentEvent]) {
        let ordered = events.sorted { ($0.occurredAt, $0.id ?? 0) < ($1.occurredAt, $1.id ?? 0) }
        var phase = SessionPhase.starting
        var changedFiles: [String] = []
        var toolUses = 0
        var prompts = 0
        for event in ordered {
            switch event.kind {
            case .sessionStart, .stop, .notification, .permissionRequest:
                phase = .waitingForYou
            case .userPromptSubmit:
                phase = .working
                prompts += 1
            case .preToolUse, .subagentStop, .preCompact:
                phase = .working
            case .postToolUse:
                phase = .working
                toolUses += 1
                if let tool = event.toolName, Self.fileWritingTools.contains(tool), let path = event.target, !changedFiles.contains(path) {
                    changedFiles.append(path)
                }
            case .sessionEnd:
                phase = .finished
            case .unknown:
                break
            }
        }
        self.phase = phase
        self.changedFiles = changedFiles
        self.toolUses = toolUses
        self.prompts = prompts
        self.lastEventAt = ordered.last?.occurredAt
    }
}

// Resumo: Agrupa eventos consecutivos iguais de subagente numa só linha da linha do tempo, com contagem e identificação de cada um.
// Tags: linha-do-tempo, agentes

import Foundation

/// Uma linha da linha do tempo: um evento sozinho ou vários `SubagentStop` seguidos.
public struct TimelineEntry: Equatable, Sendable, Identifiable {
    /// Eventos da linha, do mais antigo ao mais novo; nunca vazio.
    public let events: [AgentEvent]
    public let id: Int64

    init(events: [AgentEvent], position: Int) {
        self.events = events
        self.id = events[0].id ?? Int64(-(position + 1))
    }

    /// Quantos eventos a linha reúne.
    public var count: Int { events.count }
    /// Primeiro evento; é o que define o tipo da linha.
    public var first: AgentEvent { events[0] }
    /// Último evento; é o que dá a hora da linha.
    public var last: AgentEvent { events[events.count - 1] }
    /// Verdadeiro para a linha de subagentes que terminaram.
    public var isSubagentGroup: Bool { first.kind == .subagentStop }

    /// Tipos de subagente na linha, sem repetir, na ordem em que apareceram.
    public var subagentTypes: [String] { Self.unique(events.compactMap(\.toolName)) }
    /// Descrições dos subagentes na linha, sem repetir, na ordem em que apareceram.
    public var subagentDescriptions: [String] { Self.unique(events.compactMap(\.target)) }

    private static func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}

/// Projeção pura dos eventos de uma sessão em linhas da linha do tempo.
public enum TimelineProjection {
    /// Ordena por horário e junta `SubagentStop` consecutivos; qualquer outro evento entre eles quebra o grupo.
    public static func entries(from events: [AgentEvent]) -> [TimelineEntry] {
        let ordered = events.sorted { ($0.occurredAt, $0.id ?? 0) < ($1.occurredAt, $1.id ?? 0) }
        var groups: [[AgentEvent]] = []
        for event in ordered {
            if event.kind == .subagentStop, let last = groups.last?.last, last.kind == .subagentStop {
                groups[groups.count - 1].append(event)
            } else {
                groups.append([event])
            }
        }
        return groups.enumerated().map { TimelineEntry(events: $1, position: $0) }
    }
}

// Resumo: Identificador único de uma sessão de agente aberta pelo Friday, que liga terminal, hooks e eventos.
// Tags: agentes, sensor

import Foundation

/// Identifica uma sessão do início ao fim. Para o Claude, é o mesmo valor passado em `--session-id`.
public struct AgentSessionID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: UUID

    public init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }

    /// Forma em texto minúsculo, a mesma que o Claude grava nos eventos.
    public var description: String { rawValue.uuidString.lowercased() }
}

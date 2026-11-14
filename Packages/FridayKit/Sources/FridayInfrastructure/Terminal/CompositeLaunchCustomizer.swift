// Resumo: Junta vários customizadores de lançamento (Claude, Codex...) num só: argumentos somados e ambiente mesclado.
// Tags: agentes, terminal

import FridayDomain

/// Aplica os customizadores na ordem dada; cada um decide sozinho se vale para o agente.
public struct CompositeLaunchCustomizer: AgentLaunchCustomizing {
    private let customizers: [any AgentLaunchCustomizing]

    public init(_ customizers: [any AgentLaunchCustomizing]) {
        self.customizers = customizers
    }

    /// Argumentos de todos, na ordem.
    public func extraArguments(agent: AgentKind, session: AgentSessionID) throws -> [String] {
        try customizers.flatMap { try $0.extraArguments(agent: agent, session: session) }
    }

    /// Ambientes mesclados; em chave repetida vence o último.
    public func extraEnvironment(agent: AgentKind, session: AgentSessionID) throws -> [String: String] {
        try customizers.reduce(into: [:]) { result, customizer in
            result.merge(try customizer.extraEnvironment(agent: agent, session: session)) { _, new in new }
        }
    }
}

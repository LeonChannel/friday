// Resumo: Põe as ferramentas do Friday ao alcance de cada sessão: o comando `friday` no PATH e, para o Claude, o plugin com a skill do assunto.
// Tags: agentes, terminal, assuntos

import FridayDomain

/// Entrega por sessão o que vem dentro do app, sem instalar nada no sistema nem em `~/.claude`.
public struct FridayToolsCustomizer: AgentLaunchCustomizing {
    private let binDirectory: String
    private let pluginDirectory: String?

    /// `binDirectory` contém o `friday`; `pluginDirectory` é um plugin do Claude Code (com `.claude-plugin/plugin.json`).
    public init(binDirectory: String, pluginDirectory: String?) {
        self.binDirectory = binDirectory
        self.pluginDirectory = pluginDirectory
    }

    /// Para o Claude, carrega o plugin do Friday só nesta sessão (`--plugin-dir`).
    public func extraArguments(agent: AgentKind, session: AgentSessionID) throws -> [String] {
        guard agent == .claude, let pluginDirectory else { return [] }
        return ["--plugin-dir", pluginDirectory]
    }

    /// `PATH` com a pasta do `friday`; o shell de login acrescenta os caminhos do sistema e do usuário depois.
    public func extraEnvironment(agent: AgentKind, session: AgentSessionID) throws -> [String: String] {
        ["PATH": binDirectory]
    }
}

// Resumo: Monta a receita de cada sessão (shell, Claude, Codex) passando pelo shell de login do usuário para achar os executáveis.
// Tags: agentes, terminal

import FridayDomain
import Foundation

/// Planner padrão, sem hooks. Rodar pelo shell de login interativo (`-l -i`) é o que recupera o PATH
/// do usuário (`~/.local/bin`, fnm), que um app de interface não herda.
public struct DefaultLaunchPlanner: LaunchPlanning {
    private let userShell: String
    private let home: String
    private let user: String
    private let language: String
    private let customizer: (any AgentLaunchCustomizing)?

    /// Os valores padrão vêm do ambiente do app; os parâmetros existem para os testes.
    public init(
        userShell: String? = nil,
        home: String = NSHomeDirectory(),
        user: String = NSUserName(),
        language: String? = nil,
        customizer: (any AgentLaunchCustomizing)? = nil
    ) {
        let environment = ProcessInfo.processInfo.environment
        let shell = userShell ?? environment["SHELL"] ?? "/bin/zsh"
        self.userShell = shell.hasPrefix("/") ? shell : "/bin/zsh"
        self.home = home
        self.user = user
        self.language = language ?? environment["LANG"] ?? "en_US.UTF-8"
        self.customizer = customizer
    }

    /// Receita da sessão: shell interativo de login e, para os agentes, `exec <comando>` dentro dele.
    public func plan(agent: AgentKind, project: Project, session: AgentSessionID) throws -> LaunchPlan {
        try plan(agent: agent, project: project, session: session, initialPrompt: nil)
    }

    /// Receita com a primeira mensagem: para o Claude vira o argumento posicional (sessão interativa que já começa com ela).
    public func plan(agent: AgentKind, project: Project, session: AgentSessionID, initialPrompt: String?) throws -> LaunchPlan {
        var arguments = ["-l", "-i"]
        if var command = Self.command(for: agent, session: session) {
            command += try customizer?.extraArguments(agent: agent, session: session) ?? []
            if agent == .claude, let initialPrompt, !initialPrompt.isEmpty { command.append(initialPrompt) }
            arguments += ["-c", "exec " + command.map(Self.shellQuoted).joined(separator: " ")]
        }
        var environment = environment(agent: agent, session: session)
        environment.merge(try customizer?.extraEnvironment(agent: agent, session: session) ?? [:]) { _, extra in extra }
        return LaunchPlan(
            executable: userShell,
            arguments: arguments,
            environment: environment,
            workingDirectory: project.path
        )
    }

    private func environment(agent: AgentKind, session: AgentSessionID) -> [String: String] {
        [
            "HOME": home,
            "USER": user,
            "LOGNAME": user,
            "SHELL": userShell,
            "TERM": "xterm-256color",
            "COLORTERM": "truecolor",
            "LANG": language,
            "FRIDAY_SESSION_ID": session.description,
            "FRIDAY_AGENT": agent.rawValue,
        ]
    }

    private static func command(for agent: AgentKind, session: AgentSessionID) -> [String]? {
        switch agent {
        case .shell: nil
        case .claude: ["claude", "--session-id", session.description]
        case .codex: ["codex"]
        }
    }

    /// Aspas simples de shell POSIX; palavra só com caracteres seguros fica como está.
    static func shellQuoted(_ word: String) -> String {
        let safe = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_./=:@%+,")
        if !word.isEmpty, word.allSatisfy(safe.contains) { return word }
        return "'" + word.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

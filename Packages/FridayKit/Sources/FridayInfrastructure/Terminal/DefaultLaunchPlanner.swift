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

    /// Os valores padrão vêm do ambiente do app; os parâmetros existem para os testes.
    public init(
        userShell: String? = nil,
        home: String = NSHomeDirectory(),
        user: String = NSUserName(),
        language: String? = nil
    ) {
        let environment = ProcessInfo.processInfo.environment
        let shell = userShell ?? environment["SHELL"] ?? "/bin/zsh"
        self.userShell = shell.hasPrefix("/") ? shell : "/bin/zsh"
        self.home = home
        self.user = user
        self.language = language ?? environment["LANG"] ?? "en_US.UTF-8"
    }

    /// Receita da sessão: shell interativo de login e, para os agentes, `exec <comando>` dentro dele.
    public func plan(agent: AgentKind, project: Project, session: AgentSessionID) throws -> LaunchPlan {
        var arguments = ["-l", "-i"]
        if let command = Self.command(for: agent, session: session) {
            arguments += ["-c", "exec \(command)"]
        }
        return LaunchPlan(
            executable: userShell,
            arguments: arguments,
            environment: environment(agent: agent, session: session),
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

    private static func command(for agent: AgentKind, session: AgentSessionID) -> String? {
        switch agent {
        case .shell: nil
        case .claude: "claude --session-id \(session.description)"
        case .codex: "codex"
        }
    }
}

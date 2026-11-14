// Resumo: Receita para abrir um programa no terminal (executável, argumentos, ambiente e pasta) e quem monta essa receita.
// Tags: agentes, terminal, sensor

/// Tudo que o terminal precisa para iniciar um processo. Quem monta não inicia; quem inicia não decide o conteúdo.
public struct LaunchPlan: Equatable, Sendable {
    /// Caminho absoluto do executável (por exemplo `/bin/zsh`).
    public var executable: String
    public var arguments: [String]
    /// Ambiente completo do processo; não é mesclado com nada depois.
    public var environment: [String: String]
    public var workingDirectory: String

    public init(executable: String, arguments: [String], environment: [String: String], workingDirectory: String) {
        self.executable = executable
        self.arguments = arguments
        self.environment = environment
        self.workingDirectory = workingDirectory
    }
}

/// Monta a receita de uma sessão. A versão com hooks do Friday vive na infraestrutura do sensor.
public protocol LaunchPlanning: Sendable {
    func plan(agent: AgentKind, project: Project, session: AgentSessionID) throws -> LaunchPlan
}

/// Acréscimos ao comando de um agente, por sessão (ex.: `--settings` com os hooks do Friday).
/// O planner aplica com o escape de shell correto; quem implementa não monta linha de comando.
public protocol AgentLaunchCustomizing: Sendable {
    /// Argumentos extras do agente, já separados (sem escape).
    func extraArguments(agent: AgentKind, session: AgentSessionID) throws -> [String]
    /// Variáveis de ambiente extras da sessão.
    func extraEnvironment(agent: AgentKind, session: AgentSessionID) throws -> [String: String]
}

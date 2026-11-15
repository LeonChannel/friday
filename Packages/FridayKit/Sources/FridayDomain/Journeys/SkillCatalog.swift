// Resumo: Contrato de quem lista as skills do Claude instaladas na máquina, para o dev escolher as de cada jornada.
// Tags: jornadas, agentes

/// Uma skill que o Claude Code consegue carregar.
public struct InstalledSkill: Equatable, Sendable, Identifiable {
    /// Nome de invocação: `skill` para as do usuário, `plugin:skill` para as de plugin.
    public var name: String
    public var summary: String
    /// De onde veio: "usuário" ou o nome do plugin.
    public var origin: String

    public var id: String { name }

    public init(name: String, summary: String, origin: String) {
        self.name = name
        self.summary = summary
        self.origin = origin
    }
}

/// Lista as skills instaladas. Só lê; nunca altera a configuração do agente.
public protocol SkillCataloging: Sendable {
    func installedSkills() -> [InstalledSkill]
}

// Resumo: Monta a primeira mensagem que o Claude recebe ao iniciar a jornada de um assunto: o pedido, o prompt do dev, as skills e as etapas.
// Tags: jornadas, assuntos, agentes

/// Primeira mensagem da sessão do Claude aberta para um assunto. Só junta o que o dev escreveu; não inventa método.
public enum JourneyBriefing {
    /// Texto do briefing. Começa sem hífen para nunca ser lido como opção da linha de comando.
    public static func text(subject: Subject, journey: Journey) -> String {
        let id = subject.id ?? 0
        var lines = ["Assunto \(id) no Friday (\(journey.kind.displayName)): \(subject.title)"]
        if !subject.intent.isEmpty { lines += ["", subject.intent] }

        let prompt = journey.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !prompt.isEmpty { lines += ["", "Como conduzir:", prompt] }

        let skills = journey.cleanSkills
        if !skills.isEmpty { lines += ["", "Use as skills: " + skills.joined(separator: ", ") + "."] }

        if !subject.stages.isEmpty {
            lines += ["", "Etapas (a lousa do dev mostra este trilho):"]
            for (index, stage) in subject.stages.enumerated() { lines.append("\(index + 1). \(stage.name)") }
            lines.append("Marque cada etapa com `friday etapa \(id) <n> --estado rodando|esperando-voce|concluida [--nota \"...\"]`.")
        }

        lines += ["", "Registre o estado do assunto \(id) com a skill friday-assunto (`friday assunto ler \(id)` primeiro)."]
        return lines.joined(separator: "\n")
    }
}

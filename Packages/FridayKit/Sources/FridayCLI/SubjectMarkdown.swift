// Resumo: Escreve o assunto em markdown compacto, para o Claude carregar barato o estado dele.
// Tags: assuntos

import FridayDomain
import Foundation

/// Formato de leitura do assunto: só as partes que têm conteúdo.
enum SubjectMarkdown {
    static func stateLabel(_ state: FrontState) -> String {
        switch state {
        case .running: "rodando"
        case .waitingForYou: "esperando você"
        case .done: "concluída"
        }
    }

    static func render(_ subject: Subject) -> String {
        let turn = subject.turn
        let holder = turn.holder == .you ? "você" : turn.holder == .claude ? "Claude" : "parado"
        var lines = ["# \(subject.title) (assunto \(subject.id ?? 0))", "vez: \(holder) · \(turn.reason)"]
        if !subject.intent.isEmpty { lines += ["", "## Intenção", subject.intent] }
        if !subject.questions.isEmpty {
            lines += ["", "## Perguntas"]
            for q in subject.questions {
                let mark = q.isOpen ? (q.waitsForYou ? " [espera você]" : " [aberta]") : " [respondida]"
                lines.append("- \(q.id). \(q.text)\(mark)")
                for option in q.options { lines.append("  - \(option.label) → \(option.consequence)") }
            }
        }
        if !subject.evidences.isEmpty {
            lines += ["", "## Evidências"]
            for e in subject.evidences { lines.append("- \(e.id). \(e.fact) · \(e.grade.label) · \(e.source)") }
        }
        if !subject.alternatives.isEmpty {
            lines += ["", "## Alternativas"]
            for a in subject.alternatives {
                lines.append("- \(a.id). \(a.name): ganho \(a.gain); risco \(a.risk); esforço \(a.effort); reversível \(a.reversibility)")
            }
        }
        if !subject.decisions.isEmpty {
            lines += ["", "## Decisões"]
            for d in subject.decisions {
                lines.append("- \(d.id). \(d.text) · porque: \(d.reason)" + (d.changeIf.map { " · mudaria se: \($0)" } ?? ""))
            }
        }
        if !subject.fronts.isEmpty {
            lines += ["", "## Frentes"]
            for f in subject.fronts {
                lines.append("- \(f.name) · \(stateLabel(f.state)) · critério: \(f.criterion)")
                for step in f.steps { lines.append("  - [\(step.isDone ? "x" : " ")] \(step.text)") }
            }
        }
        return lines.joined(separator: "\n")
    }
}

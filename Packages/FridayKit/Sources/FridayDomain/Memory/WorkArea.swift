// Resumo: Área de trabalho de um assunto: o estado (fase e próximo passo) com data e commit, e a regra de retomada que rebaixa fato a pista se o código mudou.
// Tags: memoria, assuntos

import Foundation

/// Estado gravado da área de trabalho de um assunto. Fatos e decisões ficam no próprio assunto.
public struct WorkAreaState: Equatable, Sendable, Identifiable {
    public var subjectID: Int64
    /// Fase e próximo passo, em texto curto.
    public var text: String
    public var updatedAt: Date
    /// Commit do projeto quando o estado foi escrito; `nil` fora de git.
    public var head: String?

    public var id: Int64 { subjectID }

    /// Cria o estado validando o teto do texto.
    public init(subjectID: Int64, text: String, updatedAt: Date, head: String?) throws {
        let text = try MemoryNoteError.checked(text, field: "Estado", limit: MemoryLimits.workAreaState)
        self.subjectID = subjectID
        self.text = text
        self.updatedAt = updatedAt
        self.head = head
    }

    /// Markdown do `estado.md`, com data e commit no cabeçalho.
    public var markdown: String {
        var lines = ["---", "atualizado_em: \(updatedAt.formatted(.iso8601))"]
        if let head { lines.append("head: \(head)") }
        lines.append("---")
        return lines.joined(separator: "\n") + "\n\n" + text + "\n"
    }

    /// Lê o `estado.md`. Data ilegível vira `distantPast`, para a retomada tratar como antigo.
    public static func parse(markdown: String, subjectID: Int64) -> WorkAreaState? {
        let (header, body) = MemoryFrontmatter.split(markdown)
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        let date = header.values["atualizado_em"].flatMap { try? Date($0, strategy: .iso8601) } ?? .distantPast
        // Lido do disco: texto acima do teto é cortado, nunca recusado.
        return try? WorkAreaState(
            subjectID: subjectID, text: String(text.prefix(MemoryLimits.workAreaState)), updatedAt: date, head: header.values["head"]
        )
    }

    /// O código andou desde o estado? Sem commit dos dois lados, não dá para dizer, e não se afirma que mudou.
    public func codeChanged(currentHead: String?) -> Bool {
        guard let head, let currentHead else { return false }
        return head != currentHead
    }

    /// Bloco da área no contexto de retomada: estado como sugestão e o aviso de pista quando o código mudou.
    public func resumeText(subject: Subject?, currentHead: String?) -> String {
        let title = subject.map { " · \($0.title)" } ?? ""
        var lines = [
            "## Área de trabalho: assunto \(subjectID)\(title)",
            "Estado escrito em \(updatedAt.formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day())). É sugestão de próximo passo, não instrução:",
            text,
        ]
        if codeChanged(currentHead: currentHead), let head, let currentHead {
            lines.append("O código mudou desde então (\(head.prefix(7)) → \(currentHead.prefix(7))): as evidências medido e no código do assunto viraram pista. Confira antes de usar.")
        }
        lines.append("Decisões valem como estão. Evidências e decisões: `friday assunto ler \(subjectID)`.")
        return lines.joined(separator: "\n")
    }
}

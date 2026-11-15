// Resumo: Escreve o item do backlog e o índice do projeto em markdown, para a pasta espelho no vault e para o Claude ler barato pela CLI.
// Tags: backlog

import Foundation

/// Texto markdown do backlog. Só texto: quem grava no disco é a infraestrutura.
public enum BacklogMarkdown {
    /// Uma linha por item: `FRI-12 · Bug · Fazendo · alta · título`.
    public static func line(_ item: BacklogItem, key: String) -> String {
        var parts = [BacklogCode.format(key: key, number: item.number), item.kind.label, item.status.label]
        if item.priority != .medium { parts.append(item.priority.label) }
        if let externalRef = item.externalRef { parts.append("→ \(externalRef)") }
        parts.append(item.title)
        return parts.joined(separator: " · ")
    }

    /// O item inteiro, com o pai e os filhos pelo código.
    public static func render(_ item: BacklogItem, key: String, parent: BacklogItem?, children: [BacklogItem]) -> String {
        let code = BacklogCode.format(key: key, number: item.number)
        var lines = [
            "---",
            "codigo: \(code)",
            "tipo: \(item.kind.cliName)",
            "estado: \(item.status.cliName)",
            "prioridade: \(item.priority.label)",
            "autor: \(item.author == .claude ? "claude" : "voce")",
        ]
        if let parent { lines.append("pai: \(BacklogCode.format(key: key, number: parent.number))") }
        if let externalRef = item.externalRef { lines.append("externo: \"\(externalRef.replacingOccurrences(of: "\"", with: "'"))\"") }
        lines.append("criado_em: \(day(item.createdAt))")
        lines.append("atualizado_em: \(day(item.updatedAt))")
        lines += ["---", "", "# \(code) · \(item.title)", ""]
        lines.append("Espelho gerado pelo Friday. Edite pelo app ou por `friday item`; mudança feita aqui é sobrescrita.")
        if let location = item.location {
            let grade = item.grade.map { " (\($0.label))" } ?? ""
            lines += ["", "**Onde:** `\(location)`\(grade)"]
        } else if let grade = item.grade {
            lines += ["", "**Grau:** \(grade.label)"]
        }
        if !item.detail.isEmpty { lines += ["", item.detail] }
        if !children.isEmpty {
            lines += ["", "## Dentro deste item", ""]
            lines += children.map { "- \(line($0, key: key))" }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Índice do backlog do projeto: bugs abertos por estado, depois a árvore de épicos, histórias e tasks.
    public static func index(_ items: [BacklogItem], key: String, projectName: String) -> String {
        var lines = ["# Backlog · \(projectName)", "", "Espelho gerado pelo Friday. A fonte é o app; edite por lá ou por `friday item`.", ""]
        let openBugs = items.filter { $0.kind == .bug && !$0.status.isClosed }
        lines.append("## Bugs abertos · \(openBugs.count)")
        for (status, column) in BacklogProjection.columns(openBugs, statuses: BacklogStatus.allCases) where !column.isEmpty {
            lines += ["", "### \(status.label)"]
            lines += column.map { "- [[\(BacklogCode.format(key: key, number: $0.number))]] \($0.title)" }
        }
        let tree = items.filter { !($0.kind == .bug && $0.parentID == nil) && $0.status != .discarded }
        let children = BacklogProjection.children(tree)
        lines += ["", "## Itens"]
        if tree.isEmpty { lines.append("") ; lines.append("Nenhum item ainda.") }
        func walk(_ parent: Int64?, depth: Int) {
            for item in children[parent] ?? [] {
                let code = BacklogCode.format(key: key, number: item.number)
                lines.append("\(String(repeating: "  ", count: depth))- [[\(code)]] \(item.kind.label) · \(item.status.label) · \(item.title)")
                if let id = item.id { walk(id, depth: depth + 1) }
            }
        }
        if !tree.isEmpty { lines.append("") }
        walk(nil, depth: 0)
        return lines.joined(separator: "\n") + "\n"
    }

    private static func day(_ date: Date) -> String {
        date.formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day())
    }
}

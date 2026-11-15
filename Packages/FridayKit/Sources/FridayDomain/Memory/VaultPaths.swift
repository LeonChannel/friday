// Resumo: Onde cada coisa mora dentro do vault (camadas, projeto, área de trabalho, backlog) e o nome de pasta ou arquivo em ASCII sem acento.
// Tags: memoria, backlog

import Foundation

/// Caminhos relativos à raiz do vault. Só texto: quem lê e grava o disco é a infraestrutura.
public enum VaultPaths {
    /// Hub da raiz do vault.
    public static let hub = "00 - Friday.md"
    /// Pasta das áreas de trabalho dentro do projeto.
    public static let workFolder = "Trabalho"
    /// Pasta do espelho do backlog dentro do projeto; não é nota de memória.
    public static let backlogFolder = "Backlog"

    /// Nome de pasta ou arquivo digitável e estável: sem acento, sem barra, só letra, número, espaço, `-` e `_`.
    public static func slug(_ name: String) -> String {
        let folded = name.folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US_POSIX"))
        let mapped = String(folded.map { char -> Character in
            let allowed = char.isASCII && (char.isLetter || char.isNumber || char == " " || char == "-" || char == "_")
            return allowed ? char : "-"
        })
        let collapsed = mapped
            .replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
            .replacingOccurrences(of: " +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: " -"))
        return collapsed.isEmpty ? "sem-nome" : collapsed
    }

    /// Pasta do projeto: `Projetos/<slug>`.
    public static func project(_ projectName: String) -> String {
        "\(MemoryLayer.project.folder)/\(slug(projectName))"
    }

    /// Hub do projeto: `Projetos/<slug>/00 - <slug>.md`.
    public static func projectHub(_ projectName: String) -> String {
        "\(project(projectName))/00 - \(slug(projectName)).md"
    }

    /// Área de trabalho de um assunto: `Projetos/<slug>/Trabalho/assunto-<id>`.
    public static func workArea(projectName: String, subject: Int64) -> String {
        "\(project(projectName))/\(workFolder)/assunto-\(subject)"
    }

    /// Pasta do espelho do backlog: `Projetos/<slug>/Backlog`.
    public static func backlog(projectName: String) -> String {
        "\(project(projectName))/\(backlogFolder)"
    }

    /// Arquivo de um item no espelho, pelo código (estável mesmo se o título mudar): `Projetos/<slug>/Backlog/FRI-12.md`.
    public static func backlogItem(projectName: String, code: String) -> String {
        "\(backlog(projectName: projectName))/\(slug(code)).md"
    }

    /// Índice do backlog do projeto.
    public static func backlogIndex(projectName: String) -> String {
        "\(backlog(projectName: projectName))/00 - Backlog.md"
    }

    /// Estado da área de trabalho.
    public static func workAreaState(projectName: String, subject: Int64) -> String {
        "\(workArea(projectName: projectName, subject: subject))/estado.md"
    }

    /// Onde gravar uma nota nova: pasta da camada (ou do projeto), subpasta do tipo e o título como nome de arquivo.
    public static func newNote(title: String, kind: MemoryNoteKind, projectName: String?) -> String {
        let base = kind.layer == .project ? project(projectName ?? "") : kind.layer.folder
        let folder = kind.defaultFolder.map { "\(base)/\($0)" } ?? base
        return "\(folder)/\(slug(title)).md"
    }

    /// Recusa caminho que sai do vault (`..`, absoluto) ou que não é nota markdown.
    public static func isSafeNotePath(_ path: String) -> Bool {
        guard !path.isEmpty, !path.hasPrefix("/"), path.hasSuffix(".md") else { return false }
        return !path.split(separator: "/").contains { $0 == ".." || $0 == "." }
    }
}

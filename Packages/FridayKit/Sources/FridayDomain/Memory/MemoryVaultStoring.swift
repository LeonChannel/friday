// Resumo: Contrato de quem lê e grava o vault (notas por camada, área de trabalho, estrutura inicial) e a promoção de uma decisão do assunto a nota de projeto.
// Tags: memoria, assuntos

import Foundation

/// Notas lidas de uma camada, com as que tinham problema ao lado (nada some em silêncio).
public struct MemoryLoad: Equatable, Sendable {
    public var notes: [MemoryNote]
    public var issues: [MemoryIssue]

    public init(notes: [MemoryNote] = [], issues: [MemoryIssue] = []) {
        self.notes = notes
        self.issues = issues
    }
}

/// Onde a memória mora. Produção usa uma pasta de markdown; teste usa uma pasta temporária.
public protocol MemoryVaultStoring: Sendable {
    /// Raiz do vault, para mostrar e para o contexto.
    var rootPath: String { get }
    /// Cria as pastas e as notas iniciais que faltam (e o hub do projeto, se houver). Nunca sobrescreve o que existe.
    func scaffold(project: Project?, repositories: [CodeRepository]) throws
    /// Notas de uma camada; `projectName` só vale para a camada de projeto. Ignora a área de trabalho.
    func load(_ layer: MemoryLayer, projectName: String?) throws -> MemoryLoad
    /// Markdown de uma nota pelo caminho relativo; `nil` se não existir.
    func read(_ path: String) throws -> String?
    /// Grava a nota no caminho dela, criando as pastas.
    func save(_ note: MemoryNote) throws
    /// Estado da área de trabalho do assunto, se houver.
    func workArea(projectName: String, subject: Int64) throws -> WorkAreaState?
    /// Estados de todas as áreas abertas do projeto.
    func workAreas(projectName: String) throws -> [WorkAreaState]
    func saveWorkArea(_ state: WorkAreaState, projectName: String) throws
    /// Apaga a área do assunto (estado e cache), depois de destilada.
    func closeWorkArea(projectName: String, subject: Int64) throws
}

extension MemoryVaultStoring {
    /// Lê as três camadas de uma vez para montar o contexto.
    public func snapshot(projectName: String?) throws -> (snapshot: MemorySnapshot, issues: [MemoryIssue]) {
        let abstraction = try load(.abstraction, projectName: nil)
        let process = try load(.process, projectName: nil)
        let project = try projectName.map { try load(.project, projectName: $0) } ?? MemoryLoad()
        let snapshot = MemorySnapshot(
            vaultPath: rootPath, abstraction: abstraction.notes, process: process.notes, project: project.notes, projectName: projectName
        )
        return (snapshot, abstraction.issues + process.issues + project.issues)
    }
}

extension MemoryNote {
    /// Nota `decisao` do projeto feita de uma decisão do assunto: o que, por quê, o que faria mudar e de onde veio.
    public static func promoting(_ decision: Decision, of subject: Subject, projectName: String, today: String) throws -> MemoryNote {
        let title = clipped(decision.text, to: MemoryLimits.title)
        let summary = clipped("\(decision.text.trimmingTrailingPeriod). Porque \(decision.reason.trimmingTrailingPeriod).", to: MemoryLimits.summary)
        var body = ["# \(title)", "", decision.text, "", "- **Por quê:** \(decision.reason)"]
        if let changeIf = decision.changeIf { body.append("- **Mudaria se:** \(changeIf)") }
        body.append("- **Origem:** assunto \(subject.id ?? 0) · \(subject.title) · decidida em \(decision.decidedAt.formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day()))")
        return try MemoryNote(
            path: VaultPaths.newNote(title: title, kind: .decision, projectName: projectName),
            layer: .project, kind: .decision, title: title, summary: summary, verifiedAt: today,
            body: body.joined(separator: "\n")
        )
    }

    private static func clipped(_ text: String, to limit: Int) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count <= limit ? trimmed : String(trimmed.prefix(limit - 1)) + "…"
    }
}

private extension String {
    var trimmingTrailingPeriod: String {
        var text = trimmingCharacters(in: .whitespacesAndNewlines)
        while text.hasSuffix(".") { text.removeLast() }
        return text
    }
}

// Resumo: Estado da tela de Memória de um projeto: notas das três camadas, áreas de trabalho, o contexto que a sessão recebe e as ações de criar, importar, promover e fechar.
// Tags: memoria, interface

import FridayDomain
import Foundation
import Observation

/// Memória de um projeto na tela. Relê o vault quando a pasta muda no disco (o dev edita as notas fora do app).
@MainActor
@Observable
public final class MemoryModel {
    public let project: Project
    public private(set) var abstraction: [MemoryNote] = []
    public private(set) var process: [MemoryNote] = []
    public private(set) var projectNotes: [MemoryNote] = []
    public private(set) var issues: [MemoryIssue] = []
    public private(set) var workAreas: [WorkAreaState] = []
    /// O que uma sessão sem assunto recebe no começo, com o tamanho.
    public private(set) var briefing: MemoryBriefing?
    /// Mensagem em português da última ação que falhou.
    public var errorMessage: String?

    private let settings: AppSettings
    private let makeVault: @Sendable (String) -> any MemoryVaultStoring
    private let watcher: any ChangeWatching
    private let now: @Sendable () -> Date

    public init(
        project: Project,
        settings: AppSettings,
        makeVault: @escaping @Sendable (String) -> any MemoryVaultStoring,
        watcher: any ChangeWatching,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.project = project
        self.settings = settings
        self.makeVault = makeVault
        self.watcher = watcher
        self.now = now
    }

    /// Pasta do vault escolhida; `nil` enquanto o dev não escolheu.
    public var vaultPath: String? { settings.vaultPath }

    /// Vault escolhido, mas sem nenhuma nota nas camadas comuns: a tela oferece criar a estrutura.
    public var needsScaffold: Bool {
        vaultPath != nil && abstraction.isEmpty && process.isEmpty && projectNotes.isEmpty && issues.isEmpty
    }

    /// O projeto ainda não tem hub no vault.
    public var lacksProjectHub: Bool { !projectNotes.contains { $0.kind == .projectHub } }

    private var vault: (any MemoryVaultStoring)? { vaultPath.map(makeVault) }

    /// Relê as três camadas e as áreas de trabalho.
    public func reload() {
        guard let vault else {
            abstraction = []; process = []; projectNotes = []; issues = []; workAreas = []; briefing = nil
            return
        }
        do {
            let (snapshot, problems) = try vault.snapshot(projectName: project.name)
            abstraction = snapshot.abstraction
            process = snapshot.process
            projectNotes = snapshot.project
            issues = problems
            workAreas = try vault.workAreas(projectName: project.name)
            briefing = MemoryBriefing.sessionStart(snapshot)
        } catch {
            errorMessage = "Não consegui ler o vault: \(error.localizedDescription)"
        }
    }

    /// Lê agora e de novo a cada mudança na pasta, até a tarefa ser cancelada. Use em `.task(id: vaultPath)`.
    public func observe() async {
        reload()
        guard let path = vaultPath else { return }
        for await _ in await watcher.changes(inFolderAt: path) {
            reload()
        }
    }

    /// Passa a usar a pasta e relê. As sessões novas recebem `FRIDAY_VAULT` com ela.
    public func chooseVault(path: String) {
        settings.vaultPath = Project.normalizedPath(path)
        errorMessage = nil
        reload()
    }

    /// Cria as pastas, as notas iniciais e o hub deste projeto, sem sobrescrever nada.
    public func scaffold(repositories: [CodeRepository]) {
        act { try $0.scaffold(project: project, repositories: repositories) }
    }

    /// Troca o corpo da nota de comunicação pelo texto importado, mantendo tipo e resumo.
    public func importCommunication(_ text: String, sourceName: String) {
        act { vault in
            let path = "\(MemoryLayer.abstraction.folder)/Comunicacao.md"
            let current = try vault.read(path).flatMap { try? MemoryNote.parse(markdown: $0, path: path, layer: .abstraction) }
            let (_, imported) = MemoryFrontmatter.split(text)
            let body = imported.trimmingCharacters(in: .whitespacesAndNewlines)
            let titled = body.hasPrefix("# ") ? body : "# Comunicação\n\n" + body
            try vault.save(try MemoryNote(
                path: path, layer: .abstraction, kind: .communication, title: current?.title ?? "Comunicação",
                summary: current?.summary ?? "Regras de comunicação importadas de \(sourceName).", body: titled
            ))
        }
    }

    /// Grava a decisão do assunto como nota `decisao` do projeto. Devolve o caminho.
    @discardableResult
    public func promote(_ decision: Decision, of subject: Subject) -> String? {
        var path: String?
        act { vault in
            let note = try MemoryNote.promoting(decision, of: subject, projectName: project.name, today: today())
            try vault.save(note)
            path = note.path
        }
        return path
    }

    /// Diz se a decisão já virou nota (mesmo caminho que a promoção usaria).
    public func isPromoted(_ decision: Decision, of subject: Subject) -> Bool {
        guard let note = try? MemoryNote.promoting(decision, of: subject, projectName: project.name, today: today()) else { return false }
        return projectNotes.contains { $0.path == note.path }
    }

    /// Apaga a área de trabalho do assunto (estado e cache).
    public func closeWorkArea(subject: Int64) {
        act { try $0.closeWorkArea(projectName: project.name, subject: subject) }
    }

    /// Markdown inteiro da nota, para a folha de leitura.
    public func markdown(of note: MemoryNote) -> String? {
        try? vault?.read(note.path)
    }

    /// Caminho absoluto de uma nota, para abrir no editor.
    public func fileURL(of note: MemoryNote) -> URL? {
        vaultPath.map { URL(fileURLWithPath: $0).appendingPathComponent(note.path) }
    }

    private func today() -> String {
        now().formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day())
    }

    private func act(_ change: (any MemoryVaultStoring) throws -> Void) {
        guard let vault else { errorMessage = "Escolha a pasta do vault primeiro."; return }
        do {
            try change(vault)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        reload()
    }
}

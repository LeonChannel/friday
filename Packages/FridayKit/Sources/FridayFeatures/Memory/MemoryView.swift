// Resumo: Tela de Memória: as três camadas do vault em colunas, a destilação dos assuntos em notas de projeto e o contexto exato que a sessão recebe, com o custo.
// Tags: memoria, interface

import AppKit
import FridayDomain
import SwiftUI
import UniformTypeIdentifiers

/// Memória do projeto aberto.
struct MemoryView: View {
    let model: MemoryModel
    let repositories: [CodeRepository]
    @Environment(\.openURL) private var openURL
    @State private var reading: MemoryNote?
    @State private var showsBriefing = false
    @State private var closing: Int64?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
            header
            if let error = model.errorMessage {
                Text(error).typography(.secundario).foregroundStyle(Theme.erro)
            }
            if model.vaultPath == nil {
                emptyState(
                    "A memória mora numa pasta de markdown sua, legível fora do app. Escolha a pasta para o Friday ler e escrever as notas.",
                    action: "Escolher pasta…", perform: chooseFolder
                )
            } else if model.needsScaffold {
                emptyState(
                    "A pasta ainda não tem notas. Criar a estrutura das três camadas, com notas iniciais para você editar e o hub de \(model.project.name).",
                    action: "Criar estrutura", perform: { model.scaffold(repositories: repositories) }
                )
            } else {
                ScrollView {
                    MemoryLayersView(model: model, reading: $reading, closing: $closing, showsBriefing: $showsBriefing)
                        .padding(.bottom, Spacing.xxxl)
                }
                .scrollIndicators(.automatic)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.fundo)
        .task(id: model.vaultPath) { await model.observe() }
        .sheet(item: $reading) { note in
            MemoryNoteSheet(note: note, markdown: model.markdown(of: note) ?? note.body) {
                if let url = model.fileURL(of: note) { openURL(url) }
            }
        }
        .confirmationDialog("Fechar a área de trabalho?", isPresented: Binding(get: { closing != nil }, set: { if !$0 { closing = nil } })) {
            Button("Fechar área", role: .destructive) {
                if let closing { model.closeWorkArea(subject: closing) }
                closing = nil
            }
        } message: {
            Text("O estado e o cache do assunto são apagados do vault. Decisões e evidências continuam no assunto.")
        }
    }

    // MARK: Topo

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Memória").typography(.tituloTela).foregroundStyle(Theme.texto)
                if let path = model.vaultPath {
                    MonoLabel(path).textSelection(.enabled).lineLimit(1).truncationMode(.middle)
                }
            }
            Spacer()
            if let path = model.vaultPath {
                if !model.needsScaffold, model.lacksProjectHub {
                    Button("Criar hub do projeto") { model.scaffold(repositories: repositories) }.buttonStyle(.friday)
                }
                Button("Importar comunicação…", action: importCommunication)
                    .buttonStyle(.friday)
                    .help("Troca o corpo de Abstracao/Comunicacao.md pelo arquivo escolhido (ex.: as regras que você já usa).")
                Button("Mostrar no Finder") { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)]) }
                    .buttonStyle(.friday)
                Button("Trocar pasta…", action: chooseFolder).buttonStyle(.friday)
            }
        }
    }

    private func emptyState(_ text: String, action: String, perform: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Nada de fixedSize vertical: medido com largura quase zero, pedia uma linha por letra e esticava a janela (tela preta).
            Text(text).typography(.corpo).foregroundStyle(Theme.textoSecundario).lineLimit(4)
            Button(action, action: perform).buttonStyle(.fridayPrimary)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: 560, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: Radius.peca).strokeBorder(Theme.linha, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
    }

    // MARK: Ações

    private func chooseFolder() {
        if let url = FolderPanel.choose(prompt: "Usar como vault") { model.chooseVault(path: url.path) }
    }

    private func importCommunication() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.plainText, .init(filenameExtension: "md") ?? .plainText]
        panel.showsHiddenFiles = true
        panel.prompt = "Importar"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            model.importCommunication(try String(contentsOf: url, encoding: .utf8), sourceName: url.lastPathComponent)
        } catch {
            model.errorMessage = "Não consegui ler \(url.lastPathComponent): \(error.localizedDescription)"
        }
    }
}

/// Conteúdo rolável da Memória: colunas das camadas, notas com problema, destilação e o contexto de início.
struct MemoryLayersView: View {
    let model: MemoryModel
    @Binding var reading: MemoryNote?
    @Binding var closing: Int64?
    @Binding var showsBriefing: Bool
    @Environment(SubjectsModel.self) private var subjects

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxxl) {
            HStack(alignment: .top, spacing: Spacing.lg) {
                column(.abstraction, notes: model.abstraction, empty: "Nenhuma regra de comunicação ou conduta.")
                column(.process, notes: model.process, empty: "Nenhum fluxo registrado.")
                projectColumn
            }
            if !model.issues.isEmpty { issues }
            distillation
            briefing
        }
    }

    // MARK: Camadas

    private var projectColumn: some View {
        column(.project, notes: model.projectNotes, title: "Projeto · \(model.project.name)", empty: "Nenhuma nota deste projeto ainda.")
    }

    private func column(_ layer: MemoryLayer, notes: [MemoryNote], title: String? = nil, empty: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            MonoLabel("\(title ?? layer.displayName) · \(notes.count)", kind: .secao)
            Text(subtitle(layer)).typography(.secundario).foregroundStyle(Theme.textoSecundario)
            if notes.isEmpty {
                Text(empty)
                    .typography(.secundario).foregroundStyle(Theme.textoSecundario)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: Radius.peca).strokeBorder(Theme.linha, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
            }
            ForEach(notes) { note in
                Button { reading = note } label: { MemoryNoteCard(note: note) }.buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func subtitle(_ layer: MemoryLayer) -> String {
        switch layer {
        case .abstraction: "Como o Claude fala e se porta. Entra inteira em toda sessão."
        case .process: "Como o trabalho anda no Friday. As marcadas como sempre entram inteiras."
        case .project: "Regras, padrões, decisões e mapa. Índice no começo; a ancorada chega ao abrir o arquivo."
        }
    }

    private var issues: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            MonoLabel("Com problema · \(model.issues.count)", kind: .secao)
            ForEach(model.issues) { issue in
                Text("\(issue.path): \(issue.message)").typography(.secundario).foregroundStyle(Theme.erro).textSelection(.enabled)
            }
            Text("Estas notas não chegam ao Claude até serem corrigidas.").typography(.secundario).foregroundStyle(Theme.textoSecundario)
        }
    }

    // MARK: Destilação

    /// Assuntos do projeto com área de trabalho aberta ou decisão a promover.
    private var distillationRows: [SubjectRow] {
        let withArea = Set(model.workAreas.map(\.subjectID))
        return subjects.rows.filter { row in
            guard let id = row.subject.id else { return false }
            return row.subject.projectID == model.project.id && (withArea.contains(id) || !row.subject.decisions.isEmpty)
        }
    }

    private var distillation: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            MonoLabel("Área de trabalho e destilação", kind: .secao)
            Text("O que sobrevive ao assunto vira nota do projeto; estado e cache morrem com a área.")
                .typography(.secundario).foregroundStyle(Theme.textoSecundario)
            if distillationRows.isEmpty {
                Text("Nenhum assunto deste projeto com área aberta ou decisão.")
                    .typography(.secundario).foregroundStyle(Theme.textoSecundario)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: Radius.peca).strokeBorder(Theme.linha, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
            }
            ForEach(distillationRows) { row in
                distillationCard(row.subject)
            }
        }
    }

    private func distillationCard(_ subject: Subject) -> some View {
        let id = subject.id ?? 0
        let state = model.workAreas.first { $0.subjectID == id }
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Text(subject.title).typography(.corpo).fontWeight(.semibold).foregroundStyle(Theme.texto)
                MonoLabel("assunto \(id)")
                Spacer()
                if state != nil {
                    Button("Fechar área") { closing = id }.buttonStyle(.friday)
                }
            }
            if let state {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    MonoLabel("estado · \(state.updatedAt.formatted(.relative(presentation: .named)))\(state.head.map { " · \($0.prefix(7))" } ?? "")")
                    Text(state.text).typography(.secundario).foregroundStyle(Theme.texto).textSelection(.enabled)
                }
            }
            ForEach(subject.decisions) { decision in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(decision.text).typography(.secundario).foregroundStyle(Theme.texto)
                        Text("porque \(decision.reason)").typography(.secundario).foregroundStyle(Theme.textoSecundario)
                    }
                    Spacer()
                    if model.isPromoted(decision, of: subject) {
                        MonoLabel("no projeto")
                    } else {
                        Button("Promover") { model.promote(decision, of: subject) }
                            .buttonStyle(.friday)
                            .help("Grava esta decisão como nota do projeto, em Decisoes/.")
                    }
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.peca).fill(Theme.superficie))
        .overlay(RoundedRectangle(cornerRadius: Radius.peca).strokeBorder(Theme.linha))
    }

    // MARK: Contexto

    @ViewBuilder
    private var briefing: some View {
        if let briefing = model.briefing {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.md) {
                    MonoLabel("Contexto de início", kind: .secao)
                    let omitted = briefing.omitted > 0 ? " · \(briefing.omitted) fora do teto" : ""
                    MonoLabel("fonte: \(briefing.included) notas · \(briefing.characters) caracteres · ~\(briefing.estimatedTokens) tokens\(omitted)")
                    Spacer()
                    Button(showsBriefing ? "Esconder" : "Mostrar") { showsBriefing.toggle() }.buttonStyle(.friday)
                }
                Text("O que toda sessão do Claude aberta neste projeto recebe no começo, antes de você digitar.")
                    .typography(.secundario).foregroundStyle(Theme.textoSecundario)
                if showsBriefing {
                    Text(briefing.text)
                        .typography(.metadado)
                        .foregroundStyle(Theme.texto)
                        .textSelection(.enabled)
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: Radius.campo).fill(Theme.superficieElevada))
                        .overlay(RoundedRectangle(cornerRadius: Radius.campo).strokeBorder(Theme.linha))
                }
            }
        }
    }
}

/// Uma nota na coluna da camada: título, tipo, como chega ao Claude e o resumo.
struct MemoryNoteCard: View {
    let note: MemoryNote

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(note.title).typography(.corpo).fontWeight(.semibold).foregroundStyle(Theme.texto).lineLimit(2)
            MonoLabel(meta)
            Text(note.summary).typography(.secundario).foregroundStyle(Theme.textoSecundario).lineLimit(4)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.peca).fill(Theme.superficie))
        .overlay(RoundedRectangle(cornerRadius: Radius.peca).strokeBorder(Theme.linha))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// Tipo · como chega (inteira com o custo, ou índice) · âncoras.
    private var meta: String {
        var parts = [note.kind.rawValue]
        if note.always || note.kind == .projectHub {
            let size = min(note.bodyWithoutTitle.count, MemoryLimits.inlineNote)
            parts.append("inteira · ~\((size + 3) / 4) tokens")
        } else {
            parts.append("índice")
        }
        if !note.anchors.isEmpty { parts.append(note.anchors.count == 1 ? "1 âncora" : "\(note.anchors.count) âncoras") }
        if let verified = note.verifiedAt { parts.append("conferida \(verified)") }
        return parts.joined(separator: " · ")
    }
}

/// Folha de leitura de uma nota: o markdown como está no disco e o botão para abrir no editor.
struct MemoryNoteSheet: View {
    let note: MemoryNote
    let markdown: String
    let openInEditor: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.title).typography(.tituloAssunto).foregroundStyle(Theme.texto)
                    MonoLabel("\(note.layer.displayName) · \(note.kind.rawValue) · \(note.path)").textSelection(.enabled)
                }
                Spacer()
                Button("Abrir no editor", action: openInEditor).buttonStyle(.friday)
                Button("Fechar") { dismiss() }.buttonStyle(.friday).keyboardShortcut(.cancelAction)
            }
            if !note.anchors.isEmpty {
                MonoLabel("âncoras: " + note.anchors.joined(separator: ", ")).textSelection(.enabled)
            }
            ScrollView {
                Text(markdown)
                    .typography(.metadado)
                    .foregroundStyle(Theme.texto)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Spacing.md)
            .background(RoundedRectangle(cornerRadius: Radius.campo).fill(Theme.superficieElevada))
        }
        .padding(Spacing.xxl)
        .frame(minWidth: 620, idealWidth: 720, minHeight: 420, idealHeight: 560)
        .background(Theme.superficie)
    }
}

#if DEBUG
import FridayInfrastructure

/// Vault só de leitura, em memória, para as prévias não tocarem no disco.
private struct PreviewMemoryVault: MemoryVaultStoring {
    let rootPath = "/Users/exemplo/Friday Vault"
    let notes: [MemoryNote]
    let areas: [WorkAreaState]

    func scaffold(project: Project?, repositories: [CodeRepository]) throws {}
    func load(_ layer: MemoryLayer, projectName: String?) throws -> MemoryLoad { MemoryLoad(notes: notes.filter { $0.layer == layer }) }
    func read(_ path: String) throws -> String? { notes.first { $0.path == path }?.markdown }
    func save(_ note: MemoryNote) throws {}
    func workArea(projectName: String, subject: Int64) throws -> WorkAreaState? { areas.first { $0.subjectID == subject } }
    func workAreas(projectName: String) throws -> [WorkAreaState] { areas }
    func saveWorkArea(_ state: WorkAreaState, projectName: String) throws {}
    func closeWorkArea(projectName: String, subject: Int64) throws {}
}

@MainActor
private func memoryPreview(_ scheme: ColorScheme) -> some View {
    // SAFETY: só prévia; dados fixos que passam na validação e banco em memória não falha ao abrir.
    let notes = [
        try! MemoryNote(path: "Abstracao/Comunicacao.md", layer: .abstraction, kind: .communication, title: "Comunicação",
                        summary: "Fale em português, direto, com a conclusão primeiro. Deixe claro o nível de certeza.", body: "# Comunicação\n\n- Conclusão primeiro."),
        try! MemoryNote(path: "Abstracao/Conduta.md", layer: .abstraction, kind: .conduct, title: "Conduta",
                        summary: "Pare só em dúvida que três caminhos não resolveram, desvio grande do padrão ou ação difícil de desfazer.", body: "# Conduta"),
        try! MemoryNote(path: "Processual/Fluxo.md", layer: .process, kind: .flow, title: "Fluxo de trabalho no Friday",
                        summary: "Antes: a memória chega sozinha. Durante: estado no assunto. Depois: o que sobrevive vira nota.", always: true, body: "# Fluxo"),
        try! MemoryNote(path: "Projetos/friday/00 - friday.md", layer: .project, kind: .projectHub, title: "friday",
                        summary: "Hub do projeto friday: tecnologias, repositórios e onde achar o resto.", body: "# friday\n\nSwift 6, SwiftUI, GRDB."),
        try! MemoryNote(path: "Projetos/friday/Regras/Escrita.md", layer: .project, kind: .rule, title: "Escrita só pelo repositório",
                        summary: "A view nunca grava no banco; tudo passa pelo repositório.", anchors: ["Packages/FridayKit/Sources/FridayInfrastructure/"],
                        verifiedAt: "2026-11-14", body: "# Escrita só pelo repositório"),
    ]
    let areas = [try! WorkAreaState(subjectID: 1, text: "Fase: medir o p95 da fila. Próximo: comparar com o TTL.", updatedAt: .now.addingTimeInterval(-7200), head: "a1b2c3d")]
    let defaults = UserDefaults(suiteName: "friday.preview.memoria") ?? .standard
    let settings = AppSettings(defaults: defaults)
    settings.vaultPath = "/Users/exemplo/Friday Vault"
    let project = Project(id: 1, name: "friday", path: "/Users/exemplo/Projetos/friday", kind: .git, addedAt: .now)
    let vault = PreviewMemoryVault(notes: notes, areas: areas)
    let model = MemoryModel(project: project, settings: settings, makeVault: { _ in vault }, watcher: FolderChangeWatcher())
    let database = try! AppDatabase.inMemory()
    let subjects = GRDBSubjectRepository(database: database)
    _ = try! GRDBProjectRepository(database: database).insert(project)
    if var subject = try? Subject(title: "Reduzir o custo da fila de imagens", projectID: 1, createdAt: .now) {
        _ = try? subject.recordDecision(text: "Invalidar por evento, não por tempo.", reason: "TTL serve dado velho", at: .now)
        _ = try? subjects.insert(subject)
    }
    let subjectsModel = SubjectsModel(repository: subjects)
    return MemoryView(model: model, repositories: [])
        .environment(subjectsModel)
        .task { await subjectsModel.observe() }
        .frame(width: 1100, height: 760)
        .preferredColorScheme(scheme)
}

#Preview("Memória, escuro") { memoryPreview(.dark) }
#Preview("Memória, claro") { memoryPreview(.light) }
#endif

// Resumo: Seleção de projetos na abertura: fundo líquido, busca, projetos recentes e as entradas para abrir pasta, clonar ou criar, com botões que reagem ao mouse.
// Tags: projetos, interface

import AppKit
import FridayDomain
import SwiftUI

/// Tela de entrada do Friday. O dev decide o que é projeto: uma pasta, um repositório ou uma pasta com vários.
struct ProjectPickerView: View {
    @Environment(ProjectsModel.self) private var projects
    let open: (Project) -> Void
    @State private var search = ""
    @State private var sheet: CreationSheet?
    @State private var errorMessage: String?
    @FocusState private var searchFocused: Bool

    enum CreationSheet: Identifiable {
        case clone, create
        var id: Self { self }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.md) {
                FridayMark(size: 56)
                Text("Escolha um projeto").typography(.tituloTela).foregroundStyle(Theme.texto)
                Text("Uma pasta, um repositório ou uma pasta com vários. Você decide o que é projeto.")
                    .typography(.secundario).foregroundStyle(Theme.textoSecundario)
            }
            .padding(.top, Spacing.huge)
            .padding(.bottom, Spacing.xxl)

            HStack(spacing: Spacing.sm) {
                Button("Abrir pasta…", systemImage: "folder", action: pickFolder)
                    .buttonStyle(.fridayLive).keyboardShortcut("o", modifiers: .command)
                Button("Clonar repositório…", systemImage: "arrow.down.circle") { sheet = .clone }
                    .buttonStyle(.fridayLive)
                Button("Criar pasta nova…", systemImage: "folder.badge.plus") { sheet = .create }
                    .buttonStyle(.fridayLive).keyboardShortcut("n", modifiers: [.command, .shift])
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    MonoLabel("Recentes · \(projects.projects.count)", kind: .secao)
                    Spacer()
                }
                TextField("Buscar projeto", text: $search)
                    .textFieldStyle(.plain)
                    .typography(.corpo)
                    .focused($searchFocused)
                    .padding(Spacing.sm)
                    .background(RoundedRectangle(cornerRadius: Radius.campo).fill(Theme.superficieElevada))
                    .overlay(RoundedRectangle(cornerRadius: Radius.campo).strokeBorder(Theme.linha))
                    .onSubmit { if let first = filtered.first { open(first) } }
                ScrollView {
                    LazyVStack(spacing: Spacing.xs) {
                        if filtered.isEmpty {
                            Text(projects.projects.isEmpty ? "Nenhum projeto ainda. Abra uma pasta para começar." : "Nada encontrado para \"\(search)\".")
                                .typography(.secundario).foregroundStyle(Theme.textoSecundario)
                                .frame(maxWidth: .infinity).padding(Spacing.xxl)
                        }
                        ForEach(filtered) { project in
                            Button { open(project) } label: { ProjectPickerRow(project: project) }
                                .buttonStyle(.fridayLiveRow)
                                .contextMenu {
                                    Button("Mostrar no Finder") { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: project.path)]) }
                                    Button("Remover da lista", role: .destructive) { remove(project) }
                                }
                        }
                    }
                }
                if let errorMessage {
                    Text(errorMessage).typography(.metadado).foregroundStyle(Theme.erro)
                }
            }
            .frame(maxWidth: 620)
            .padding(.top, Spacing.xxl)
            .padding(.horizontal, Spacing.xxl)
            .padding(.bottom, Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Tela de passagem: a única onde o fundo se move (ver VISUAL.md, Movimento).
        .background(LiquidBackground())
        .onAppear { searchFocused = !projects.projects.isEmpty }
        .sheet(item: $sheet) { kind in
            switch kind {
            case .clone: CloneSheet(open: open)
            case .create: CreateFolderSheet(open: open)
            }
        }
    }

    private var filtered: [Project] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return projects.projects }
        return projects.projects.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.path.localizedCaseInsensitiveContains(query) }
    }

    private func pickFolder() {
        // O seletor do sistema bloqueia a tela: abre no próximo ciclo, para o brilho do clique já ter começado.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            choosePickedFolder()
        }
    }

    private func choosePickedFolder() {
        guard let url = FolderPanel.choose(prompt: "Abrir") else { return }
        do {
            open(try projects.add(path: url.path))
        } catch ProjectError.alreadyAdded {
            if let existing = projects.projects.first(where: { $0.path == Project.normalizedPath(url.path) }) { open(existing) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func remove(_ project: Project) {
        do { try projects.remove(project) } catch { errorMessage = error.localizedDescription }
    }
}

/// Linha de projeto na seleção: nome, caminho, quantos repositórios tem e quando foi aberto.
struct ProjectPickerRow: View {
    let project: Project
    @Environment(\.repositoryDiscoverer) private var discoverer
    @State private var repositoryCount: Int?
    @State private var hovering = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: project.kind.symbolName)
                .foregroundStyle(Theme.textoSecundario)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name).typography(.corpo).fontWeight(.semibold).foregroundStyle(Theme.texto)
                Text(project.path).typography(.metadado).foregroundStyle(Theme.textoSecundario).lineLimit(1).truncationMode(.head)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                MonoLabel(kindText)
                if let opened = project.lastOpenedAt {
                    MonoLabel(opened.formatted(.relative(presentation: .named)))
                }
            }
        }
        .padding(Spacing.md)
        .background(RoundedRectangle(cornerRadius: Radius.peca).fill(hovering ? Theme.superficieAtiva : Theme.superficie))
        .overlay(RoundedRectangle(cornerRadius: Radius.peca).strokeBorder(Theme.linha))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .task(id: project.path) {
            let path = project.path
            let discoverer = discoverer
            repositoryCount = await Task.detached { discoverer.repositories(inProjectAt: path).count }.value
        }
        .accessibilityElement(children: .combine)
    }

    private var kindText: String {
        if project.kind == .git { return "repositório git" }
        switch repositoryCount {
        case nil: return "pasta"
        case 0: return "pasta"
        case 1: return "pasta com 1 repositório"
        case let count?: return "pasta com \(count) repositórios"
        }
    }
}

/// Clonar: endereço do repositório e pasta onde salvar.
struct CloneSheet: View {
    @Environment(ProjectsModel.self) private var projects
    @Environment(\.dismiss) private var dismiss
    let open: (Project) -> Void
    @State private var url = ""
    @State private var parent = FolderPanel.defaultParent
    @State private var working = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            TextField("Endereço do repositório", text: $url, prompt: Text("https://github.com/dono/repo.git"))
            LabeledContent("Salvar em") {
                HStack {
                    Text(parent).monospaced().lineLimit(1).truncationMode(.head)
                    Button("Escolher…") { if let url = FolderPanel.choose(prompt: "Escolher") { parent = url.path } }
                }
            }
            if let errorMessage { Text(errorMessage).foregroundStyle(Theme.erro) }
        }
        .formStyle(.grouped)
        .frame(width: 520)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() }.disabled(working) }
            ToolbarItem(placement: .confirmationAction) {
                if working { ProgressView().controlSize(.small) } else {
                    Button("Clonar") { Task { await clone() } }.disabled(url.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func clone() async {
        working = true
        defer { working = false }
        do {
            let project = try await projects.clone(url, into: parent)
            dismiss()
            open(project)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// Criar pasta nova: nome, onde, e se já começa como repositório git.
struct CreateFolderSheet: View {
    @Environment(ProjectsModel.self) private var projects
    @Environment(\.dismiss) private var dismiss
    let open: (Project) -> Void
    @State private var name = ""
    @State private var parent = FolderPanel.defaultParent
    @State private var initializeGit = true
    @State private var errorMessage: String?

    var body: some View {
        Form {
            TextField("Nome da pasta", text: $name)
            LabeledContent("Dentro de") {
                HStack {
                    Text(parent).monospaced().lineLimit(1).truncationMode(.head)
                    Button("Escolher…") { if let url = FolderPanel.choose(prompt: "Escolher") { parent = url.path } }
                }
            }
            Toggle("Iniciar como repositório git (git init)", isOn: $initializeGit)
            if let errorMessage { Text(errorMessage).foregroundStyle(Theme.erro) }
        }
        .formStyle(.grouped)
        .frame(width: 520)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Criar") { Task { await create() } }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func create() async {
        do {
            let project = try await projects.createFolder(named: name, in: parent, initializeGit: initializeGit)
            dismiss()
            open(project)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// Seletor de pasta do sistema.
enum FolderPanel {
    /// Pasta inicial para clonar e criar: `~/Projetos` se existir, senão a pasta do usuário.
    static var defaultParent: String {
        let projects = (NSHomeDirectory() as NSString).appendingPathComponent("Projetos")
        return FileManager.default.fileExists(atPath: projects) ? projects : NSHomeDirectory()
    }

    @MainActor
    static func choose(prompt: String) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = prompt
        return panel.runModal() == .OK ? panel.url : nil
    }
}

extension EnvironmentValues {
    /// Quem descobre os repositórios de um projeto (injetado pelo app; testes e prévias usam o padrão).
    @Entry public var repositoryDiscoverer: any RepositoryDiscovering = EmptyRepositoryDiscoverer()
}

/// Descoberta vazia, para prévias.
struct EmptyRepositoryDiscoverer: RepositoryDiscovering {
    func repositories(inProjectAt path: String) -> [CodeRepository] { [] }
}

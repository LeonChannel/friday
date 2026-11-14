// Resumo: Janela principal: projetos na lateral, terminais do projeto no centro e, no inspetor, a linha do tempo da sessão ou os arquivos e o git.
// Tags: interface

import FridayDomain
import SwiftUI

/// Janela principal do Friday.
public struct RootView: View {
    @Environment(ProjectsModel.self) private var projects
    @Environment(WorkspaceModel.self) private var workspace
    @State private var selection: Project.ID?
    @State private var showsInspector = true
    @State private var inspectorTab = InspectorTab.session

    public init() {}

    public var body: some View {
        NavigationSplitView {
            ProjectsSidebar(selection: $selection)
        } detail: {
            ZStack {
                // Todo projeto visitado continua montado: desmontar o terminal mataria o processo.
                ForEach(workspace.visitedProjectIDs, id: \.self) { id in
                    if let model = workspace.terminals[id] {
                        TerminalArea(model: model)
                            .opacity(id == selection ? 1 : 0)
                            .allowsHitTesting(id == selection)
                    }
                }
                if selectedProject == nil {
                    ContentUnavailableView(
                        "Nenhum projeto selecionado",
                        systemImage: "folder",
                        description: Text("Adicione uma pasta na barra lateral para começar.")
                    )
                }
            }
            .navigationTitle(selectedProject?.name ?? "Friday")
            .navigationSubtitle(selectedProject?.path ?? "")
            .inspector(isPresented: $showsInspector) {
                VStack(spacing: 0) {
                    Picker("Painel", selection: $inspectorTab) {
                        ForEach(InspectorTab.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .padding(8)
                    Divider()
                    inspectorContent
                }
                .inspectorColumnWidth(min: 260, ideal: 320, max: 460)
            }
            .toolbar {
                ToolbarItem {
                    Button("Painel lateral", systemImage: "sidebar.trailing") { showsInspector.toggle() }
                        .keyboardShortcut("0", modifiers: [.command, .option])
                }
            }
        }
        .task { await projects.observe() }
        .onChange(of: selection, initial: true) {
            if let project = selectedProject { _ = workspace.terminals(for: project) }
        }
    }

    @ViewBuilder
    private var inspectorContent: some View {
        switch inspectorTab {
        case .session:
            if let session = selectedSession {
                SessionTimelineView(model: workspace.timeline(for: session)).id(session)
            } else {
                ContentUnavailableView("Nenhuma sessão", systemImage: "list.bullet.rectangle", description: Text("Abra o Claude Code para acompanhar a sessão aqui."))
            }
        case .files:
            if let project = selectedProject, let files = workspace.files(for: project) {
                VStack(spacing: 0) {
                    GitSummaryView(status: files.gitStatus)
                    Divider()
                    ProjectFilesView(model: files)
                }
                .id(project.id)
            } else {
                ContentUnavailableView("Nenhum projeto", systemImage: "folder", description: Text("Escolha um projeto na barra lateral."))
            }
        }
    }

    private var selectedProject: Project? {
        projects.projects.first { $0.id == selection }
    }

    private var selectedSession: AgentSessionID? {
        guard let id = selection ?? nil else { return nil }
        return workspace.terminals[id]?.selection
    }
}

enum InspectorTab: String, CaseIterable, Identifiable {
    case session, files
    var id: Self { self }
    var title: String {
        switch self {
        case .session: "Sessão"
        case .files: "Arquivos"
        }
    }
}

#if DEBUG
import FridayInfrastructure

@MainActor
private func previewModel(_ projects: [Project]) -> ProjectsModel {
    // SAFETY: só prévia; banco em memória não falha ao abrir.
    let repository = GRDBProjectRepository(database: try! AppDatabase.inMemory())
    for project in projects { _ = try? repository.insert(project) }
    return ProjectsModel(repository: repository, inspector: LocalFolderInspector())
}

@MainActor
private func previewWorkspace() -> WorkspaceModel {
    // SAFETY: só prévia; banco em memória não falha ao abrir.
    WorkspaceModel(planner: DefaultLaunchPlanner(), events: GRDBAgentEventRepository(database: try! AppDatabase.inMemory())) { project in
        ProjectFilesModel(rootPath: project.path, folderReader: LocalFolderReader(), gitReader: GitStatusReader(), watcher: FolderChangeWatcher())
    }
}

#Preview("Com projetos") {
    RootView()
        .environment(previewModel([
            Project(name: "friday", path: "/Users/exemplo/Projetos/friday", kind: .git, addedAt: .now),
            Project(name: "anotacoes", path: "/Users/exemplo/Documentos/anotacoes", kind: .folder, addedAt: .now),
        ]))
        .environment(previewWorkspace())
        .frame(width: 900, height: 560)
}

#Preview("Vazio") {
    RootView()
        .environment(previewModel([]))
        .environment(previewWorkspace())
        .frame(width: 900, height: 560)
}
#endif

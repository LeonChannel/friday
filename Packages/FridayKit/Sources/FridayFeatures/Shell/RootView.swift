// Resumo: Janela principal: barra lateral de projetos e, à direita, os terminais do projeto escolhido, com prévias de exemplo.
// Tags: interface

import FridayDomain
import SwiftUI

/// Janela principal do Friday.
public struct RootView: View {
    @Environment(ProjectsModel.self) private var projects
    @Environment(WorkspaceModel.self) private var workspace
    @State private var selection: Project.ID?

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
        }
        .task { await projects.observe() }
        .onChange(of: selection, initial: true) {
            if let project = selectedProject { _ = workspace.terminals(for: project) }
        }
    }

    private var selectedProject: Project? {
        projects.projects.first { $0.id == selection }
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

#Preview("Com projetos") {
    RootView()
        .environment(previewModel([
            Project(name: "friday", path: "/Users/exemplo/Projetos/friday", kind: .git, addedAt: .now),
            Project(name: "anotacoes", path: "/Users/exemplo/Documentos/anotacoes", kind: .folder, addedAt: .now),
        ]))
        .environment(WorkspaceModel(planner: DefaultLaunchPlanner()))
        .frame(width: 900, height: 560)
}

#Preview("Vazio") {
    RootView()
        .environment(previewModel([]))
        .environment(WorkspaceModel(planner: DefaultLaunchPlanner()))
        .frame(width: 900, height: 560)
}
#endif

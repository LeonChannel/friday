import FridayDomain
import SwiftUI

public struct RootView: View {
    @Environment(ProjectsModel.self) private var projects
    @State private var selection: Project.ID?

    public init() {}

    public var body: some View {
        NavigationSplitView {
            ProjectsSidebar(selection: $selection)
        } detail: {
            if let project = projects.projects.first(where: { $0.id == selection }) {
                ProjectDetail(project: project)
            } else {
                ContentUnavailableView(
                    "Nenhum projeto selecionado",
                    systemImage: "folder",
                    description: Text("Adicione uma pasta na barra lateral para começar.")
                )
            }
        }
        .task { await projects.observe() }
    }
}

struct ProjectDetail: View {
    let project: Project

    var body: some View {
        Form {
            LabeledContent("Caminho") {
                Text(project.path).monospaced().textSelection(.enabled)
            }
            LabeledContent("Tipo") {
                Label(project.kind.label, systemImage: project.kind.symbolName)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(project.name)
    }
}

#if DEBUG
import FridayInfrastructure

@MainActor
private func previewModel(_ projects: [Project]) -> ProjectsModel {
    // SAFETY: preview-only; an in-memory database cannot fail to open.
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
        .frame(width: 900, height: 560)
}

#Preview("Vazio") {
    RootView()
        .environment(previewModel([]))
        .frame(width: 900, height: 560)
}
#endif

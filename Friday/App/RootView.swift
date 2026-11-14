import SwiftUI

struct RootView: View {
    @Environment(ProjectStore.self) private var projects
    @State private var selection: Project.ID?

    var body: some View {
        NavigationSplitView {
            ProjectsSidebar(selection: $selection)
        } detail: {
            if let project = projects.all.first(where: { $0.id == selection }) {
                ProjectDetail(project: project)
            } else {
                ContentUnavailableView(
                    "Nenhum projeto selecionado",
                    systemImage: "folder",
                    description: Text("Adicione uma pasta na barra lateral para começar.")
                )
            }
        }
    }
}

struct ProjectDetail: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.name).font(.largeTitle.bold())
            Text(project.path).font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
            Label(project.isGitRepository ? "Repositório git" : "Pasta", systemImage: project.isGitRepository ? "arrow.triangle.branch" : "folder")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationTitle(project.name)
    }
}

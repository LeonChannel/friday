import AppKit
import SwiftUI

struct ProjectsSidebar: View {
    @Environment(ProjectStore.self) private var projects
    @Binding var selection: Project.ID?
    @State private var errorMessage: String?

    var body: some View {
        List(selection: $selection) {
            Section("Projetos") {
                ForEach(projects.all) { project in
                    Label(project.name, systemImage: project.isGitRepository ? "arrow.triangle.branch" : "folder")
                        .tag(project.id)
                        .contextMenu {
                            Button("Remover da lista", role: .destructive) { remove(project) }
                        }
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 240)
        .toolbar {
            ToolbarItem {
                Button("Adicionar projeto", systemImage: "plus", action: pickFolder)
            }
        }
        .alert("Não deu para adicionar", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Adicionar"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            selection = try projects.add(path: url.path).id
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func remove(_ project: Project) {
        do {
            if selection == project.id { selection = nil }
            try projects.remove(project.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

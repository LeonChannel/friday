// Resumo: Barra lateral com os projetos: escolher pasta para adicionar, remover pelo menu de contexto e mostrar erros.
// Tags: projetos, interface

import AppKit
import FridayDomain
import SwiftUI

struct ProjectsSidebar: View {
    @Environment(ProjectsModel.self) private var model
    @Binding var selection: Project.ID?
    @State private var errorMessage: String?

    var body: some View {
        List(selection: $selection) {
            Section("Projetos") {
                ForEach(model.projects) { project in
                    Label(project.name, systemImage: project.kind.symbolName)
                        .tag(project.id)
                        .contextMenu {
                            Button("Remover da lista", role: .destructive) { remove(project) }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 200, ideal: 240)
        .toolbar {
            ToolbarItem {
                Button("Adicionar projeto", systemImage: "plus", action: pickFolder)
            }
        }
        .alert("Não deu para continuar", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
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
            selection = try model.add(path: url.path).id
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func remove(_ project: Project) {
        do {
            if selection == project.id { selection = nil }
            try model.remove(project)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension ProjectKind {
    var symbolName: String {
        switch self {
        case .git: "arrow.triangle.branch"
        case .folder: "folder"
        }
    }

    var label: String {
        switch self {
        case .git: "Repositório git"
        case .folder: "Pasta"
        }
    }
}

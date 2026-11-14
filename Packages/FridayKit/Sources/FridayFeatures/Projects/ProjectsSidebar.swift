// Resumo: Barra lateral com os projetos: escolher pasta para adicionar, remover pelo menu de contexto e mostrar erros.
// Tags: projetos, interface

import AppKit
import FridayDomain
import SwiftUI

struct ProjectsSidebar: View {
    @Environment(ProjectsModel.self) private var model
    @Binding var selection: Int64?
    @State private var errorMessage: String?

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(model.projects) { project in
                    ProjectRow(project: project)
                        .tag(project.id)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: Radius.botao)
                                .fill(selection == project.id ? Theme.superficieAtiva : .clear)
                                .padding(.horizontal, Spacing.sm)
                        )
                        .listRowSeparator(.hidden)
                        .contextMenu {
                            Button("Remover da lista", role: .destructive) { remove(project) }
                        }
                }
            } header: {
                MonoLabel("Projetos", kind: .secao)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Theme.superficie)
        .safeAreaInset(edge: .top, spacing: 0) {
            FridayWordmark()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
        }
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

private struct ProjectRow: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(project.name)
                .typography(.corpo)
                .foregroundStyle(Theme.texto)
                .lineLimit(1)
            Text(project.path)
                .typography(.metadado)
                .foregroundStyle(Theme.textoSecundario)
                .lineLimit(1)
                .truncationMode(.head)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(project.name), \(project.kind.label)")
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

#if DEBUG
import FridayInfrastructure

@MainActor
private func previewModel() -> ProjectsModel {
    // SAFETY: só prévia; banco em memória não falha ao abrir.
    let repository = GRDBProjectRepository(database: try! AppDatabase.inMemory())
    _ = try? repository.insert(Project(name: "friday", path: "/Users/exemplo/Projetos/friday", kind: .git, addedAt: .now))
    _ = try? repository.insert(Project(name: "anotacoes", path: "/Users/exemplo/Documentos/anotacoes", kind: .folder, addedAt: .now))
    return ProjectsModel(repository: repository, inspector: LocalFolderInspector())
}

private struct SidebarPreview: View {
    @State private var model = previewModel()
    @State private var selection: Int64?

    var body: some View {
        ProjectsSidebar(selection: $selection)
            .environment(model)
            .task { await model.observe() }
            .frame(width: 240, height: 360)
    }
}

#Preview("Lateral, escuro") { SidebarPreview().preferredColorScheme(.dark) }
#Preview("Lateral, claro") { SidebarPreview().preferredColorScheme(.light) }
#endif

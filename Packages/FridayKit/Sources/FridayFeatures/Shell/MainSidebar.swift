// Resumo: Lateral da janela: marca, Mesa, Sua vez, os assuntos com a vez de cada um, os projetos e a legenda das três vezes.
// Tags: interface, assuntos, projetos

import AppKit
import FridayDomain
import SwiftUI

/// Lateral principal do Friday.
struct MainSidebar: View {
    @Environment(ProjectsModel.self) private var projects
    @Environment(SubjectsModel.self) private var subjects
    @Binding var selection: Destination?
    @State private var errorMessage: String?

    var body: some View {
        List(selection: $selection) {
            Section {
                row(.desk) { Text("Mesa").typography(.corpo) }
                row(.yourTurn) {
                    HStack {
                        Text("Sua vez").typography(.corpo)
                        Spacer()
                        let count = subjects.rows(for: .you).count
                        if count > 0 {
                            Text("\(count)").typography(.metadado).foregroundStyle(Theme.voceTexto)
                                .accessibilityLabel("\(count) esperando você")
                        }
                    }
                }
            }
            Section {
                if subjects.rows.isEmpty {
                    Text("Nenhum assunto ainda").typography(.secundario).foregroundStyle(Theme.textoSecundario)
                }
                ForEach(subjects.rows) { row in
                    if let id = row.subject.id {
                        self.row(.subject(id)) {
                            HStack(spacing: Spacing.sm) {
                                TurnDot(TurnStyle(row.turn.holder))
                                Text(row.subject.title).typography(.corpo).lineLimit(1)
                            }
                        }
                    }
                }
            } header: {
                MonoLabel("Assuntos", kind: .secao)
            }
            Section {
                ForEach(projects.projects) { project in
                    if let id = project.id {
                        row(.project(id)) { ProjectRow(project: project) }
                            .contextMenu {
                                Button("Remover da lista", role: .destructive) { remove(project) }
                            }
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
        .safeAreaInset(edge: .bottom, spacing: 0) { legend }
        .navigationSplitViewColumnWidth(min: 210, ideal: 250)
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

    private func row(_ destination: Destination, @ViewBuilder label: () -> some View) -> some View {
        label()
            .foregroundStyle(Theme.texto)
            .tag(destination)
            .listRowBackground(
                RoundedRectangle(cornerRadius: Radius.botao)
                    .fill(selection == destination ? Theme.superficieAtiva : .clear)
                    .padding(.horizontal, Spacing.sm)
            )
            .listRowSeparator(.hidden)
    }

    private var legend: some View {
        HStack(spacing: Spacing.md) {
            TurnBadge(.voce)
            TurnBadge(.claude)
            TurnBadge(.parado)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Rectangle().fill(Theme.linha).frame(height: 1) }
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Adicionar"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            if let id = try projects.add(path: url.path).id { selection = .project(id) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func remove(_ project: Project) {
        do {
            if let id = project.id, selection == .project(id) { selection = .desk }
            try projects.remove(project)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

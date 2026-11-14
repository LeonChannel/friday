// Resumo: Lateral do projeto aberto: troca de projeto no topo, Mesa, Sua vez, os assuntos do projeto e os repositórios com branch e alterados.
// Tags: interface, assuntos, projetos

import FridayDomain
import SwiftUI

/// Lateral principal, sempre dentro de um projeto.
struct MainSidebar: View {
    let project: Project
    @Environment(ProjectsModel.self) private var projects
    @Environment(SubjectsModel.self) private var subjects
    @Environment(WorkspaceModel.self) private var workspace
    @Binding var selection: Destination?
    let switchProject: (Project?) -> Void

    var body: some View {
        let repositories = workspace.repositories(for: project)
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
                if project.kind == .folder {
                    row(.folder(project.path)) {
                        HStack {
                            Text("Pasta do projeto").typography(.corpo)
                            Spacer()
                            MonoLabel("raiz")
                        }
                    }
                }
                ForEach(repositories.summaries) { summary in
                    row(.folder(summary.repository.path)) { RepositoryRow(summary: summary) }
                }
                if repositories.isLoading && repositories.summaries.isEmpty {
                    Text("Procurando repositórios…").typography(.secundario).foregroundStyle(Theme.textoSecundario)
                }
            } header: {
                MonoLabel(repositories.summaries.isEmpty ? "Repositórios" : "Repositórios · \(repositories.summaries.count)", kind: .secao)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Theme.superficie)
        .safeAreaInset(edge: .top, spacing: 0) { projectSwitcher }
        .safeAreaInset(edge: .bottom, spacing: 0) { legend }
        .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        .task(id: project.path) { await repositories.refresh() }
    }

    /// Topo da lateral: marca e o projeto aberto, com os recentes e a volta à seleção.
    private var projectSwitcher: some View {
        HStack(spacing: Spacing.sm) {
            FridayMark(size: 20)
            Menu {
                ForEach(projects.projects.filter { $0.id != project.id }.prefix(8)) { other in
                    Button(other.name) { switchProject(other) }
                }
                Divider()
                Button("Todos os projetos…") { switchProject(nil) }
                    .keyboardShortcut("o", modifiers: [.command, .shift])
            } label: {
                HStack(spacing: Spacing.xs) {
                    Text(project.name).typography(.corpo).fontWeight(.semibold).foregroundStyle(Theme.texto).lineLimit(1)
                    Image(systemName: "chevron.down").imageScale(.small).foregroundStyle(Theme.textoSecundario)
                }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Trocar de projeto (⌘⇧O)")
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
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
}

/// Repositório na lateral: nome, branch e quantos arquivos alterados.
struct RepositoryRow: View {
    let summary: RepositorySummary

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(summary.repository.name).typography(.corpo).lineLimit(1)
            Spacer()
            if let branch = summary.branch {
                MonoLabel(summary.changedFiles > 0 ? "\(branch) · \(summary.changedFiles)" : branch)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(summary.repository.name), branch \(summary.branch ?? "desconhecida"), \(summary.changedFiles) alterados")
    }
}

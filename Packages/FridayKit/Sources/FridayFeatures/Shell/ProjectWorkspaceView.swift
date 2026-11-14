// Resumo: Tela de um projeto: os terminais no centro e, no painel lateral, a linha do tempo da sessão ou os arquivos e o git.
// Tags: interface, terminal, linha-do-tempo, pastas

import FridayDomain
import SwiftUI

/// Um projeto aberto.
struct ProjectWorkspaceView: View {
    let project: Project
    @Environment(WorkspaceModel.self) private var workspace
    @State private var showsInspector = true
    @State private var inspectorTab = InspectorTab.session

    var body: some View {
        Group {
            if let terminals = workspace.terminals(for: project) {
                TerminalArea(model: terminals)
            }
        }
        .navigationTitle(project.name)
        .navigationSubtitle(project.path)
        .inspector(isPresented: $showsInspector) {
            VStack(spacing: 0) {
                Picker("Painel", selection: $inspectorTab) {
                    ForEach(InspectorTab.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(Spacing.sm)
                Rectangle().fill(Theme.linha).frame(height: 1)
                inspectorContent
            }
            .background(Theme.superficie)
            .inspectorColumnWidth(min: 260, ideal: 320, max: 460)
        }
        .toolbar {
            ToolbarItem {
                Button("Painel lateral", systemImage: "sidebar.trailing") { showsInspector.toggle() }
                    .keyboardShortcut("0", modifiers: [.command, .option])
            }
        }
    }

    @ViewBuilder
    private var inspectorContent: some View {
        switch inspectorTab {
        case .session:
            if let session = workspace.terminals[project.id ?? -1]?.selection {
                SessionTimelineView(model: workspace.timeline(for: session)).id(session)
            } else {
                placeholder("Abra o Claude Code para acompanhar a sessão aqui.")
            }
        case .files:
            if let files = workspace.files(for: project) {
                VStack(spacing: 0) {
                    GitSummaryView(status: files.gitStatus)
                    Rectangle().fill(Theme.linha).frame(height: 1)
                    ProjectFilesView(model: files)
                }
            }
        }
    }

    private func placeholder(_ text: String) -> some View {
        Text(text).typography(.secundario).foregroundStyle(Theme.textoSecundario)
            .multilineTextAlignment(.center).padding(Spacing.xxl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

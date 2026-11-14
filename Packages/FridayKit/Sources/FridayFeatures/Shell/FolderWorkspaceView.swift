// Resumo: Tela de uma pasta do projeto (a raiz ou um repositório): os terminais no centro e, no painel lateral, a linha do tempo ou os arquivos e o git.
// Tags: interface, terminal, linha-do-tempo, pastas

import FridayDomain
import SwiftUI

/// Uma pasta do projeto aberta. `folder` pode ser a raiz do projeto ou um repositório dentro dela.
struct FolderWorkspaceView: View {
    let folder: Project
    @Environment(WorkspaceModel.self) private var workspace
    @State private var showsInspector = true
    @State private var inspectorTab = InspectorTab.session

    var body: some View {
        Group {
            TerminalArea(model: workspace.terminals(for: folder))
        }
        .navigationTitle(folder.name)
        .navigationSubtitle(folder.path)
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
            if let session = workspace.terminals[folder.path]?.selection {
                SessionTimelineView(model: workspace.timeline(for: session)).id(session)
            } else {
                placeholder("Abra o Claude Code para acompanhar a sessão aqui.")
            }
        case .files:
            let files = workspace.files(for: folder)
            VStack(spacing: 0) {
                GitSummaryView(status: files.gitStatus)
                Rectangle().fill(Theme.linha).frame(height: 1)
                ProjectFilesView(model: files)
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

// Resumo: Área de terminais de um projeto: abas das sessões, botões para abrir shell, Claude Code e Codex, e prévias.
// Tags: terminal, interface

import FridayDomain
import OSLog
import SwiftUI

/// Abas de sessões com o terminal da selecionada. Todas as sessões ficam montadas para o processo sobreviver à troca de aba.
public struct TerminalArea: View {
    @Bindable var model: TerminalSessionsModel

    public init(model: TerminalSessionsModel) { self.model = model }

    public var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            ZStack {
                ForEach(model.sessions) { session in
                    TerminalSessionView(session: session) { code in
                        model.markExited(id: session.id, code: code)
                    }
                    .opacity(model.selection == session.id ? 1 : 0)
                    .allowsHitTesting(model.selection == session.id)
                }
                if model.sessions.isEmpty {
                    ContentUnavailableView(
                        "Nenhuma sessão aberta",
                        systemImage: "terminal",
                        description: Text("Abra um terminal, o Claude Code ou o Codex nesta pasta.")
                    )
                }
            }
        }
        .onAppear {
            Logger(subsystem: "com.leonchannel.friday", category: "terminal").info("Área de terminais montada para \(model.project.name, privacy: .public)")
        }
        .alert("Não foi possível abrir", isPresented: Binding(get: { model.openError != nil }, set: { if !$0 { model.dismissOpenError() } })) {
            Button("OK") { model.dismissOpenError() }
        } message: {
            Text(model.openError ?? "")
        }
    }

    private var tabBar: some View {
        HStack {
            Picker("Sessão", selection: $model.selection) {
                ForEach(model.sessions) { session in
                    Label(session.title, systemImage: symbol(for: session)).tag(Optional(session.id))
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .disabled(model.sessions.isEmpty)

            if let selected = model.selection {
                Button("Fechar sessão", systemImage: "xmark") { model.close(id: selected) }
                    .labelStyle(.iconOnly)
                    .help("Fecha a sessão e encerra o processo")
            }

            Spacer()

            ForEach(AgentKind.allCases, id: \.self) { agent in
                Button(agent.displayName, systemImage: agent.symbolName) { model.open(agent: agent) }
            }
        }
        .padding(8)
    }

    private func symbol(for session: TerminalSession) -> String {
        if case .exited = session.state { return "stop.circle" }
        return session.agent.symbolName
    }
}

extension AgentKind {
    var symbolName: String {
        switch self {
        case .shell: "terminal"
        case .claude: "sparkles"
        case .codex: "chevron.left.forwardslash.chevron.right"
        }
    }
}

#if DEBUG
import FridayInfrastructure

@MainActor
private func previewModel() -> TerminalSessionsModel {
    let project = Project(name: "tmp", path: NSTemporaryDirectory(), kind: .folder, addedAt: .now)
    let model = TerminalSessionsModel(project: project, planner: DefaultLaunchPlanner())
    model.open(agent: .shell)
    return model
}

#Preview("Com um terminal") {
    TerminalArea(model: previewModel()).frame(width: 760, height: 460)
}

#Preview("Vazio") {
    TerminalArea(model: TerminalSessionsModel(
        project: Project(name: "tmp", path: NSTemporaryDirectory(), kind: .folder, addedAt: .now),
        planner: DefaultLaunchPlanner()
    ))
    .frame(width: 760, height: 460)
}
#endif

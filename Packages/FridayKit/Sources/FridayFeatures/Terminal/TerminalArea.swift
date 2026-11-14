// Resumo: Área de terminais de um projeto: abas das sessões, botões para abrir shell, Claude Code e Codex, e prévias.
// Tags: terminal, interface

import FridayDomain
import OSLog
import SwiftUI

/// Abas de sessões com o terminal da selecionada. Todas as sessões ficam montadas para o processo sobreviver à troca de aba.
public struct TerminalArea: View {
    @Bindable var model: TerminalSessionsModel
    /// Variáveis extras das sessões abertas aqui (ex.: `FRIDAY_ASSUNTO` quando a área é a gaveta de um assunto).
    let sessionEnvironment: [String: String]

    public init(model: TerminalSessionsModel, sessionEnvironment: [String: String] = [:]) {
        self.model = model
        self.sessionEnvironment = sessionEnvironment
    }

    public var body: some View {
        VStack(spacing: 0) {
            tabBar
            Rectangle().fill(Theme.linha).frame(height: 1)
            ZStack {
                // Só a sessão escolhida fica na tela; as outras seguem rodando no registro do model.
                if let session = model.sessions.first(where: { $0.id == model.selection }) {
                    TerminalSessionView(session: session, model: model).id(session.id)
                }
                if model.sessions.isEmpty {
                    Text("Nenhuma sessão aberta. Abra um terminal, o Claude Code ou o Codex nesta pasta.")
                        .typography(.secundario)
                        .foregroundStyle(Theme.textoSecundario)
                        .multilineTextAlignment(.center)
                        .padding(Spacing.xxl)
                }
            }
        }
        .background(Theme.fundo)
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
        HStack(spacing: Spacing.sm) {
            ForEach(model.sessions) { session in
                SessionTab(
                    title: session.displayTitle,
                    isSelected: model.selection == session.id,
                    hasExited: isExited(session),
                    select: { model.selection = session.id },
                    close: { model.close(id: session.id) }
                )
            }

            Spacer()

            ForEach(AgentKind.allCases, id: \.self) { agent in
                Button(agent.displayName) { model.open(agent: agent, environment: sessionEnvironment) }
                    .buttonStyle(.friday)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Theme.superficie)
    }

    private func isExited(_ session: TerminalSession) -> Bool {
        if case .exited = session.state { return true }
        return false
    }
}

/// Aba de uma sessão: título, estado (encerrada é parado) e botão de fechar.
private struct SessionTab: View {
    let title: String
    let isSelected: Bool
    let hasExited: Bool
    let select: () -> Void
    let close: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Button(action: select) {
                HStack(spacing: Spacing.sm) {
                    if hasExited { TurnDot(.parado).accessibilityHidden(true) }
                    Text(title)
                        .typography(.secundario)
                        .foregroundStyle(isSelected ? Theme.texto : Theme.textoSecundario)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(hasExited ? "\(title), encerrada" : title)
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            if isSelected {
                Button(action: close) {
                    Text("×").typography(.metadado).foregroundStyle(Theme.textoSecundario)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Fechar sessão")
                .help("Fecha a sessão e encerra o processo")
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs + 2)
        .background(isSelected ? Theme.superficieAtiva : .clear, in: .rect(cornerRadius: Radius.botao))
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

#Preview("Com um terminal, escuro") {
    TerminalArea(model: previewModel()).frame(width: 760, height: 460).preferredColorScheme(.dark)
}

#Preview("Com um terminal, claro") {
    TerminalArea(model: previewModel()).frame(width: 760, height: 460).preferredColorScheme(.light)
}

#Preview("Vazio, escuro") {
    TerminalArea(model: TerminalSessionsModel(
        project: Project(name: "tmp", path: NSTemporaryDirectory(), kind: .folder, addedAt: .now),
        planner: DefaultLaunchPlanner()
    ))
    .frame(width: 760, height: 460)
    .preferredColorScheme(.dark)
}

#Preview("Vazio, claro") {
    TerminalArea(model: TerminalSessionsModel(
        project: Project(name: "tmp", path: NSTemporaryDirectory(), kind: .folder, addedAt: .now),
        planner: DefaultLaunchPlanner()
    ))
    .frame(width: 760, height: 460)
    .preferredColorScheme(.light)
}
#endif

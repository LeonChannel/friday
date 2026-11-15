// Resumo: Sessões de terminal abertas num projeto: abrir shell, Claude ou Codex, fechar, escolher a ativa e registrar o fim do processo.
// Tags: terminal, agentes, interface

import FridayDomain
import Foundation
import Observation
import SwiftTerm

/// Situação do processo de uma sessão.
public enum TerminalSessionState: Equatable, Sendable {
    case running
    /// `code` é nil quando o processo morreu por sinal.
    case exited(code: Int32?)
}

/// Uma aba de terminal: o programa, o título e a receita usada para iniciá-lo.
public struct TerminalSession: Identifiable, Equatable, Sendable {
    public let id: AgentSessionID
    public let agent: AgentKind
    /// Nome de fallback (agente, com número quando há repetidos).
    public let title: String
    /// Título que o programa definiu no terminal, quando definiu.
    public var programTitle: String?
    public let plan: LaunchPlan
    public var state: TerminalSessionState
    /// Assunto que abriu a sessão, quando foi o início de uma jornada.
    public var subjectID: Int64?

    /// O que a aba mostra: o título do programa ou, sem ele, o nome numerado do agente.
    public var displayTitle: String {
        let trimmed = programTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? title : trimmed
    }
}

/// Estado das sessões de terminal de um projeto. Quem mostra a sessão avisa o fim do processo por `markExited`.
@MainActor
@Observable
public final class TerminalSessionsModel {
    public private(set) var sessions: [TerminalSession] = []
    public var selection: AgentSessionID?
    /// Mensagem em português da última sessão que não abriu.
    public private(set) var openError: String?

    public let project: Project
    @ObservationIgnored private let views = TerminalViewRegistry()
    private let planner: any LaunchPlanning
    private let makeSessionID: @Sendable () -> AgentSessionID

    public init(project: Project, planner: any LaunchPlanning, makeSessionID: @escaping @Sendable () -> AgentSessionID = { AgentSessionID() }) {
        self.project = project
        self.planner = planner
        self.makeSessionID = makeSessionID
    }

    /// Abre uma sessão nova do programa, na pasta do projeto, e a deixa selecionada.
    @discardableResult
    public func open(
        agent: AgentKind, environment extra: [String: String] = [:], initialPrompt: String? = nil, subjectID: Int64? = nil
    ) -> TerminalSession? {
        let id = makeSessionID()
        do {
            var plan = try planner.plan(agent: agent, project: project, session: id, initialPrompt: initialPrompt)
            plan.environment.merge(extra) { _, new in new }
            let session = TerminalSession(id: id, agent: agent, title: title(for: agent), plan: plan, state: .running, subjectID: subjectID)
            sessions.append(session)
            selection = id
            openError = nil
            return session
        } catch {
            openError = "Não foi possível abrir \(agent.displayName): \(error.localizedDescription)"
            return nil
        }
    }

    /// Sessão do Claude aberta para o assunto que ainda está rodando, se houver.
    public func runningSession(forSubject subjectID: Int64) -> TerminalSession? {
        sessions.last { $0.subjectID == subjectID && $0.state == .running }
    }

    /// Remove a sessão da lista; a view que a mostra encerra o processo ao sair da tela.
    public func close(id: AgentSessionID) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        views.close(id)
        sessions.remove(at: index)
        if selection == id {
            selection = sessions.isEmpty ? nil : sessions[min(index, sessions.count - 1)].id
        }
    }

    /// Registra que o processo da sessão terminou. A aba continua até o usuário fechar.
    public func markExited(id: AgentSessionID, code: Int32?) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].state = .exited(code: code)
    }

    /// Guarda o título que o programa definiu; vazio volta ao nome do agente.
    public func setProgramTitle(id: AgentSessionID, title: String) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].programTitle = title
    }

    /// Some com o aviso de erro depois que o usuário o viu.
    public func dismissOpenError() { openError = nil }

    private func title(for agent: AgentKind) -> String {
        let sameKind = sessions.filter { $0.agent == agent }.count
        return sameKind == 0 ? agent.displayName : "\(agent.displayName) \(sameKind + 1)"
    }

    /// Inicia o processo da sessão sem mostrar o terminal (o bastidor de uma jornada).
    public func startInBackground(_ session: TerminalSession) {
        _ = terminalView(for: session)
    }

    /// View viva do terminal da sessão (criada e iniciada na primeira vez).
    func terminalView(for session: TerminalSession) -> LocalProcessTerminalView {
        views.view(for: session, onTitle: { [weak self] title in
            self?.setProgramTitle(id: session.id, title: title)
        }, onExit: { [weak self] code in
            self?.markExited(id: session.id, code: code)
        })
    }
}

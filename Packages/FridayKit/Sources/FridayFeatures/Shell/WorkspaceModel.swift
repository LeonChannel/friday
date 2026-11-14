// Resumo: Guarda as sessões de terminal de cada projeto aberto e a linha do tempo de cada sessão, para trocar de projeto sem perder nada.
// Tags: terminal, linha-do-tempo, interface

import FridayDomain
import Observation

/// Um `TerminalSessionsModel` por projeto, criado na primeira visita e mantido até o app fechar.
@MainActor
@Observable
public final class WorkspaceModel {
    public private(set) var terminals: [Int64: TerminalSessionsModel] = [:]
    private var timelines: [AgentSessionID: SessionTimelineModel] = [:]
    private let planner: any LaunchPlanning
    private let events: any AgentEventRepository

    public init(planner: any LaunchPlanning, events: any AgentEventRepository) {
        self.planner = planner
        self.events = events
    }

    /// Linha do tempo da sessão; a mesma instância a cada chamada.
    public func timeline(for session: AgentSessionID) -> SessionTimelineModel {
        if let existing = timelines[session] { return existing }
        let model = SessionTimelineModel(session: session, repository: events)
        timelines[session] = model
        return model
    }

    /// Sessões do projeto; cria o model na primeira chamada.
    public func terminals(for project: Project) -> TerminalSessionsModel? {
        guard let id = project.id else { return nil }
        if let existing = terminals[id] { return existing }
        let model = TerminalSessionsModel(project: project, planner: planner)
        terminals[id] = model
        return model
    }

    /// Projetos que já têm sessões abertas, para a janela manter os terminais montados.
    public var visitedProjectIDs: [Int64] { terminals.keys.sorted() }
}

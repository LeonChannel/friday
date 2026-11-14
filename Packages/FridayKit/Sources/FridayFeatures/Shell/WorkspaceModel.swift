// Resumo: Guarda as sessões de terminal de cada projeto aberto, para trocar de projeto sem matar o que está rodando.
// Tags: terminal, interface

import FridayDomain
import Observation

/// Um `TerminalSessionsModel` por projeto, criado na primeira visita e mantido até o app fechar.
@MainActor
@Observable
public final class WorkspaceModel {
    public private(set) var terminals: [Int64: TerminalSessionsModel] = [:]
    private let planner: any LaunchPlanning

    public init(planner: any LaunchPlanning) {
        self.planner = planner
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

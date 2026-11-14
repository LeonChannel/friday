// Resumo: Guarda por projeto as sessões de terminal, a árvore de arquivos e os assuntos abertos, para trocar de tela sem perder nada.
// Tags: terminal, linha-do-tempo, pastas, interface

import FridayDomain
import Observation

/// Um `TerminalSessionsModel` por projeto, criado na primeira visita e mantido até o app fechar.
@MainActor
@Observable
public final class WorkspaceModel {
    public private(set) var terminals: [Int64: TerminalSessionsModel] = [:]
    private var timelines: [AgentSessionID: SessionTimelineModel] = [:]
    private var files: [Int64: ProjectFilesModel] = [:]
    private var subjectModels: [Int64: SubjectModel] = [:]
    private let planner: any LaunchPlanning
    private let events: any AgentEventRepository
    private let makeFilesModel: @MainActor (Project) -> ProjectFilesModel
    private let subjects: any SubjectRepository

    public init(
        planner: any LaunchPlanning,
        events: any AgentEventRepository,
        subjects: any SubjectRepository,
        makeFilesModel: @escaping @MainActor (Project) -> ProjectFilesModel
    ) {
        self.planner = planner
        self.events = events
        self.subjects = subjects
        self.makeFilesModel = makeFilesModel
    }

    /// Model do assunto aberto; a mesma instância a cada chamada.
    public func subject(_ id: Int64) -> SubjectModel {
        if let existing = subjectModels[id] { return existing }
        let model = SubjectModel(id: id, repository: subjects)
        subjectModels[id] = model
        return model
    }

    /// Árvore de arquivos e git do projeto; a mesma instância a cada chamada.
    public func files(for project: Project) -> ProjectFilesModel? {
        guard let id = project.id else { return nil }
        if let existing = files[id] { return existing }
        let model = makeFilesModel(project)
        files[id] = model
        return model
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

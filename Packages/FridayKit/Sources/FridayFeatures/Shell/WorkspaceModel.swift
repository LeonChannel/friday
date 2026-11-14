// Resumo: Guarda por projeto as sessões de terminal, a árvore de arquivos e os assuntos abertos, para trocar de tela sem perder nada.
// Tags: terminal, linha-do-tempo, pastas, interface

import FridayDomain
import Observation

/// Um `TerminalSessionsModel` por projeto, criado na primeira visita e mantido até o app fechar.
@MainActor
@Observable
public final class WorkspaceModel {
    public private(set) var terminals: [String: TerminalSessionsModel] = [:]
    private var timelines: [AgentSessionID: SessionTimelineModel] = [:]
    private var files: [String: ProjectFilesModel] = [:]
    private var repositories: [String: ProjectRepositoriesModel] = [:]
    private var subjectModels: [Int64: SubjectModel] = [:]
    private let planner: any LaunchPlanning
    private let events: any AgentEventRepository
    private let makeFilesModel: @MainActor (Project) -> ProjectFilesModel
    private let makeRepositoriesModel: @MainActor (Project) -> ProjectRepositoriesModel
    private let subjects: any SubjectRepository

    public init(
        planner: any LaunchPlanning,
        events: any AgentEventRepository,
        subjects: any SubjectRepository,
        makeRepositoriesModel: @escaping @MainActor (Project) -> ProjectRepositoriesModel,
        makeFilesModel: @escaping @MainActor (Project) -> ProjectFilesModel
    ) {
        self.planner = planner
        self.events = events
        self.subjects = subjects
        self.makeRepositoriesModel = makeRepositoriesModel
        self.makeFilesModel = makeFilesModel
    }

    /// Repositórios do projeto; a mesma instância a cada chamada.
    public func repositories(for project: Project) -> ProjectRepositoriesModel {
        if let existing = repositories[project.path] { return existing }
        let model = makeRepositoriesModel(project)
        repositories[project.path] = model
        return model
    }

    /// Model do assunto aberto; a mesma instância a cada chamada.
    public func subject(_ id: Int64) -> SubjectModel {
        if let existing = subjectModels[id] { return existing }
        let model = SubjectModel(id: id, repository: subjects)
        subjectModels[id] = model
        return model
    }

    /// Árvore de arquivos e git do projeto; a mesma instância a cada chamada.
    /// Árvore de arquivos e git da pasta (projeto ou repositório), pela pasta.
    public func files(for project: Project) -> ProjectFilesModel {
        if let existing = files[project.path] { return existing }
        let model = makeFilesModel(project)
        files[project.path] = model
        return model
    }

    /// Linha do tempo da sessão; a mesma instância a cada chamada.
    public func timeline(for session: AgentSessionID) -> SessionTimelineModel {
        if let existing = timelines[session] { return existing }
        let model = SessionTimelineModel(session: session, repository: events)
        timelines[session] = model
        return model
    }

    /// Sessões de terminal da pasta (projeto ou repositório); cria na primeira chamada.
    public func terminals(for project: Project) -> TerminalSessionsModel {
        if let existing = terminals[project.path] { return existing }
        let model = TerminalSessionsModel(project: project, planner: planner)
        terminals[project.path] = model
        return model
    }
}

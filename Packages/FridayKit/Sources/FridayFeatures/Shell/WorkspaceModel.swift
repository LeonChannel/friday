// Resumo: Guarda por projeto as sessões de terminal, a árvore de arquivos, a memória, o backlog e os assuntos abertos, e inicia a jornada de um assunto no bastidor.
// Tags: terminal, linha-do-tempo, pastas, interface, memoria, backlog, jornadas

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
    private var memoryModels: [String: MemoryModel] = [:]
    private var backlogModels: [String: BacklogModel] = [:]
    private let backlog: (any BacklogRepository)?
    private let makeMemoryModel: (@MainActor (Project) -> MemoryModel)?
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
        makeFilesModel: @escaping @MainActor (Project) -> ProjectFilesModel,
        makeMemoryModel: (@MainActor (Project) -> MemoryModel)? = nil,
        backlog: (any BacklogRepository)? = nil
    ) {
        self.backlog = backlog
        self.makeMemoryModel = makeMemoryModel
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

    /// Memória do projeto; a mesma instância a cada chamada. `nil` quando o app não montou a memória (prévias).
    public func memory(for project: Project) -> MemoryModel? {
        if let existing = memoryModels[project.path] { return existing }
        guard let model = makeMemoryModel?(project) else { return nil }
        memoryModels[project.path] = model
        return model
    }

    /// Backlog do projeto; a mesma instância a cada chamada. `nil` quando o app não montou o backlog (prévias) ou o projeto não foi gravado.
    public func backlog(for project: Project) -> BacklogModel? {
        if let existing = backlogModels[project.path] { return existing }
        guard let backlog, project.id != nil else { return nil }
        let model = BacklogModel(project: project, repository: backlog)
        backlogModels[project.path] = model
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

    /// Abre o Claude no bastidor do projeto com o briefing da jornada como primeira mensagem.
    /// Devolve a mensagem de erro em português quando a sessão não abre.
    @discardableResult
    public func startJourney(subject: Subject, journey: Journey, project: Project) -> String? {
        guard let id = subject.id else { return "O assunto ainda não foi gravado." }
        let terminals = terminals(for: project)
        guard let session = terminals.open(
            agent: .claude, environment: ["FRIDAY_ASSUNTO": "\(id)"],
            initialPrompt: JourneyBriefing.text(subject: subject, journey: journey), subjectID: id
        ) else { return terminals.openError }
        terminals.startInBackground(session)
        return nil
    }
}

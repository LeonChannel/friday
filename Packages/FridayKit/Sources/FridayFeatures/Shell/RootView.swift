// Resumo: Janela principal: a seleção de projetos ou o workspace do projeto aberto, com o movimento de cada troca pela hierarquia (mergulho, deslize lateral, rolagem do conteúdo).
// Tags: interface

import FridayDomain
import SwiftUI

/// Janela principal do Friday: sem projeto aberto, a seleção de projetos; com projeto, a área de trabalho dele.
public struct RootView: View {
    @Environment(ProjectsModel.self) private var projects
    @Environment(SubjectsModel.self) private var subjects
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(UsageQuotaModel.self) private var usage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Destino escolhido em cada projeto: o projeto que sai deslizando continua mostrando a tela dele.
    @State private var selections: [Int: Destination] = [:]
    @State private var showsSplash = true
    /// Projeto aberto (0 = nenhum). Guardado entre aberturas do app e lido também pelo menu do app.
    @AppStorage("activeProjectID") private var activeProjectID = 0
    @AppStorage("destination") private var storedDestination = Destination.desk.storageKey

    public init() {}

    public var body: some View {
        MotionStack(key: activeProjectID, movement: { from, to in
            let move = ProjectMove.between(from: from, to: to)
            return (move.motion(reduceMotion: reduceMotion), move.animation(reduceMotion: reduceMotion))
        }) { shown in
            if shown != 0 {
                if let project = projects.projects.first(where: { $0.id == Int64(shown) }) {
                    ProjectWorkspace(
                        project: project,
                        selection: selectionBinding(shown),
                        switchProject: { other in if let other { open(other) } else { activeProjectID = 0 } }
                    )
                } else {
                    // Projeto recém-adicionado ainda chegando do banco: fundo liso em vez de piscar a seleção.
                    Theme.fundo
                }
            } else {
                ProjectPickerView(open: open)
            }
        }
        .overlay {
            if showsSplash {
                LaunchSplash { showsSplash = false }
            }
        }
        .task { await projects.observe() }
        .task { await subjects.observe() }
        .task { await usage.observe() }
        .onChange(of: activeProjectID, initial: true) { subjects.projectScope = activeProject?.id }
        .onChange(of: projects.projects) { subjects.projectScope = activeProject?.id }
    }

    private func selectionBinding(_ project: Int) -> Binding<Destination?> {
        Binding(
            get: { selections[project] ?? (project == activeProjectID ? Destination(storageKey: storedDestination) : nil) ?? .desk },
            set: { new in
                selections[project] = new ?? .desk
                if project == activeProjectID { storedDestination = (new ?? .desk).storageKey }
            }
        )
    }

    private var activeProject: Project? {
        guard activeProjectID != 0 else { return nil }
        return projects.projects.first { $0.id == Int64(activeProjectID) }
    }

    private func open(_ project: Project) {
        guard let id = project.id else { return }
        try? projects.markOpened(project)
        if Int64(activeProjectID) != id {
            selections[Int(id)] = .desk
            storedDestination = Destination.desk.storageKey
        }
        activeProjectID = Int(id)
    }
}

/// O workspace de um projeto: a lateral fica parada e o conteúdo rola na vertical, no sentido da lateral, ao trocar de tela.
struct ProjectWorkspace: View {
    let project: Project
    @Binding var selection: Destination?
    let switchProject: (Project?) -> Void
    @Environment(SubjectsModel.self) private var subjects
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationSplitView {
            MainSidebar(project: project, selection: $selection, switchProject: switchProject)
        } detail: {
            MotionStack(key: selection ?? .desk, clips: true, movement: { from, to in
                if reduceMotion { return (.fade, .easeInOut(duration: 0.2)) }
                let subjectIDs = subjects.rows.compactMap(\.subject.id)
                let folders = workspace.repositories(for: project).summaries.map(\.repository.path)
                let edge = SidebarOrder.entryEdge(
                    from: SidebarOrder.rank(of: from, subjects: subjectIDs, projectPath: project.path, folders: folders),
                    to: SidebarOrder.rank(of: to, subjects: subjectIDs, projectPath: project.path, folders: folders)
                )
                return (.slide(edge), .spring(duration: 0.42, bounce: 0))
            }) { destination in
                detail(destination).background(Theme.fundo)
            }
            .background(Theme.fundo)
        }
    }

    @ViewBuilder
    private func detail(_ destination: Destination) -> some View {
        switch destination {
        case .desk:
            MesaView(project: project, open: { selection = .subject($0) })
        case .yourTurn:
            YourTurnView(open: { selection = .subject($0) })
        case .memory:
            if let memory = workspace.memory(for: project) {
                MemoryView(model: memory, repositories: workspace.repositories(for: project).summaries.map(\.repository))
            } else {
                Text("Memória indisponível nesta janela.").typography(.secundario).foregroundStyle(Theme.textoSecundario)
            }
        case .backlog:
            if let backlog = workspace.backlog(for: project) {
                BacklogView(model: backlog)
            } else {
                Text("Backlog indisponível nesta janela.").typography(.secundario).foregroundStyle(Theme.textoSecundario)
            }
        case .bugs:
            if let backlog = workspace.backlog(for: project) {
                BugBoardView(model: backlog)
            } else {
                Text("Quadro de bugs indisponível nesta janela.").typography(.secundario).foregroundStyle(Theme.textoSecundario)
            }
        case .subject(let id):
            SubjectView(model: workspace.subject(id))
        case .folder(let path):
            FolderWorkspaceView(folder: folderProject(path))
        }
    }

    /// A raiz é o próprio projeto; um repositório vira uma pasta de trabalho com o nome dele.
    private func folderProject(_ path: String) -> Project {
        if path == project.path { return project }
        return Project(name: (path as NSString).lastPathComponent, path: path, kind: .git, addedAt: project.addedAt)
    }
}

#if DEBUG
import FridayInfrastructure

@MainActor
private struct PreviewEnvironment {
    let projects: ProjectsModel
    let subjects: SubjectsModel
    let workspace: WorkspaceModel

    init() {
        // SAFETY: só prévia; banco em memória não falha ao abrir.
        let database = try! AppDatabase.inMemory()
        let projectRepository = GRDBProjectRepository(database: database)
        _ = try? projectRepository.insert(Project(name: "friday", path: "/Users/exemplo/Projetos/friday", kind: .git, addedAt: .now))
        let subjectRepository = GRDBSubjectRepository(database: database)
        if var subject = try? Subject(title: "Reduzir o custo da fila de imagens", intent: "cortar 30% do custo mensal sem aumentar o tempo de processamento", createdAt: .now) {
            _ = try? subject.addEvidence(fact: "redimensionamento responde por 48% do custo", source: "relatório de faturamento", grade: .measured, at: .now)
            _ = try? subject.addQuestion(text: "Liberar acesso às métricas de produção?", options: [
                QuestionOption(label: "Liberar", consequence: "medição exata em 1 dia"),
                QuestionOption(label: "Estimar pelos logs", consequence: "sem acesso novo, margem de erro maior"),
            ], waitsForYou: true, at: .now)
            _ = try? subjectRepository.insert(subject)
        }
        _ = try? subjectRepository.insert(try! Subject(title: "Avaliar troca do banco de buscas", createdAt: .now))
        projects = ProjectsModel(repository: projectRepository, inspector: LocalFolderInspector())
        subjects = SubjectsModel(repository: subjectRepository)
        workspace = WorkspaceModel(
            planner: DefaultLaunchPlanner(), events: GRDBAgentEventRepository(database: database), subjects: subjectRepository,
            makeRepositoriesModel: { ProjectRepositoriesModel(projectPath: $0.path, discoverer: LocalRepositoryDiscoverer(), gitReader: GitStatusReader()) },
            makeFilesModel: { ProjectFilesModel(rootPath: $0.path, folderReader: LocalFolderReader(), gitReader: GitStatusReader(), watcher: FolderChangeWatcher()) },
            backlog: GRDBBacklogRepository(database: database)
        )
    }
}

#Preview("Mesa, escuro") {
    let environment = PreviewEnvironment()
    RootView()
        .environment(environment.projects)
        .environment(environment.subjects)
        .environment(environment.workspace)
        .environment(UsageQuotaModel(repository: nil))
        .frame(width: 1100, height: 680)
        .preferredColorScheme(.dark)
}

#Preview("Mesa, claro") {
    let environment = PreviewEnvironment()
    RootView()
        .environment(environment.projects)
        .environment(environment.subjects)
        .environment(environment.workspace)
        .environment(UsageQuotaModel(repository: nil))
        .frame(width: 1100, height: 680)
        .preferredColorScheme(.light)
}
#endif

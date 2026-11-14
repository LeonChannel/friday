// Resumo: Janela principal: a lateral escolhe o destino (Mesa, Sua vez, um assunto ou um projeto) e a área de trabalho mostra a tela dele.
// Tags: interface

import FridayDomain
import SwiftUI

/// Janela principal do Friday.
public struct RootView: View {
    @Environment(ProjectsModel.self) private var projects
    @Environment(SubjectsModel.self) private var subjects
    @Environment(WorkspaceModel.self) private var workspace
    @State private var selection: Destination?
    @AppStorage("destination") private var storedDestination = Destination.desk.storageKey

    public init() {}

    public var body: some View {
        NavigationSplitView {
            MainSidebar(selection: $selection)
        } detail: {
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.fundo)
        }
        .task { await projects.observe() }
        .task { await subjects.observe() }
        .onAppear { if selection == nil { selection = Destination(storageKey: storedDestination) ?? .desk } }
        .onChange(of: selection) { storedDestination = (selection ?? .desk).storageKey }
    }

    @ViewBuilder
    private var detail: some View {
        switch selection ?? .desk {
        case .desk:
            MesaView(open: open)
        case .yourTurn:
            YourTurnView(open: open)
        case .subject(let id):
            SubjectView(model: workspace.subject(id)).id(id)
        case .project(let id):
            if let project = projects.projects.first(where: { $0.id == id }) {
                ProjectWorkspaceView(project: project).id(id)
            } else {
                Text("Carregando o projeto…").typography(.secundario).foregroundStyle(Theme.textoSecundario)
            }
        }
    }

    private func open(_ subject: Int64) {
        selection = .subject(subject)
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
        workspace = WorkspaceModel(planner: DefaultLaunchPlanner(), events: GRDBAgentEventRepository(database: database), subjects: subjectRepository) { project in
            ProjectFilesModel(rootPath: project.path, folderReader: LocalFolderReader(), gitReader: GitStatusReader(), watcher: FolderChangeWatcher())
        }
    }
}

#Preview("Mesa, escuro") {
    let environment = PreviewEnvironment()
    RootView()
        .environment(environment.projects)
        .environment(environment.subjects)
        .environment(environment.workspace)
        .frame(width: 1100, height: 680)
        .preferredColorScheme(.dark)
}

#Preview("Mesa, claro") {
    let environment = PreviewEnvironment()
    RootView()
        .environment(environment.projects)
        .environment(environment.subjects)
        .environment(environment.workspace)
        .frame(width: 1100, height: 680)
        .preferredColorScheme(.light)
}
#endif

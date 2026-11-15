// Resumo: Ponto de entrada do app: abre o banco, liga o sensor de hooks, a memória, o backlog e o catálogo de skills das jornadas e monta as dependências reais.
// Tags: composicao

import FridayDomain
import FridayFeatures
import FridayInfrastructure
import OSLog
import SwiftUI

struct FridayApp: App {
    @State private var projects: ProjectsModel
    @State private var workspace: WorkspaceModel
    @State private var subjects: SubjectsModel
    @State private var settings: AppSettings
    @State private var usage: UsageQuotaModel
    private let sensor: SensorService?

    init() {
        let database: AppDatabase
        do {
            database = try AppDatabase.live()
        } catch {
            fatalError("Não consegui abrir o banco do Friday: \(error)")
        }
        let events = GRDBAgentEventRepository(database: database)
        let quotas = GRDBUsageQuotaRepository(database: database)
        _usage = State(initialValue: UsageQuotaModel(repository: quotas))
        let settings = AppSettings()
        _settings = State(initialValue: settings)

        // Sem sensor o terminal ainda funciona; só a linha do tempo fica vazia.
        var hooks: (any AgentLaunchCustomizing)?
        var sensor: SensorService?
        do {
            let locations = try SensorLocations.live()
            hooks = CompositeLaunchCustomizer([
                FridayToolsCustomizer.bundled(),
                // Vault lido a cada sessão nova: trocar a pasta vale sem reabrir o app.
                MemoryLaunchCustomizer(vaultPath: VaultPreference.reader()),
                ClaudeSessionHooks(locations: locations),
                // Codex só com a preferência ligada; lida a cada sessão nova.
                CodexSessionHooks(locations: locations, isEnabled: AppSettings.codexTimelineReader()),
            ])
            sensor = SensorService(server: HookSocketServer(socketPath: locations.socketPath), repository: events, quotas: quotas)
        } catch {
            Logger(subsystem: "com.leonchannel.friday", category: "sensor").error("Sensor desligado: \(error.localizedDescription, privacy: .public)")
        }
        self.sensor = sensor
        if let sensor {
            Task {
                do { try await sensor.start() } catch {
                    Logger(subsystem: "com.leonchannel.friday", category: "sensor").error("Sensor não iniciou: \(error.localizedDescription, privacy: .public)")
                }
            }
        }

        let projectRepository = GRDBProjectRepository(database: database)
        _projects = State(initialValue: ProjectsModel(
            repository: projectRepository, inspector: LocalFolderInspector(), creator: GitProjectCreator()
        ))
        let subjectRepository = GRDBSubjectRepository(database: database)
        _subjects = State(initialValue: SubjectsModel(repository: subjectRepository))
        _workspace = State(initialValue: WorkspaceModel(planner: DefaultLaunchPlanner(customizer: hooks), events: events, subjects: subjectRepository,
            makeRepositoriesModel: { ProjectRepositoriesModel(projectPath: $0.path, discoverer: LocalRepositoryDiscoverer(), gitReader: GitStatusReader()) },
            makeFilesModel: { ProjectFilesModel(rootPath: $0.path, folderReader: LocalFolderReader(), gitReader: GitStatusReader(), watcher: FolderChangeWatcher()) },
            makeMemoryModel: { MemoryModel(project: $0, settings: settings, makeVault: { FileMemoryVault(rootPath: $0) }, watcher: FolderChangeWatcher()) },
            backlog: MirroredBacklogRepository(inner: GRDBBacklogRepository(database: database), mirror: BacklogMirror(
                vaultRoot: VaultPreference.reader(),
                projectName: { id in (try? projectRepository.all())?.first { $0.id == id }?.name }
            ))
        ))
    }

    var body: some Scene {
        WindowGroup("Friday") {
            RootView()
                .environment(projects)
                .environment(workspace)
                .environment(subjects)
                .environment(settings)
                .environment(usage)
                .environment(\.repositoryDiscoverer, LocalRepositoryDiscoverer())
                .frame(minWidth: 1000, minHeight: 600)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Trocar de projeto…") { UserDefaults.standard.set(0, forKey: "activeProjectID") }
                    .keyboardShortcut("o", modifiers: [.command, .shift])
            }
        }
        Settings {
            SettingsView(settings: settings, skills: ClaudeSkillCatalog())
        }
    }
}

// Resumo: Ponto de entrada do app: abre o banco, liga o sensor de hooks e monta as dependências reais de cada funcionalidade.
// Tags: composicao

import FridayDomain
import FridayFeatures
import FridayInfrastructure
import OSLog
import SwiftUI

struct FridayApp: App {
    @State private var projects: ProjectsModel
    @State private var workspace: WorkspaceModel
    @State private var settings = AppSettings()
    private let sensor: SensorService?

    init() {
        let database: AppDatabase
        do {
            database = try AppDatabase.live()
        } catch {
            fatalError("Não consegui abrir o banco do Friday: \(error)")
        }
        let events = GRDBAgentEventRepository(database: database)

        // Sem sensor o terminal ainda funciona; só a linha do tempo fica vazia.
        var hooks: (any AgentLaunchCustomizing)?
        var sensor: SensorService?
        do {
            let locations = try SensorLocations.live()
            hooks = CompositeLaunchCustomizer([
                FridayToolsCustomizer.bundled(),
                ClaudeSessionHooks(locations: locations),
                // Codex só com a preferência ligada; lida a cada sessão nova.
                CodexSessionHooks(locations: locations, isEnabled: AppSettings.codexTimelineReader()),
            ])
            sensor = SensorService(server: HookSocketServer(socketPath: locations.socketPath), repository: events)
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

        _projects = State(initialValue: ProjectsModel(repository: GRDBProjectRepository(database: database), inspector: LocalFolderInspector()))
        _workspace = State(initialValue: WorkspaceModel(planner: DefaultLaunchPlanner(customizer: hooks), events: events) { project in
            ProjectFilesModel(rootPath: project.path, folderReader: LocalFolderReader(), gitReader: GitStatusReader(), watcher: FolderChangeWatcher())
        })
    }

    var body: some Scene {
        WindowGroup("Friday") {
            RootView()
                .environment(projects)
                .environment(workspace)
                .frame(minWidth: 1000, minHeight: 600)
        }
        Settings {
            SettingsView(settings: settings)
        }
    }
}

import FridayFeatures
import FridayInfrastructure
import SwiftUI

@main
struct FridayApp: App {
    @State private var projects: ProjectsModel

    init() {
        let database: AppDatabase
        do {
            database = try AppDatabase.live()
        } catch {
            fatalError("Não consegui abrir o banco do Friday: \(error)")
        }
        _projects = State(initialValue: ProjectsModel(
            repository: GRDBProjectRepository(database: database),
            inspector: LocalFolderInspector()
        ))
    }

    var body: some Scene {
        WindowGroup("Friday") {
            RootView()
                .environment(projects)
                .frame(minWidth: 900, minHeight: 560)
        }
    }
}

// Resumo: Ponto de entrada do comando `friday`, usado pelo executável próprio e pelo app quando chamado em modo de linha de comando.
// Tags: assuntos, memoria, backlog, persistencia

import FridayInfrastructure
import Foundation

/// Roda um comando `friday` completo e encerra o processo com o código de saída.
public enum FridayCommand {
    /// Abre o banco (o do app, ou o de `FRIDAY_DB`), executa, avisa o app se algo foi gravado e sai.
    public static func main(_ arguments: [String]) -> Never {
        let environment = ProcessInfo.processInfo.environment
        do {
            let database: AppDatabase
            if let path = environment["FRIDAY_DB"], !path.isEmpty {
                database = try AppDatabase.open(path: path)
            } else {
                database = try AppDatabase.live()
            }
            let subjects = GRDBSubjectRepository(database: database)
            let outcome: CommandOutcome
            if arguments.first == "memoria" {
                outcome = memoryRunner(database: database, subjects: subjects, environment: environment)
                    .run(Array(arguments.dropFirst()), input: { FileHandle.standardInput.readDataToEndOfFile() })
            } else if arguments.first == "bug" || arguments.first == "item" {
                outcome = backlogRunner(database: database, environment: environment)
                    .run(arguments, input: { FileHandle.standardInput.readDataToEndOfFile() })
                if outcome.wrote { SubjectChangeSignal.post() }
            } else {
                outcome = SubjectCommandRunner(repository: subjects).run(arguments)
                if outcome.wrote { SubjectChangeSignal.post() }
            }
            FileHandle.standardOutput.write(Data(outcome.output.utf8))
            FileHandle.standardError.write(Data(outcome.errorOutput.utf8))
            exit(outcome.exitCode)
        } catch {
            // O hook nunca derruba o agente, nem com o banco fora do ar.
            if arguments.starts(with: ["memoria", "hook"]) || arguments.starts(with: ["item", "hook"]) { exit(0) }
            FileHandle.standardError.write(Data("Não consegui abrir o banco: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }

    private static func backlogRunner(database: AppDatabase, environment: [String: String]) -> BacklogCommandRunner {
        let projects = GRDBProjectRepository(database: database)
        let mirror = BacklogMirror(
            vaultRoot: { VaultPreference.resolve(environment: environment, preference: VaultPreference.reader()) },
            projectName: { id in (try? projects.all())?.first { $0.id == id }?.name }
        )
        return BacklogCommandRunner(
            repository: MirroredBacklogRepository(inner: GRDBBacklogRepository(database: database), mirror: mirror),
            projects: { try projects.all() },
            currentDirectory: FileManager.default.currentDirectoryPath,
            environment: environment
        )
    }

    private static func memoryRunner(database: AppDatabase, subjects: GRDBSubjectRepository, environment: [String: String]) -> MemoryCommandRunner {
        let projects = GRDBProjectRepository(database: database)
        let vaultPath = VaultPreference.resolve(environment: environment, preference: VaultPreference.reader())
        return MemoryCommandRunner(
            vault: vaultPath.map { FileMemoryVault(rootPath: $0) },
            projects: { try projects.all() },
            subjects: subjects,
            environment: environment,
            currentDirectory: FileManager.default.currentDirectoryPath,
            ledgerDirectory: FileManager.default.temporaryDirectory.appendingPathComponent("friday-memoria", isDirectory: true)
        )
    }
}

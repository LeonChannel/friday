// Resumo: Ponto de entrada do comando `friday`: abre o banco (o do app, ou o de FRIDAY_DB), roda o comando e avisa o app se algo foi gravado.
// Tags: assuntos, persistencia

import FridayCLI
import FridayInfrastructure
import Foundation

do {
    let database: AppDatabase
    if let path = ProcessInfo.processInfo.environment["FRIDAY_DB"], !path.isEmpty {
        database = try AppDatabase.open(path: path)
    } else {
        database = try AppDatabase.live()
    }
    let outcome = SubjectCommandRunner(repository: GRDBSubjectRepository(database: database)).run(Array(CommandLine.arguments.dropFirst()))
    FileHandle.standardOutput.write(Data(outcome.output.utf8))
    FileHandle.standardError.write(Data(outcome.errorOutput.utf8))
    if outcome.wrote { SubjectChangeSignal.post() }
    exit(outcome.exitCode)
} catch {
    FileHandle.standardError.write(Data("Não consegui abrir o banco: \(error.localizedDescription)\n".utf8))
    exit(1)
}

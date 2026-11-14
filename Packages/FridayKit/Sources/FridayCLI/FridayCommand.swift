// Resumo: Ponto de entrada do comando `friday`, usado pelo executável próprio e pelo app quando chamado em modo de linha de comando.
// Tags: assuntos, persistencia

import FridayInfrastructure
import Foundation

/// Roda um comando `friday` completo e encerra o processo com o código de saída.
public enum FridayCommand {
    /// Abre o banco (o do app, ou o de `FRIDAY_DB`), executa, avisa o app se algo foi gravado e sai.
    public static func main(_ arguments: [String]) -> Never {
        do {
            let database: AppDatabase
            if let path = ProcessInfo.processInfo.environment["FRIDAY_DB"], !path.isEmpty {
                database = try AppDatabase.open(path: path)
            } else {
                database = try AppDatabase.live()
            }
            let outcome = SubjectCommandRunner(repository: GRDBSubjectRepository(database: database)).run(arguments)
            FileHandle.standardOutput.write(Data(outcome.output.utf8))
            FileHandle.standardError.write(Data(outcome.errorOutput.utf8))
            if outcome.wrote { SubjectChangeSignal.post() }
            exit(outcome.exitCode)
        } catch {
            FileHandle.standardError.write(Data("Não consegui abrir o banco: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }
}

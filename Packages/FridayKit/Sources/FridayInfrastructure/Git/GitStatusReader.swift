// Resumo: Pergunta ao git o status de um projeto e devolve "sem git" quando a pasta não é repositório.
// Tags: git

import FridayDomain
import Foundation

/// Falhas de leitura do git que o usuário pode ver.
public enum GitStatusError: LocalizedError, Equatable {
    case commandFailed(String)

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let detail): "Não deu para ler o git deste projeto: \(detail)"
        }
    }
}

/// Roda `git status` pelo `CommandRunning` injetado.
///
/// Usa `/usr/bin/git` porque app GUI não herda o PATH do shell. Esse binário é um atalho do sistema:
/// sem as Ferramentas de Linha de Comando do Xcode instaladas ele falha, e a falha vira `GitStatusError`.
public struct GitStatusReader: GitStatusReading {
    public static let gitExecutable = "/usr/bin/git"

    private let runner: any CommandRunning

    public init(runner: any CommandRunning = CommandRunner()) {
        self.runner = runner
    }

    public func status(forFolderAt path: String) async throws -> GitStatus? {
        // `.git` é pasta num clone e arquivo numa worktree. Subpasta de um repositório maior não conta como git.
        guard FileManager.default.fileExists(atPath: (path as NSString).appendingPathComponent(".git")) else { return nil }
        let output = try await runner.run(
            executable: Self.gitExecutable,
            arguments: ["status", "--porcelain=v2", "-z", "--branch", "--untracked-files=all"],
            // OPTIONAL_LOCKS=0: sem isso o status regrava o índice e o vigia dispararia um novo status em loop.
            environment: ["PATH": "/usr/bin:/bin", "GIT_OPTIONAL_LOCKS": "0", "LC_ALL": "C", "HOME": NSHomeDirectory()],
            workingDirectory: path
        )
        guard output.exitCode == 0 else {
            throw GitStatusError.commandFailed(output.standardError.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return GitStatusParser.parse(output.standardOutput)
    }
}

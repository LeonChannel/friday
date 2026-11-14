// Resumo: Cria um repositório git descartável com identidade fictícia, para os testes nunca tocarem repositórios reais.
// Tags: testes, git

import Foundation
import FridayInfrastructure

/// Repositório git dentro de uma pasta temporária, manipulado pelo próprio `git` do sistema.
struct TemporaryGitRepository {
    let directory: TemporaryDirectory
    var path: String { directory.url.path }

    init() throws {
        directory = try TemporaryDirectory()
        try runGit(["init", "-q", "-b", "main"])
    }

    func remove() { directory.remove() }

    func write(_ relative: String, _ contents: String = "x") throws {
        let url = directory.url.appendingPathComponent(relative)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(contents.utf8).write(to: url)
    }

    func commitAll(_ message: String = "c") throws {
        try runGit(["add", "-A"])
        try runGit(["-c", "user.name=Teste", "-c", "user.email=teste@example.invalid", "-c", "commit.gpgsign=false", "commit", "-q", "-m", message])
    }

    @discardableResult
    func runGit(_ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory.url
        // Isola do ~/.gitconfig do usuário.
        process.environment = ["PATH": "/usr/bin:/bin", "HOME": directory.url.path, "GIT_CONFIG_NOSYSTEM": "1"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw GitTestError.failed(arguments, String(decoding: data, as: UTF8.self)) }
        return String(decoding: data, as: UTF8.self)
    }
}

enum GitTestError: Error { case failed([String], String) }

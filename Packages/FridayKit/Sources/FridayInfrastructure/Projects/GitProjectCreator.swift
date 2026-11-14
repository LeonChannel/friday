// Resumo: Cria projetos novos no disco: pasta vazia (com git init opcional) ou clone de um repositório, pelo git do sistema.
// Tags: projetos, git

import FridayDomain
import Foundation

/// Cria pasta ou clona com `/usr/bin/git`, sem pedir senha no terminal (usa as credenciais que o git do usuário já tem).
public struct GitProjectCreator: ProjectCreating {
    private let runner: any CommandRunning
    private let gitPath: String

    public init(runner: any CommandRunning = CommandRunner(), gitPath: String = "/usr/bin/git") {
        self.runner = runner
        self.gitPath = gitPath
    }

    public func createFolder(named name: String, in parent: String, initializeGit: Bool) async throws -> String {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, !clean.contains("/"), clean != ".", clean != ".." else { throw ProjectError.invalidName(name) }
        let target = URL(fileURLWithPath: parent).appendingPathComponent(clean, isDirectory: true)
        guard !FileManager.default.fileExists(atPath: target.path) else { throw ProjectError.alreadyExists(target.path) }
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)
        if initializeGit {
            try await git(["init", "--quiet"], in: target.path)
        }
        return target.path
    }

    public func clone(_ url: String, into parent: String) async throws -> String {
        let address = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let name = Self.folderName(forRepositoryURL: address) else { throw ProjectError.invalidURL(url) }
        let target = URL(fileURLWithPath: parent).appendingPathComponent(name, isDirectory: true)
        guard !FileManager.default.fileExists(atPath: target.path) else { throw ProjectError.alreadyExists(target.path) }
        try await git(["clone", "--quiet", "--", address, target.path], in: parent)
        return target.path
    }

    /// Nome da pasta do clone: último pedaço do endereço, sem `.git` (como o próprio git faz).
    public static func folderName(forRepositoryURL url: String) -> String? {
        var last = url.split(whereSeparator: { $0 == "/" || $0 == ":" }).last.map(String.init) ?? ""
        if last.hasSuffix(".git") { last.removeLast(4) }
        let valid = !last.isEmpty && last != "." && last != ".." && !url.contains(" ")
        return valid ? last : nil
    }

    private func git(_ arguments: [String], in directory: String) async throws {
        var environment = ProcessInfo.processInfo.environment
        environment["GIT_TERMINAL_PROMPT"] = "0"
        let output = try await runner.run(executable: gitPath, arguments: arguments, environment: environment, workingDirectory: directory)
        guard output.exitCode == 0 else {
            let message = output.standardError.trimmingCharacters(in: .whitespacesAndNewlines)
            throw ProjectError.commandFailed(message.isEmpty ? "O git terminou com erro \(output.exitCode)." : message)
        }
    }
}

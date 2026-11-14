// Resumo: Único ponto que lança um programa de linha de comando, espera terminar e devolve código de saída, saída e erro.
// Tags: git, terminal

import Foundation

/// Resultado de um programa que rodou até o fim.
public struct CommandOutput: Sendable {
    public var exitCode: Int32
    public var standardOutput: Data
    public var standardError: String

    public init(exitCode: Int32, standardOutput: Data, standardError: String) {
        self.exitCode = exitCode
        self.standardOutput = standardOutput
        self.standardError = standardError
    }
}

/// Roda um programa com ambiente e pasta explícitos. Troca-se por um falso nos testes.
public protocol CommandRunning: Sendable {
    func run(executable: String, arguments: [String], environment: [String: String], workingDirectory: String) async throws -> CommandOutput
}

/// Lança o programa de verdade com `Process`, lendo saída e erro em paralelo para o pipe nunca travar.
public struct CommandRunner: CommandRunning {
    public init() {}

    public func run(executable: String, arguments: [String], environment: [String: String], workingDirectory: String) async throws -> CommandOutput {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(with: Result {
                    try Self.runBlocking(executable: executable, arguments: arguments, environment: environment, workingDirectory: workingDirectory)
                })
            }
        }
    }

    private static func runBlocking(executable: String, arguments: [String], environment: [String: String], workingDirectory: String) throws -> CommandOutput {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.environment = environment
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        process.standardInput = FileHandle.nullDevice

        let errorCollector = ErrorCollector()
        let group = DispatchGroup()
        try process.run()
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            errorCollector.data = errPipe.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }
        let output = outPipe.fileHandleForReading.readDataToEndOfFile()
        group.wait()
        process.waitUntilExit()
        return CommandOutput(
            exitCode: process.terminationStatus,
            standardOutput: output,
            standardError: String(decoding: errorCollector.data, as: UTF8.self)
        )
    }
}

/// Caixa para passar o erro lido na outra thread; só é lida depois do `group.wait()`.
private final class ErrorCollector: @unchecked Sendable {
    // SAFETY: escrita uma única vez na thread de leitura, leitura só depois de DispatchGroup.wait() (happens-before).
    var data = Data()
}

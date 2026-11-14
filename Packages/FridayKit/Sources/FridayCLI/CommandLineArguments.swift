// Resumo: Separa os argumentos da CLI em posicionais, opções com valor (repetíveis) e chaves sem valor, recusando opção desconhecida.
// Tags: assuntos

import Foundation

/// Erro de uso da CLI (opção desconhecida, argumento faltando).
struct UsageError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Argumentos já separados de um comando.
struct CommandLineArguments {
    var positionals: [String] = []
    var options: [String: [String]] = [:]
    var switches: Set<String> = []

    /// `valueOptions` levam um valor; `switchOptions` não. Tudo o que começa com `--` fora dessas listas é erro; `--` sozinho encerra as opções.
    init(_ tokens: [String], valueOptions: Set<String> = [], switchOptions: Set<String> = []) throws {
        var index = 0
        var optionsEnded = false
        while index < tokens.count {
            let token = tokens[index]
            index += 1
            if optionsEnded || !token.hasPrefix("--") {
                positionals.append(token)
            } else if token == "--" {
                optionsEnded = true
            } else if switchOptions.contains(token) {
                switches.insert(token)
            } else if valueOptions.contains(token) {
                guard index < tokens.count else { throw UsageError(message: "\(token) pede um valor.") }
                options[token, default: []].append(tokens[index])
                index += 1
            } else {
                throw UsageError(message: "Opção desconhecida: \(token).")
            }
        }
    }

    func value(_ name: String) -> String? { options[name]?.last }
    func values(_ name: String) -> [String] { options[name] ?? [] }

    /// Exige exatamente `count` argumentos posicionais.
    func requirePositionals(_ count: Int, usage: String) throws {
        guard positionals.count == count else { throw UsageError(message: "Uso: \(usage)") }
    }
}

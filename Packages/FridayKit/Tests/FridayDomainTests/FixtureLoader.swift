// Resumo: Lê os payloads de hook gravados em Tests/Fixtures para os testes de domínio.
// Tags: testes, sensor

import Foundation

/// Carrega arquivos de `Tests/Fixtures/` sem depender de recursos do pacote.
enum FixtureLoader {
    static func claude(_ name: String) throws -> Data { try load("claude", name) }

    static func codex(_ name: String) throws -> Data { try load("codex", name) }

    private static func load(_ agent: String, _ name: String) throws -> Data {
        let tests = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        return try Data(contentsOf: tests.appendingPathComponent("Fixtures/\(agent)/\(name).json"))
    }
}

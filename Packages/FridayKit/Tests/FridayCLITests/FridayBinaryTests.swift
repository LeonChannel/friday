// Resumo: Roda o binário `friday` de verdade contra um banco temporário, com o app "aberto" no mesmo arquivo, e prova que a escrita chega nele.
// Tags: assuntos, persistencia, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing

@Suite(.serialized)
struct FridayBinaryTests {
    /// O binário fica ao lado do bundle de teste na pasta de produtos.
    private func binaryURL() throws -> URL {
        let candidates = [Bundle.main.bundleURL.deletingLastPathComponent(), Bundle(for: BundleToken.self).bundleURL.deletingLastPathComponent()]
        for dir in candidates {
            let url = dir.appendingPathComponent("friday")
            if FileManager.default.isExecutableFile(atPath: url.path) { return url }
        }
        throw BinaryNotFound()
    }

    private func run(_ arguments: [String], database: String) throws -> (code: Int32, out: String, err: String) {
        let process = Process()
        process.executableURL = try binaryURL()
        process.arguments = arguments
        process.environment = ["FRIDAY_DB": database, "HOME": NSTemporaryDirectory()]
        let out = Pipe(), err = Pipe()
        process.standardOutput = out
        process.standardError = err
        try process.run()
        process.waitUntilExit()
        return (
            process.terminationStatus,
            String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self),
            String(decoding: err.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        )
    }

    @Test(.tags(.integration)) func binaryWritesToSharedDatabaseWhileAppHasItOpenAndAppObservesIt() async throws {
        let dir = try TemporaryDirectory()
        defer { dir.remove() }
        let path = dir.url.appendingPathComponent("friday.sqlite").path

        // O "app": conexão aberta no mesmo arquivo, observando a lista.
        let app = GRDBSubjectRepository(database: try .open(path: path))
        var iterator = app.observeAll().makeAsyncIterator()
        #expect(try await iterator.next() == [])

        let created = try run(["assunto", "novo", "Do binário", "--intencao", "provar"], database: path)
        #expect(created.code == 0)
        #expect(created.out == "assunto 1 criado\n")
        // Sem o aviso do binário a observação do app não acordaria; ele chega pelo SubjectChangeSignal.
        #expect(try await iterator.next()?.map(\.title) == ["Do binário"])

        let evidence = try run(["evidencia", "1", "--grau", "medido", "--fonte", "teste", "funciona"], database: path)
        #expect(evidence.code == 0)
        #expect(try await iterator.next()?.first?.evidences.map(\.fact) == ["funciona"])

        let refused = try run(["evidencia", "1", "--grau", "medido", "--fonte", "s", String(repeating: "x", count: 201)], database: path)
        #expect(refused.code == 1)
        #expect(refused.err == "Evidência: 201 caracteres, o teto é 200. Encurte e tente de novo.\n")

        let read = try run(["assunto", "ler", "1"], database: path)
        #expect(read.out.contains("funciona · medido · teste"))
    }

    @Test(.tags(.integration)) func concurrentBinariesDoNotLoseWrites() async throws {
        let dir = try TemporaryDirectory()
        defer { dir.remove() }
        let path = dir.url.appendingPathComponent("friday.sqlite").path
        #expect(try run(["assunto", "novo", "Corrida"], database: path).code == 0)

        let codes = try await withThrowingTaskGroup(of: Int32.self) { group in
            for n in 1...8 {
                group.addTask { try run(["evidencia", "1", "--grau", "inferido", "--fonte", "s", "fato \(n)"], database: path).code }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }
        #expect(codes.allSatisfy { $0 == 0 })
        let subject = try #require(try GRDBSubjectRepository(database: try .open(path: path)).subject(id: 1))
        #expect(subject.evidences.count == 8)
        #expect(Set(subject.evidences.map(\.id)).count == 8)
    }
}

private final class BundleToken {}
private struct BinaryNotFound: Error {}

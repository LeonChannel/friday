// Resumo: Prova os comandos da CLI de assunto em processo contra banco em memória: saída, recusa de texto grande e erros de uso.
// Tags: assuntos, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing
@testable import FridayCLI

struct SubjectCommandRunnerTests {
    private func makeRunner() throws -> (SubjectCommandRunner, GRDBSubjectRepository) {
        let repository = GRDBSubjectRepository(database: try .inMemory())
        return (SubjectCommandRunner(repository: repository, now: { Date(timeIntervalSince1970: 1_000) }), repository)
    }

    @Test func fullFlowWritesEveryPart() throws {
        let (runner, repository) = try makeRunner()
        #expect(runner.run(["assunto", "novo", "Cache", "--intencao", "cortar latência"]).output == "assunto 1 criado\n")
        #expect(runner.run(["evidencia", "1", "--grau", "codigo", "--fonte", "a.swift:10", "lê do banco"]).output == "evidência 1 registrada no assunto 1 (no código)\n")
        #expect(runner.run(["pergunta", "1", "Tempo ou evento?", "--opcao", "Tempo|simples", "--opcao", "Evento|exato", "--espera-voce"]).output == "pergunta 1 registrada no assunto 1 (espera você)\n")
        #expect(runner.run(["alternativa", "1", "TTL", "--ganho", "g", "--risco", "r", "--esforco", "e", "--reversivel", "sim"]).exitCode == 0)
        #expect(runner.run(["decisao", "1", "Evento", "--porque", "exato", "--mudaria-se", "custo", "--responde", "1"]).exitCode == 0)
        #expect(runner.run(["frente", "1", "Medir", "--criterio", "p95", "--passo", "a", "--passo", "b", "--feitos", "1"]).output == "frente \"Medir\" no assunto 1: rodando\n")

        let subject = try #require(try repository.subject(id: 1))
        #expect(subject.questions[0].options.count == 2 && !subject.questions[0].isOpen)
        #expect(subject.evidences[0].grade == .inCode)
        #expect(subject.fronts[0].steps.map(\.isDone) == [true, false])
        #expect(subject.turn.holder == .claude)
    }

    @Test func readIsCompactMarkdownAndListShowsTurn() throws {
        let (runner, _) = try makeRunner()
        _ = runner.run(["assunto", "novo", "Cache", "--intencao", "meta"])
        _ = runner.run(["pergunta", "1", "Qual?", "--espera-voce"])
        #expect(runner.run(["assunto", "listar"]).output == "1 · Cache · vez: você (1 decisão esperando)\n")
        let read = runner.run(["assunto", "ler", "1"]).output
        #expect(read == """
            # Cache (assunto 1)
            vez: você · 1 decisão esperando

            ## Intenção
            meta

            ## Perguntas
            - 1. Qual? [espera você]

            """)
    }

    @Test func tooLongTextIsRefusedWithSizeAndWritesNothing() throws {
        let (runner, repository) = try makeRunner()
        _ = runner.run(["assunto", "novo", "Cache"])
        let outcome = runner.run(["evidencia", "1", "--grau", "medido", "--fonte", "s", String(repeating: "x", count: 250)])
        #expect(outcome.exitCode == 1)
        #expect(outcome.errorOutput == "Evidência: 250 caracteres, o teto é 200. Encurte e tente de novo.\n")
        #expect(!outcome.wrote)
        #expect(try repository.subject(id: 1)?.evidences.isEmpty == true)
    }

    @Test func usageErrorsExitWithTwo() throws {
        let (runner, _) = try makeRunner()
        #expect(runner.run([]).exitCode == 2)
        #expect(runner.run(["nada"]).exitCode == 2)
        #expect(runner.run(["evidencia", "1", "fato"]).exitCode == 2)
        #expect(runner.run(["evidencia", "1", "--grau", "chute", "--fonte", "s", "fato"]).exitCode == 2)
        #expect(runner.run(["pergunta", "1", "q", "--opcao", "semBarra"]).exitCode == 2)
        #expect(runner.run(["pergunta", "1", "q", "--invalida"]).exitCode == 2)
        #expect(runner.run(["assunto", "ler", "abc"]).exitCode == 2)
    }

    @Test func missingSubjectFails() throws {
        let (runner, _) = try makeRunner()
        let outcome = runner.run(["assunto", "ler", "7"])
        #expect(outcome.exitCode == 1)
        #expect(outcome.errorOutput == "Não existe o assunto 7.\n")
    }

    @Test func factStartingWithDashesWorksAfterSeparator() throws {
        let (runner, repository) = try makeRunner()
        _ = runner.run(["assunto", "novo", "A"])
        #expect(runner.run(["evidencia", "1", "--grau", "medido", "--fonte", "s", "--", "--flag no texto"]).exitCode == 0)
        #expect(try repository.subject(id: 1)?.evidences[0].fact == "--flag no texto")
    }
}

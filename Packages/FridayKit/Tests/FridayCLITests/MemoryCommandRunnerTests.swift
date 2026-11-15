// Resumo: Prova `friday memoria` contra vault e banco temporários: o hook de início e o de arquivo aberto, nota, área de trabalho, promoção e o silêncio quando falta algo.
// Tags: memoria, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing
@testable import FridayCLI

@Suite(.tags(.integration))
struct MemoryCommandRunnerTests {
    /// Vault, projeto e banco descartáveis, com um assunto ligado ao projeto.
    private struct Fixture {
        let dir: TemporaryDirectory
        let vault: FileMemoryVault
        let project: Project
        let subjects: GRDBSubjectRepository
        let subjectID: Int64

        init() throws {
            dir = try TemporaryDirectory()
            vault = FileMemoryVault(rootPath: try dir.makeDirectory("vault").path)
            let database = try AppDatabase.inMemory()
            project = try GRDBProjectRepository(database: database).insert(
                Project(name: "Friday", path: try dir.makeDirectory("projeto").path, kind: .git, addedAt: .distantPast)
            )
            subjects = GRDBSubjectRepository(database: database)
            var subject = try Subject(title: "Cache", projectID: project.id, createdAt: Date(timeIntervalSince1970: 1_000))
            try subject.recordDecision(text: "Invalidar por evento.", reason: "TTL serve dado velho", at: Date(timeIntervalSince1970: 1_000))
            subjectID = try #require(try subjects.insert(subject).id)
            try vault.scaffold(project: project, repositories: [])
        }

        func runner(vault: FileMemoryVault?? = nil, environment: [String: String] = [:], cwd: String? = nil, head: String? = "a1b2c3") -> MemoryCommandRunner {
            let projects = [project]
            return MemoryCommandRunner(
                vault: vault ?? self.vault, projects: { projects }, subjects: subjects, environment: environment,
                currentDirectory: cwd ?? project.path, ledgerDirectory: dir.url.appendingPathComponent("ledger"),
                head: { _ in head }, now: { Date(timeIntervalSince1970: 1_800_000_000) }
            )
        }

        func hook(_ runner: MemoryCommandRunner, _ event: [String: Any]) throws -> [String: String]? {
            let data = try JSONSerialization.data(withJSONObject: event)
            let outcome = runner.run(["hook"], input: { data })
            #expect(outcome.exitCode == 0)
            guard !outcome.output.isEmpty else { return nil }
            let json = try #require(try JSONSerialization.jsonObject(with: Data(outcome.output.utf8)) as? [String: Any])
            return json["hookSpecificOutput"] as? [String: String]
        }
    }

    @Test func sessionStartBringsLayersAndWorkAreaOfTheSubject() throws {
        let f = try Fixture()
        defer { f.dir.remove() }
        #expect(f.runner().run(["area", "\(f.subjectID)", "--estado", "Fase: medir. Próximo: p95."]).output == "estado do assunto \(f.subjectID) gravado\n")

        let runner = f.runner(environment: ["FRIDAY_ASSUNTO": "\(f.subjectID)"], head: "ffff99")
        let output = try #require(try f.hook(runner, ["hook_event_name": "SessionStart", "session_id": "s1", "cwd": f.project.path]))
        #expect(output["hookEventName"] == "SessionStart")
        let context = try #require(output["additionalContext"])
        #expect(context.contains("## Abstração: como falar e se portar"))
        #expect(context.contains("## Área de trabalho: assunto \(f.subjectID) · Cache"))
        #expect(context.contains("Fase: medir. Próximo: p95."))
        #expect(context.contains("a1b2c3 → ffff99"), "o código mudou desde o estado: fato vira pista")
        #expect(context.contains("## Projeto: Friday"))
        #expect(context.count <= MemoryLimits.sessionStart)
    }

    @Test func fileOpenDeliversAnchoredNoteOncePerSession() throws {
        let f = try Fixture()
        defer { f.dir.remove() }
        let runner = f.runner(cwd: "/")
        #expect(runner.run(["nota", "Escrita só pelo repositório", "--camada", "projeto", "--tipo", "regra",
                            "--resumo", "A view nunca grava no banco.", "--ancora", "Sources/"]).exitCode != 0,
                "fora da pasta de um projeto, nota de projeto é recusada")
        #expect(f.runner().run(["nota", "Escrita só pelo repositório", "--camada", "projeto", "--tipo", "regra",
                                "--resumo", "A view nunca grava no banco.", "--ancora", "Sources/"]).output
                == "nota criada: Projetos/Friday/Regras/Escrita so pelo repositorio.md\n")

        let read: [String: Any] = ["hook_event_name": "PreToolUse", "session_id": "s2", "cwd": f.project.path,
                                   "tool_name": "Read", "tool_input": ["file_path": f.project.path + "/Sources/Banco.swift"]]
        let first = try #require(try f.hook(runner, read))
        #expect(first["hookEventName"] == "PreToolUse")
        #expect(first["additionalContext"]?.contains("- [regra] Escrita só pelo repositório · conferida em 2027-01-15 — A view nunca grava no banco.") == true)
        #expect(try f.hook(runner, read) == nil, "a mesma nota não volta na mesma sessão")

        let relative: [String: Any] = ["hook_event_name": "PreToolUse", "session_id": "s3", "cwd": f.project.path,
                                       "tool_name": "Edit", "tool_input": ["file_path": "Sources/Outro.swift"]]
        #expect(try f.hook(runner, relative) != nil, "caminho relativo resolve pelo cwd; outra sessão recebe de novo")
        _ = try f.hook(runner, ["hook_event_name": "SessionStart", "session_id": "s2", "cwd": f.project.path])
        #expect(try f.hook(runner, read) != nil, "início de sessão (ou /compact) zera o que já foi entregue")

        let outside: [String: Any] = ["hook_event_name": "PreToolUse", "session_id": "s4", "tool_input": ["file_path": f.project.path + "/Docs/x.md"]]
        #expect(try f.hook(runner, outside) == nil)
    }

    @Test func hookStaysSilentWithoutVaultOrWithGarbage() throws {
        let f = try Fixture()
        defer { f.dir.remove() }
        #expect(try f.hook(f.runner(vault: .some(nil)), ["hook_event_name": "SessionStart", "session_id": "s"]) == nil)
        let garbage = f.runner().run(["hook"], input: { Data("não é json".utf8) })
        #expect(garbage.exitCode == 0 && garbage.output.isEmpty && garbage.errorOutput.isEmpty)
        #expect(try f.hook(f.runner(), ["hook_event_name": "Stop", "session_id": "s"]) == nil)
        #expect(f.runner(vault: .some(nil)).run(["listar"]).errorOutput.contains("Nenhum vault escolhido"))
    }

    @Test func noteUpdatesKeepBodyAndRejectWrongKind() throws {
        let f = try Fixture()
        defer { f.dir.remove() }
        let runner = f.runner()
        _ = runner.run(["nota", "Tom", "--camada", "abstracao", "--tipo", "comunicacao", "--resumo", "Direto.", "--corpo", "Sem rodeio."])
        #expect(runner.run(["nota", "Tom", "--camada", "abstracao", "--tipo", "comunicacao", "--resumo", "Direto e curto."]).output == "nota atualizada: Abstracao/Tom.md\n")
        let text = try #require(try f.vault.read("Abstracao/Tom.md"))
        #expect(text.contains("resumo: \"Direto e curto.\"") && text.contains("Sem rodeio."))

        let wrong = runner.run(["nota", "X", "--camada", "abstracao", "--tipo", "regra", "--resumo", "r"])
        #expect(wrong.exitCode == 1 && wrong.errorOutput.contains("não existe na camada Abstração"))
        #expect(runner.run(["listar", "--camada", "abstracao"]).output.contains("abstracao · comunicacao · Tom — Abstracao/Tom.md"))
        #expect(runner.run(["ler", "Abstracao/Tom.md"]).output.hasPrefix("---\ntipo: comunicacao"))
    }

    @Test func promoteAndCloseWorkArea() throws {
        let f = try Fixture()
        defer { f.dir.remove() }
        let runner = f.runner(cwd: "/")
        #expect(runner.run(["promover", "\(f.subjectID)", "--decisao", "1"]).output == "decisão 1 promovida: Projetos/Friday/Decisoes/Invalidar por evento.md\n")
        #expect(runner.run(["promover", "\(f.subjectID)", "--decisao", "7"]).errorOutput.contains("não tem a decisão 7"))
        _ = runner.run(["area", "\(f.subjectID)", "--estado", "parado"])
        #expect(runner.run(["area", "\(f.subjectID)"]).output.contains("parado"))
        #expect(runner.run(["area", "\(f.subjectID)", "--fechar"]).exitCode == 0)
        #expect(runner.run(["area", "\(f.subjectID)"]).output == "assunto \(f.subjectID) sem área de trabalho\n")
        let context = runner.run(["contexto"]).output
        #expect(context.contains("caracteres (~") && context.contains("tokens"))
    }
}

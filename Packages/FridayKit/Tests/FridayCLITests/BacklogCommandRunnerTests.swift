// Resumo: Prova `friday bug` e `friday item` contra banco em memória: autor pelo ambiente, duplicata, hierarquia, mover, referência externa, fora de projeto e o hook de início.
// Tags: backlog, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing
@testable import FridayCLI

struct BacklogCommandRunnerTests {
    private struct Fixture {
        let repository: GRDBBacklogRepository
        let project: Project

        init() throws {
            let database = try AppDatabase.inMemory()
            project = try GRDBProjectRepository(database: database).insert(Project(name: "Friday", path: "/tmp/exemplo/friday", kind: .git, addedAt: .distantPast))
            repository = GRDBBacklogRepository(database: database)
        }

        func run(_ arguments: [String], environment: [String: String] = [:], cwd: String = "/tmp/exemplo/friday/Sources", input: Data = Data()) -> CommandOutcome {
            let projects = [project]
            return BacklogCommandRunner(
                repository: repository, projects: { projects }, currentDirectory: cwd, environment: environment,
                now: { Date(timeIntervalSince1970: 1_000) }
            ).run(arguments, input: { input })
        }

        func all() throws -> [BacklogItem] { try repository.all(projectID: try #require(project.id)) }
    }

    @Test func bugFromClaudeLandsInTriageWithDetails() throws {
        let fixture = try Fixture()
        let outcome = fixture.run(
            ["bug", "Token no log", "--onde", "Auth.swift:88", "--grau", "codigo", "--detalhe", "loga o header inteiro", "--prioridade", "critica"],
            environment: ["CLAUDECODE": "1"]
        )
        #expect(outcome.exitCode == 0 && outcome.wrote)
        #expect(outcome.output == "FRI-1 criado (Bug, Novo)\n")
        let bug = try #require(try fixture.all().first)
        #expect(bug.author == .claude && bug.status == .new && bug.grade == .inCode && bug.priority == .critical && bug.location == "Auth.swift:88")
    }

    @Test func sameOpenBugIsNotDuplicated() throws {
        let fixture = try Fixture()
        _ = fixture.run(["bug", "Lista pisca"])
        let again = fixture.run(["bug", "lista  PISCA"])
        #expect(again.exitCode == 0 && !again.wrote && again.output.hasPrefix("FRI-1 já está registrado"))
        #expect(try fixture.all().count == 1)
    }

    @Test func hierarchyMoveAndExternalReference() throws {
        let fixture = try Fixture()
        #expect(fixture.run(["item", "novo", "epico", "Login"]).output == "FRI-1 criado (Épico, A fazer)\n")
        #expect(fixture.run(["item", "novo", "historia", "Entrar com e-mail", "--pai", "FRI-1"]).exitCode == 0)
        let wrong = fixture.run(["item", "novo", "epico", "Outro", "--pai", "FRI-2"])
        #expect(wrong.exitCode == 1 && wrong.errorOutput.contains("Épico não fica dentro de outro item"))
        let orphan = fixture.run(["item", "novo", "subtask", "Sem pai"])
        #expect(orphan.exitCode == 1 && orphan.errorOutput.contains("precisa estar dentro"))

        #expect(fixture.run(["item", "mover", "fri-2", "fazendo"]).output == "FRI-2 → Fazendo\n")
        #expect(fixture.run(["item", "externo", "FRI-2", "AB#68134"]).output == "FRI-2 levado para AB#68134\n")
        let story = try #require(try fixture.all().first { $0.number == 2 })
        #expect(story.status == .doing && story.externalRef == "AB#68134" && story.parentID != nil)

        let read = fixture.run(["item", "ler", "FRI-1"])
        #expect(read.output.contains("# FRI-1 · Login") && read.output.contains("- FRI-2 · História · Fazendo · → AB#68134 · Entrar com e-mail"))
        #expect(fixture.run(["item", "listar", "--tipo", "historia"]).output == "FRI-2 · História · Fazendo · → AB#68134 · Entrar com e-mail\n")
        #expect(fixture.run(["item", "apagar", "FRI-1"]).errorOutput.contains("FRI-1 tem 1 item(ns) dentro"))
    }

    @Test func listHidesClosedUnlessAsked() throws {
        let fixture = try Fixture()
        _ = fixture.run(["bug", "A"])
        _ = fixture.run(["bug", "B"])
        _ = fixture.run(["item", "mover", "FRI-1", "feito"])
        #expect(fixture.run(["item", "listar"]).output == "FRI-2 · Bug · A fazer · B\n")
        #expect(fixture.run(["item", "listar", "--fechados"]).output.split(separator: "\n").count == 2)
    }

    @Test func outsideAnyProjectExplainsWhatToDo() throws {
        let fixture = try Fixture()
        let outcome = fixture.run(["bug", "x"], cwd: "/tmp/fora")
        #expect(outcome.exitCode == 2 && outcome.errorOutput.contains("não está em nenhum projeto do Friday"))
        #expect(fixture.run(["item", "mover", "FRI-9", "feito"]).errorOutput == "Não existe o item FRI-9 neste projeto.\n")
    }

    @Test func sessionStartHookRemindsAndCountsTriage() throws {
        let fixture = try Fixture()
        _ = fixture.run(["bug", "x"], environment: ["CLAUDECODE": "1"])
        let event = Data(#"{"hook_event_name":"SessionStart","cwd":"/tmp/exemplo/friday"}"#.utf8)
        let outcome = fixture.run(["item", "hook"], input: event)
        let json = try #require(try JSONSerialization.jsonObject(with: Data(outcome.output.utf8)) as? [String: Any])
        let context = try #require((json["hookSpecificOutput"] as? [String: Any])?["additionalContext"] as? String)
        #expect(context.contains("friday bug") && context.contains("FRI-n") && context.contains("1 bug(s) esperando triagem"))
        #expect(fixture.run(["item", "hook"], input: Data(#"{"hook_event_name":"SessionStart","cwd":"/tmp/fora"}"#.utf8)).output.isEmpty)
        #expect(fixture.run(["item", "hook"], input: Data("lixo".utf8)).exitCode == 0)
    }
}

// Resumo: Prova o vault em pasta temporária: estrutura inicial sem sobrescrever, leitura por camada com problemas visíveis, área de trabalho, commit lido do .git e FRIDAY_VAULT por sessão.
// Tags: memoria, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing

@Suite(.tags(.integration))
struct FileMemoryVaultTests {
    @Test func scaffoldCreatesLayersAndHubAndNeverOverwrites() throws {
        let dir = try TemporaryDirectory()
        defer { dir.remove() }
        let vault = FileMemoryVault(rootPath: dir.url.path)
        let project = Project(name: "Lousa Ação", path: "/Users/exemplo/Projetos/lousa", kind: .folder, addedAt: .distantPast)
        let repos = [CodeRepository(name: "api", path: "/Users/exemplo/Projetos/lousa/api")]
        try vault.scaffold(project: project, repositories: repos)

        let hubPath = VaultPaths.projectHub(project.name)
        let hub = try #require(try vault.read(hubPath))
        #expect(hub.contains("- `api`: `api`"))
        let (snapshot, issues) = try vault.snapshot(projectName: project.name)
        #expect(issues.isEmpty, "as notas iniciais precisam passar na própria validação: \(issues)")
        #expect(snapshot.abstraction.map(\.kind) == [.communication, .conduct])
        #expect(snapshot.process.map(\.title) == ["Fluxo de trabalho no Friday", "O que registrar"])
        #expect(snapshot.projectHub?.path == hubPath)
        #expect(FileManager.default.fileExists(atPath: dir.url.appendingPathComponent("Projetos/Lousa Acao/Armadilhas").path))

        try Data("---\ntipo: comunicacao\nresumo: minha\n---\n# Minha".utf8).write(to: dir.url.appendingPathComponent("Abstracao/Comunicacao.md"))
        try vault.scaffold(project: project, repositories: [])
        #expect(try vault.read("Abstracao/Comunicacao.md")?.contains("# Minha") == true)
    }

    @Test func loadSkipsWorkAreaAndCacheAndReportsBrokenNotes() throws {
        let dir = try TemporaryDirectory()
        defer { dir.remove() }
        let vault = FileMemoryVault(rootPath: dir.url.path)
        let good = try MemoryNote(path: "Projetos/p/Regras/Boa.md", layer: .project, kind: .rule, title: "Boa", summary: "ok", body: "# Boa")
        try vault.save(good)
        try write(dir, "Projetos/p/Regras/Ruim.md", "---\ntipo: inventado\nresumo: x\n---\n")
        try write(dir, "Projetos/p/Trabalho/assunto-1/notas.md", "---\ntipo: regra\nresumo: não devia aparecer\n---\n")
        try write(dir, "Projetos/p/cache/x.md", "lixo")
        try write(dir, "Projetos/p/Regras/leia.txt", "não é nota")

        let load = try vault.load(.project, projectName: "p")
        #expect(load.notes == [good])
        #expect(load.issues.map(\.path) == ["Projetos/p/Regras/Ruim.md"])
        #expect(try vault.load(.project, projectName: nil) == MemoryLoad())
        #expect(throws: MemoryNoteError.invalidPath("../fora.md")) { try vault.read("../fora.md") }
    }

    @Test func workAreaSavesListsAndCloses() throws {
        let dir = try TemporaryDirectory()
        defer { dir.remove() }
        let vault = FileMemoryVault(rootPath: dir.url.path)
        let older = try WorkAreaState(subjectID: 1, text: "velho", updatedAt: Date(timeIntervalSince1970: 1_000), head: nil)
        let newer = try WorkAreaState(subjectID: 2, text: "novo", updatedAt: Date(timeIntervalSince1970: 2_000), head: "abc")
        try vault.saveWorkArea(older, projectName: "p")
        try vault.saveWorkArea(newer, projectName: "p")
        try write(dir, "Projetos/p/Trabalho/assunto-2/cache/dump.json", "{}")

        #expect(try vault.workAreas(projectName: "p").map(\.subjectID) == [2, 1])
        #expect(try vault.workArea(projectName: "p", subject: 2) == newer)
        try vault.closeWorkArea(projectName: "p", subject: 2)
        #expect(try vault.workArea(projectName: "p", subject: 2) == nil)
        #expect(!FileManager.default.fileExists(atPath: dir.url.appendingPathComponent("Projetos/p/Trabalho/assunto-2").path))
        #expect(try vault.workAreas(projectName: "p").map(\.subjectID) == [1])
    }

    @Test func gitHeadIsReadFromDiskInRepoAndWorktree() throws {
        let repo = try TemporaryGitRepository()
        defer { repo.remove() }
        #expect(GitHeadReader.head(ofRepositoryAt: repo.path) == nil, "sem commit, o ref não resolve")
        try repo.write("a.txt")
        try repo.commitAll()
        let expected = try repo.runGit(["rev-parse", "HEAD"]).trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(GitHeadReader.head(ofRepositoryAt: repo.path) == expected)

        try repo.runGit(["pack-refs", "--all"])
        #expect(GitHeadReader.head(ofRepositoryAt: repo.path) == expected, "ref empacotado em packed-refs")

        let worktree = repo.directory.url.appendingPathComponent("wt").path
        try repo.runGit(["worktree", "add", "-q", "-b", "outra", worktree])
        #expect(GitHeadReader.head(ofRepositoryAt: worktree) == expected)
        #expect(GitHeadReader.head(ofRepositoryAt: repo.directory.url.appendingPathComponent("nada").path) == nil)
    }

    @Test func launchCustomizerExportsVaultOnlyWhenFolderExists() throws {
        let dir = try TemporaryDirectory()
        defer { dir.remove() }
        let session = AgentSessionID()
        let path = dir.url.path
        #expect(try MemoryLaunchCustomizer(vaultPath: { path }).extraEnvironment(agent: .claude, session: session) == ["FRIDAY_VAULT": path])
        #expect(try MemoryLaunchCustomizer(vaultPath: { path }).extraEnvironment(agent: .shell, session: session) == ["FRIDAY_VAULT": path])
        #expect(try MemoryLaunchCustomizer(vaultPath: { path + "/nao-existe" }).extraEnvironment(agent: .claude, session: session).isEmpty)
        #expect(try MemoryLaunchCustomizer(vaultPath: { nil }).extraEnvironment(agent: .claude, session: session).isEmpty)
        #expect(try MemoryLaunchCustomizer(vaultPath: { path }).extraArguments(agent: .claude, session: session).isEmpty)
    }

    @Test func environmentVaultWinsOverPreference() {
        #expect(VaultPreference.resolve(environment: ["FRIDAY_VAULT": "/a"], preference: { "/b" }) == "/a")
        #expect(VaultPreference.resolve(environment: ["FRIDAY_VAULT": ""], preference: { "/b" }) == "/b")
        #expect(VaultPreference.resolve(environment: [:], preference: { nil }) == nil)
    }

    private func write(_ dir: TemporaryDirectory, _ relative: String, _ text: String) throws {
        let url = dir.url.appendingPathComponent(relative)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: url)
    }
}

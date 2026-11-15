// Resumo: Prova a tela de Memória sem interface: escolher a pasta, criar a estrutura, ler as camadas, importar comunicação, promover decisão e reler quando o disco muda.
// Tags: memoria, interface, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing
@testable import FridayFeatures

@MainActor
@Suite(.tags(.integration))
struct MemoryModelTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeModel(_ dir: URL, watcher: ManualWatcher = ManualWatcher()) -> (MemoryModel, AppSettings, UserDefaults) {
        let suite = "friday.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let settings = AppSettings(defaults: defaults)
        let project = Project(id: 1, name: "Friday", path: dir.appendingPathComponent("projeto").path, kind: .git, addedAt: .distantPast)
        let model = MemoryModel(project: project, settings: settings, makeVault: { FileMemoryVault(rootPath: $0) }, watcher: watcher, now: { [now] in now })
        return (model, settings, defaults)
    }

    @Test func chooseScaffoldAndReadLayers() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("friday-tests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let (model, settings, defaults) = makeModel(dir)
        model.reload()
        #expect(model.vaultPath == nil && model.briefing == nil && !model.needsScaffold)

        let vaultPath = dir.appendingPathComponent("vault").path
        try FileManager.default.createDirectory(atPath: vaultPath, withIntermediateDirectories: true)
        model.chooseVault(path: vaultPath + "/")
        #expect(settings.vaultPath == vaultPath)
        #expect(defaults.string(forKey: VaultPreference.key) == vaultPath, "a CLI e as sessões leem a mesma preferência")
        #expect(model.needsScaffold)

        model.scaffold(repositories: [CodeRepository(name: "app", path: model.project.path)])
        #expect(!model.needsScaffold && !model.lacksProjectHub)
        #expect(model.abstraction.count == 2 && model.process.count == 2 && model.projectNotes.count == 1)
        #expect(model.issues.isEmpty)
        let briefing = try #require(model.briefing)
        #expect(briefing.text.contains("## Projeto: Friday") && briefing.omitted == 0)
    }

    @Test func importPromoteAndCloseAreaThenReloadOnDiskChange() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("friday-tests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let watcher = ManualWatcher()
        let (model, _, _) = makeModel(dir, watcher: watcher)
        let vaultPath = dir.appendingPathComponent("vault").path
        try FileManager.default.createDirectory(atPath: vaultPath, withIntermediateDirectories: true)
        model.chooseVault(path: vaultPath)
        model.scaffold(repositories: [])

        model.importCommunication("---\nqualquer: coisa\n---\n# Como falar comigo\n\nInformal e direto.", sourceName: "comunicacao.md")
        let communication = try #require(model.abstraction.first { $0.kind == .communication })
        #expect(communication.body == "# Como falar comigo\n\nInformal e direto.")
        #expect(communication.summary.hasPrefix("Fale em português"), "o resumo da nota fica; só o corpo é trocado")

        var subject = try Subject(id: 3, title: "Cache", projectID: 1, createdAt: now)
        try subject.recordDecision(text: "Invalidar por evento.", reason: "TTL serve dado velho", at: now)
        #expect(!model.isPromoted(subject.decisions[0], of: subject))
        #expect(model.promote(subject.decisions[0], of: subject) == "Projetos/Friday/Decisoes/Invalidar por evento.md")
        #expect(model.isPromoted(subject.decisions[0], of: subject))

        let vault = FileMemoryVault(rootPath: vaultPath)
        try vault.saveWorkArea(try WorkAreaState(subjectID: 3, text: "medir", updatedAt: now, head: nil), projectName: "Friday")
        let observing = Task { await model.observe() }
        defer { observing.cancel() }
        while model.workAreas.isEmpty { await Task.yield() }
        #expect(model.workAreas.map(\.subjectID) == [3])

        try vault.save(try MemoryNote(path: "Processual/Novo.md", layer: .process, kind: .tool, title: "Novo", summary: "s", body: "# Novo"))
        await watcher.emit()
        while model.process.count < 3 { await Task.yield() }
        model.closeWorkArea(subject: 3)
        #expect(model.workAreas.isEmpty && model.errorMessage == nil)
    }
}

/// Vigia que só avisa quando o teste manda.
actor ManualWatcher: ChangeWatching {
    private var continuation: AsyncStream<[FileChange]>.Continuation?

    func changes(inFolderAt path: String) -> AsyncStream<[FileChange]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [FileChange].self)
        self.continuation = continuation
        return stream
    }

    /// Espera alguém ouvir e então avisa uma mudança.
    func emit() async {
        while continuation == nil { await Task.yield() }
        continuation?.yield([FileChange(path: "x", kind: .modified)])
    }
}

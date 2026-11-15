// Resumo: Renderiza telas do app em PNG com dados de exemplo, para conferir o visual sem abrir a janela; só roda com FRIDAY_SNAPSHOTS apontando para uma pasta.
// Tags: interface, testes

import AppKit
import FridayDomain
@testable import FridayFeatures
import FridayInfrastructure
import Foundation
import SwiftUI
import Testing

@MainActor
struct ScreenSnapshots {
    nonisolated static let folder = ProcessInfo.processInfo.environment["FRIDAY_SNAPSHOTS"]

    @Test(.enabled(if: folder != nil)) func projectPicker() async throws {
        let database = try AppDatabase.inMemory()
        let repository = GRDBProjectRepository(database: database)
        try repository.insert(Project(name: "EVUP", path: "/Users/exemplo/Projetos/EVUP", kind: .folder, addedAt: .distantPast, lastOpenedAt: .now.addingTimeInterval(-3600)))
        try repository.insert(Project(name: "friday", path: "/Users/exemplo/Projetos/friday", kind: .git, addedAt: .distantPast, lastOpenedAt: .now.addingTimeInterval(-86_400)))
        try repository.insert(Project(name: "anotacoes", path: "/Users/exemplo/Documentos/anotacoes", kind: .folder, addedAt: .distantPast))
        let projects = ProjectsModel(repository: repository, inspector: LocalFolderInspector())
        let observing = Task { await projects.observe() }
        defer { observing.cancel() }
        while projects.projects.count < 3 { await Task.yield() }

        for scheme in [ColorScheme.dark, .light] {
            let view = ProjectPickerView(open: { _ in })
                .environment(projects)
                .environment(\.repositoryDiscoverer, FixedCount())
                .frame(width: 900, height: 640)
                .environment(\.colorScheme, scheme)
            try save(view, "selecao-\(scheme == .dark ? "escuro" : "claro")")
            // O renderizador não desenha ScrollView nem TextField; as linhas vão numa pilha simples.
            let rows = VStack(spacing: Spacing.xs) {
                ForEach(projects.projects) { ProjectPickerRow(project: $0) }
            }
            .padding(Spacing.xxl)
            .frame(width: 660)
            .background(Theme.fundo)
            .environment(\.repositoryDiscoverer, FixedCount())
            .environment(\.colorScheme, scheme)
            try save(rows, "selecao-linhas-\(scheme == .dark ? "escuro" : "claro")")
        }
    }

    @Test(.enabled(if: folder != nil)) func memory() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("friday-snap-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let database = try AppDatabase.inMemory()
        let project = try GRDBProjectRepository(database: database).insert(Project(name: "friday", path: "/Users/exemplo/Projetos/friday", kind: .git, addedAt: .distantPast))
        let vault = FileMemoryVault(rootPath: dir.path)
        try vault.scaffold(project: project, repositories: [CodeRepository(name: "friday", path: project.path)])
        try vault.save(try MemoryNote(
            path: "Projetos/friday/Regras/Escrita.md", layer: .project, kind: .rule, title: "Escrita só pelo repositório",
            summary: "A view nunca grava no banco; tudo passa pelo repositório.", anchors: ["Packages/FridayKit/Sources/FridayInfrastructure/"],
            verifiedAt: "2026-11-14", body: "# Escrita só pelo repositório"
        ))
        let subjects = GRDBSubjectRepository(database: database)
        var subject = try Subject(title: "Reduzir o custo da fila de imagens", projectID: project.id, createdAt: .now)
        try subject.recordDecision(text: "Invalidar por evento, não por tempo.", reason: "TTL serve dado velho", at: .now)
        let subjectID = try #require(try subjects.insert(subject).id)
        try vault.saveWorkArea(try WorkAreaState(subjectID: subjectID, text: "Fase: medir o p95 da fila. Próximo: comparar com o TTL.", updatedAt: .now.addingTimeInterval(-7200), head: "a1b2c3d4"), projectName: "friday")

        let settings = AppSettings(defaults: UserDefaults(suiteName: "friday.snap.\(UUID().uuidString)")!)
        settings.vaultPath = dir.path
        let model = MemoryModel(project: project, settings: settings, makeVault: { FileMemoryVault(rootPath: $0) }, watcher: FolderChangeWatcher())
        model.reload()
        let subjectsModel = SubjectsModel(repository: subjects)
        let observing = Task { await subjectsModel.observe() }
        defer { observing.cancel() }
        while subjectsModel.rows.isEmpty { await Task.yield() }

        for scheme in [ColorScheme.dark, .light] {
            let view = VStack(alignment: .leading, spacing: Spacing.xxl) {
                Text("Memória").typography(.tituloTela).foregroundStyle(Theme.texto)
                MemoryLayersView(model: model, reading: .constant(nil), closing: .constant(nil), showsBriefing: .constant(true))
            }
            .padding(Spacing.xxxl)
            .frame(width: 1100)
            .background(Theme.fundo)
            .environment(subjectsModel)
            .environment(\.colorScheme, scheme)
            try save(view, "memoria-\(scheme == .dark ? "escuro" : "claro")")
        }
    }

    /// Regressão: abrir uma tela não pode esticar a janela (texto com fixedSize vertical medido com largura zero deixava a janela preta).
    /// Roda sempre; com FRIDAY_SNAPSHOTS também grava a imagem de cada destino.
    @Test(.tags(.integration)) func everyDestinationKeepsWindowHeight() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("friday-snap-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let database = try AppDatabase.inMemory()
        let project = try GRDBProjectRepository(database: database).insert(Project(name: "Projetos", path: dir.path, kind: .folder, addedAt: .distantPast))
        let subjects = GRDBSubjectRepository(database: database)
        var subject = try Subject(title: "Cota no rodapé", projectID: project.id, intent: "mostrar a cota sem gastar token", createdAt: .now)
        try subject.addQuestion(text: "Qual fonte?", options: [QuestionOption(label: "Statusline", consequence: "zero token")], waitsForYou: true, at: .now)
        let subjectID = try #require(try subjects.insert(subject).id)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "friday.snap.\(UUID().uuidString)")!)
        let projects = ProjectsModel(repository: GRDBProjectRepository(database: database), inspector: LocalFolderInspector())
        let subjectsModel = SubjectsModel(repository: subjects)
        let usage = UsageQuotaModel(repository: GRDBUsageQuotaRepository(database: database))
        let workspace = WorkspaceModel(
            planner: DefaultLaunchPlanner(), events: GRDBAgentEventRepository(database: database), subjects: subjects,
            makeRepositoriesModel: { ProjectRepositoriesModel(projectPath: $0.path, discoverer: LocalRepositoryDiscoverer(), gitReader: GitStatusReader()) },
            makeFilesModel: { ProjectFilesModel(rootPath: $0.path, folderReader: LocalFolderReader(), gitReader: GitStatusReader(), watcher: FolderChangeWatcher()) },
            makeMemoryModel: { MemoryModel(project: $0, settings: settings, makeVault: { FileMemoryVault(rootPath: $0) }, watcher: FolderChangeWatcher()) }
        )
        defer { ["activeProjectID", "destination"].forEach(UserDefaults.standard.removeObject(forKey:)) }
        for destination in ["mesa", "sua-vez", "memoria", "assunto:\(subjectID)", "pasta:\(dir.path)"] {
            UserDefaults.standard.set(Int(project.id ?? 0), forKey: "activeProjectID")
            UserDefaults.standard.set(destination, forKey: "destination")
            let view = RootView()
                .environment(projects).environment(subjectsModel).environment(workspace).environment(settings).environment(usage)
                .environment(\.colorScheme, .dark)
            let height = try await saveWindow(view, size: CGSize(width: 1000, height: 650), "destino-\(destination.split(separator: ":").first ?? "")")
            #expect(height <= 700, "a tela \(destination) esticou a janela para \(height) pt")
        }
    }

    /// Janela com barra de título (como a do app), esperando o splash de abertura passar.
    @discardableResult
    func saveWindow(_ view: some View, size: CGSize, _ name: String?) async throws -> CGFloat {
        let window = NSWindow(contentRect: CGRect(x: -10_000, y: -10_000, width: size.width, height: size.height),
                              styleMask: [.titled, .closable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        let host = NSHostingView(rootView: view)
        window.contentView = host
        window.orderFrontRegardless()
        defer { window.orderOut(nil) }
        try await Task.sleep(for: .seconds(2))
        host.layoutSubtreeIfNeeded()
        if let name, let folder = Self.folder {
            let rep = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: rep)
            try #require(rep.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: folder).appendingPathComponent("\(name).png"))
        }
        return window.frame.height
    }

    /// Quadros no meio de cada movimento: mergulho (seleção → projeto), deslize lateral (projeto → projeto) e rolagem do conteúdo.
    @Test(.enabled(if: folder != nil)) func motionFrames() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("friday-snap-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let database = try AppDatabase.inMemory()
        let projectRepository = GRDBProjectRepository(database: database)
        let a = try projectRepository.insert(Project(name: "Projetos", path: dir.path, kind: .folder, addedAt: .distantPast))
        let b = try projectRepository.insert(Project(name: "friday", path: dir.path + "/friday", kind: .folder, addedAt: .distantPast))
        let subjects = GRDBSubjectRepository(database: database)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "friday.snap.\(UUID().uuidString)")!)
        let projects = ProjectsModel(repository: projectRepository, inspector: LocalFolderInspector())
        let workspace = WorkspaceModel(
            planner: DefaultLaunchPlanner(), events: GRDBAgentEventRepository(database: database), subjects: subjects,
            makeRepositoriesModel: { ProjectRepositoriesModel(projectPath: $0.path, discoverer: LocalRepositoryDiscoverer(), gitReader: GitStatusReader()) },
            makeFilesModel: { ProjectFilesModel(rootPath: $0.path, folderReader: LocalFolderReader(), gitReader: GitStatusReader(), watcher: FolderChangeWatcher()) },
            makeMemoryModel: { MemoryModel(project: $0, settings: settings, makeVault: { FileMemoryVault(rootPath: $0) }, watcher: FolderChangeWatcher()) }
        )
        defer { ["activeProjectID", "destination"].forEach(UserDefaults.standard.removeObject(forKey:)) }
        UserDefaults.standard.set(0, forKey: "activeProjectID")
        UserDefaults.standard.set("mesa", forKey: "destination")
        let view = RootView()
            .environment(projects).environment(SubjectsModel(repository: subjects)).environment(workspace).environment(settings)
            .environment(UsageQuotaModel(repository: nil)).environment(\.colorScheme, .dark)
        let window = NSWindow(contentRect: CGRect(x: -10_000, y: -10_000, width: 1000, height: 650),
                              styleMask: [.titled, .closable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        let host = NSHostingView(rootView: view)
        window.contentView = host
        window.orderFrontRegardless()
        defer { window.orderOut(nil) }
        func shot(_ name: String) throws {
            let rep = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: rep)
            try #require(rep.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: Self.folder!).appendingPathComponent("\(name).png"))
        }
        try await Task.sleep(for: .seconds(2.2))
        try shot("mov-0-selecao")
        UserDefaults.standard.set(Int(a.id!), forKey: "activeProjectID")
        try await Task.sleep(for: .milliseconds(180)); try shot("mov-1-mergulho-meio")
        try await Task.sleep(for: .seconds(1)); try shot("mov-2-projeto")
        UserDefaults.standard.set("memoria", forKey: "destination")
        UserDefaults.standard.set(Int(b.id!), forKey: "activeProjectID")
        try await Task.sleep(for: .milliseconds(160)); try shot("mov-3-lateral-meio")
        try await Task.sleep(for: .seconds(1)); try shot("mov-4-outro-projeto")
        UserDefaults.standard.set(0, forKey: "activeProjectID")
        try await Task.sleep(for: .milliseconds(180)); try shot("mov-5-subida-meio")
    }

    /// Dois quadros do fundo líquido com 3 s de diferença: precisam ser diferentes (o fundo se move).
    @Test(.enabled(if: folder != nil)) func liquidBackgroundMoves() async throws {
        let view = LiquidBackground().frame(width: 1000, height: 650).environment(\.colorScheme, .dark)
        try saveHosted(view, size: CGSize(width: 1000, height: 650), "fundo-t0")
        try await Task.sleep(for: .seconds(3))
        try saveHosted(view, size: CGSize(width: 1000, height: 650), "fundo-t3")
        let folder = URL(fileURLWithPath: Self.folder!)
        let a = try Data(contentsOf: folder.appendingPathComponent("fundo-t0.png"))
        let b = try Data(contentsOf: folder.appendingPathComponent("fundo-t3.png"))
        #expect(a != b)
    }

    /// A lateral de verdade (List do AppKit), hospedada numa janela fora da tela, com 12 repositórios git reais e cota gravada.
    @Test(.enabled(if: folder != nil)) func sidebar() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("friday-snap-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let names = ["APP-ASSINATURA-DIGITAL", "APP-CUSTOMER-RN", "APP-SVC-CONTENT", "CHECKOUT-UI", "CRM-E2E", "dolphin",
                     "DOCKER-COMPOSE", "ELOS-API", "ELOS-SVC-CRM", "ELOS-UI-CRM", "evup-vault", "friday"] + (1...75).map { "repo-\($0)" }
        for name in names {
            let repo = dir.appendingPathComponent(name)
            try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
            let git = Process()
            git.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            git.arguments = ["init", "-q", "-b", name == "CRM-E2E" ? "users/exemplo/feature-com-nome-bem-comprido" : "main", repo.path]
            git.environment = ["PATH": "/usr/bin:/bin", "HOME": dir.path, "GIT_CONFIG_NOSYSTEM": "1"]
            try git.run()
            git.waitUntilExit()
        }
        let database = try AppDatabase.inMemory()
        let projectRepository = GRDBProjectRepository(database: database)
        let project = try projectRepository.insert(Project(name: "EVUP", path: dir.path, kind: .folder, addedAt: .distantPast))
        let subjects = GRDBSubjectRepository(database: database)
        var waiting = try Subject(title: "Cota no rodapé da lateral", projectID: project.id, createdAt: .now)
        try waiting.addQuestion(text: "Qual fonte?", waitsForYou: true, at: .now)
        try subjects.insert(waiting)
        let quotas = GRDBUsageQuotaRepository(database: database)
        try quotas.save(UsageQuota(
            fiveHour: QuotaWindow(usedPercentage: 26, resetsAt: .now.addingTimeInterval(7_980)),
            sevenDay: QuotaWindow(usedPercentage: 39, resetsAt: .now.addingTimeInterval(97_200)),
            capturedAt: .now.addingTimeInterval(-120)
        ))
        let projects = ProjectsModel(repository: projectRepository, inspector: LocalFolderInspector())
        let subjectsModel = SubjectsModel(repository: subjectsModelRepository(subjects))
        let usage = UsageQuotaModel(repository: quotas)
        let workspace = WorkspaceModel(
            planner: DefaultLaunchPlanner(), events: GRDBAgentEventRepository(database: database), subjects: subjects,
            makeRepositoriesModel: { ProjectRepositoriesModel(projectPath: $0.path, discoverer: LocalRepositoryDiscoverer(), gitReader: GitStatusReader()) },
            makeFilesModel: { ProjectFilesModel(rootPath: $0.path, folderReader: LocalFolderReader(), gitReader: GitStatusReader(), watcher: FolderChangeWatcher()) }
        )
        let tasks = [Task { await projects.observe() }, Task { await subjectsModel.observe() }, Task { await usage.observe() }]
        defer { tasks.forEach { $0.cancel() } }
        await workspace.repositories(for: project).refresh()
        while subjectsModel.rows.isEmpty || usage.quota == nil { await Task.yield() }

        let key = "sidebar.repositoriesExpanded"
        defer { UserDefaults.standard.removeObject(forKey: key) }
        for (expanded, scheme) in [(true, ColorScheme.dark), (false, .dark), (true, .light)] {
            UserDefaults.standard.set(expanded, forKey: key)
            let view = MainSidebar(project: project, selection: .constant(.desk), switchProject: { _ in })
                .environment(projects).environment(subjectsModel).environment(workspace).environment(usage)
                .frame(width: 260, height: 620)
                .environment(\.colorScheme, scheme)
            try saveHosted(view, size: CGSize(width: 260, height: 620), "lateral-\(expanded ? "aberta" : "recolhida")-\(scheme == .dark ? "escuro" : "claro")")
        }
        // Como no app: a lateral numa NavigationSplitView, sem altura fixa, numa janela de 1000 x 680.
        UserDefaults.standard.set(true, forKey: key)
        let window = NavigationSplitView {
            MainSidebar(project: project, selection: .constant(.desk), switchProject: { _ in })
        } detail: {
            Text("detalhe").frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding()
        }
        .environment(projects).environment(subjectsModel).environment(workspace).environment(usage)
        .environment(\.colorScheme, .dark)
        try saveHosted(window, size: CGSize(width: 1000, height: 680), "janela-com-lateral")
    }

    private func subjectsModelRepository(_ repository: GRDBSubjectRepository) -> GRDBSubjectRepository { repository }

    /// Desenha a view numa janela de verdade fora da tela (List e controles do AppKit aparecem, ao contrário do ImageRenderer).
    private func saveHosted(_ view: some View, size: CGSize, _ name: String) throws {
        let host = NSHostingView(rootView: view)
        host.frame = CGRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: CGRect(x: -10_000, y: -10_000, width: size.width, height: size.height), styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        window.orderFrontRegardless()
        defer { window.orderOut(nil) }
        for _ in 0..<20 { RunLoop.main.run(until: Date().addingTimeInterval(0.05)); host.layoutSubtreeIfNeeded() }
        let rep = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: rep)
        let data = try #require(rep.representation(using: .png, properties: [:]))
        try data.write(to: URL(fileURLWithPath: Self.folder!).appendingPathComponent("\(name).png"))
    }

    private func save(_ view: some View, _ name: String) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        let data = try #require(renderer.nsImage?.tiffRepresentation.flatMap(NSBitmapImageRep.init(data:))?.representation(using: .png, properties: [:]))
        try data.write(to: URL(fileURLWithPath: Self.folder!).appendingPathComponent("\(name).png"))
    }
}

private struct FixedCount: RepositoryDiscovering {
    func repositories(inProjectAt path: String) -> [CodeRepository] {
        path.hasSuffix("EVUP") ? (1...16).map { CodeRepository(name: "repo\($0)", path: "\(path)/repo\($0)") } : []
    }
}

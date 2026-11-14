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

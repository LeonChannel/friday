// Resumo: Árvore de arquivos do projeto com pastas que abrem sob demanda e a marca de git (M, A, D, R, ?, U) ao lado de cada item.
// Tags: pastas, git, interface

import FridayDomain
import SwiftUI

/// Árvore de arquivos de um projeto. Cria a `ProjectFilesModel` fora e a mantém viva com `.task`.
public struct ProjectFilesView: View {
    let model: ProjectFilesModel

    public init(model: ProjectFilesModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            if let message = model.errorMessage, model.rootNodes.isEmpty {
                ContentUnavailableView("Pasta indisponível", systemImage: "folder.badge.questionmark", description: Text(message))
            } else {
                List { FileTreeRows(nodes: model.rootNodes, model: model) }
            }
        }
        .task(id: model.rootPath) { await model.start() }
    }
}

/// Linhas de um nível da árvore; pastas abrem um `DisclosureGroup` com o nível de baixo.
private struct FileTreeRows: View {
    let nodes: [FileNode]
    let model: ProjectFilesModel

    var body: some View {
        ForEach(nodes) { node in
            if node.isDirectory {
                DisclosureGroup(isExpanded: expansion(of: node)) {
                    FileTreeRows(nodes: model.children(of: node), model: model)
                } label: {
                    FileRow(node: node, kind: nil, containsChanges: model.hasChanges(in: node))
                }
            } else {
                FileRow(node: node, kind: model.changeKind(of: node), containsChanges: false)
            }
        }
    }

    private func expansion(of node: FileNode) -> Binding<Bool> {
        Binding(
            get: { model.expandedPaths.contains(node.path) },
            set: { isExpanded in Task { await model.setExpanded(node.path, isExpanded) } }
        )
    }
}

private struct FileRow: View {
    let node: FileNode
    let kind: GitChangeKind?
    let containsChanges: Bool

    var body: some View {
        HStack {
            Label(node.name, systemImage: node.isDirectory ? "folder" : "doc")
                .lineLimit(1)
            Spacer()
            if let kind {
                Text(kind.badge)
                    .font(.caption.monospaced())
                    .foregroundStyle(kind.tint)
                    .accessibilityHidden(true)
            } else if containsChanges {
                Image(systemName: "circle.fill")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let type = node.isDirectory ? "pasta" : "arquivo"
        if let kind { return "\(node.name), \(type) \(kind.accessibilityText)" }
        if containsChanges { return "\(node.name), \(type) com alterações" }
        return "\(node.name), \(type)"
    }
}

#if DEBUG
private struct SampleFolderReader: FolderReading {
    func children(ofFolderAt path: String) async throws -> [FileNode] {
        let tree: [String: [FileNode]] = [
            "/exemplo": [
                FileNode(name: "Sources", path: "/exemplo/Sources", isDirectory: true),
                FileNode(name: "Tests", path: "/exemplo/Tests", isDirectory: true),
                FileNode(name: "Package.swift", path: "/exemplo/Package.swift", isDirectory: false),
                FileNode(name: "README.md", path: "/exemplo/README.md", isDirectory: false),
            ],
            "/exemplo/Sources": [
                FileNode(name: "App.swift", path: "/exemplo/Sources/App.swift", isDirectory: false),
                FileNode(name: "nova tela.swift", path: "/exemplo/Sources/nova tela.swift", isDirectory: false),
            ],
        ]
        return tree[path] ?? []
    }
}

private struct SampleGitReader: GitStatusReading {
    func status(forFolderAt path: String) async throws -> GitStatus? {
        GitStatus(branch: "main", upstream: "origin/main", ahead: 1, behind: 0, changes: [
            GitFileChange(path: "Sources/App.swift", kind: .modified),
            GitFileChange(path: "Sources/nova tela.swift", kind: .untracked),
            GitFileChange(path: "README.md", kind: .deleted),
        ])
    }
}

private struct QuietWatcher: ChangeWatching {
    func changes(inFolderAt path: String) async -> AsyncStream<[FileChange]> { AsyncStream { $0.finish() } }
}

@MainActor
private func sampleModel() -> ProjectFilesModel {
    let model = ProjectFilesModel(rootPath: "/exemplo", folderReader: SampleFolderReader(), gitReader: SampleGitReader(), watcher: QuietWatcher())
    return model
}

#Preview("Árvore de arquivos") {
    ProjectFilesView(model: sampleModel())
        .frame(width: 320, height: 360)
}

#Preview("Árvore de arquivos, escuro") {
    ProjectFilesView(model: sampleModel())
        .frame(width: 320, height: 360)
        .preferredColorScheme(.dark)
}
#endif

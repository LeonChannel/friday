// Resumo: Estado da árvore de arquivos e do git de um projeto: abre pastas sob demanda e se atualiza sozinho quando o disco muda.
// Tags: pastas, git, interface

import FridayDomain
import Foundation
import Observation

/// Árvore de arquivos preguiçosa (um nível por vez) com o status do git de cada item, mantida viva pelo vigia de mudanças.
@MainActor
@Observable
public final class ProjectFilesModel {
    public let rootPath: String
    /// Filhos diretos da raiz, na ordem de exibição.
    public private(set) var rootNodes: [FileNode] = []
    public private(set) var expandedPaths: Set<String> = []
    /// `nil` quando a pasta não é git (ou ainda não foi lida).
    public private(set) var gitStatus: GitStatus?
    public private(set) var errorMessage: String?

    private var loadedChildren: [String: [FileNode]] = [:]
    private var changeKinds: [String: GitChangeKind] = [:]
    private var foldersWithChanges: Set<String> = []

    private let folderReader: any FolderReading
    private let gitReader: any GitStatusReading
    private let watcher: any ChangeWatching

    public init(rootPath: String, folderReader: any FolderReading, gitReader: any GitStatusReading, watcher: any ChangeWatching) {
        self.rootPath = Project.normalizedPath(rootPath)
        self.folderReader = folderReader
        self.gitReader = gitReader
        self.watcher = watcher
    }

    /// Carrega a raiz e o git e depois acompanha o disco até a tarefa que chamou ser cancelada (use em `.task`).
    public func start() async {
        // O vigia abre antes da primeira leitura, para nenhuma mudança cair no intervalo entre as duas.
        let stream = await watcher.changes(inFolderAt: rootPath)
        await reload(folderAt: rootPath)
        await refreshGit()
        for await batch in stream {
            await apply(batch)
        }
    }

    /// Filhos já carregados de uma pasta; vazio enquanto ela não foi aberta.
    public func children(of node: FileNode) -> [FileNode] {
        loadedChildren[node.path] ?? []
    }

    /// Abre ou fecha uma pasta. Ao abrir pela primeira vez, lê só aquele nível.
    public func setExpanded(_ path: String, _ isExpanded: Bool) async {
        if isExpanded {
            expandedPaths.insert(path)
            if loadedChildren[path] == nil { await reload(folderAt: path) }
        } else {
            expandedPaths.remove(path)
        }
    }

    /// Tipo de alteração do arquivo no git, se houver.
    public func changeKind(of node: FileNode) -> GitChangeKind? {
        changeKinds[node.path]
    }

    /// Verdadeiro quando alguma alteração do git está dentro da pasta.
    public func hasChanges(in folder: FileNode) -> Bool {
        foldersWithChanges.contains(folder.path)
    }

    /// Relê a pasta do disco; pasta que sumiu sai da árvore.
    private func reload(folderAt path: String) async {
        do {
            let nodes = try await folderReader.children(ofFolderAt: path)
            if path == rootPath { rootNodes = nodes } else { loadedChildren[path] = nodes }
            errorMessage = nil
        } catch {
            if path == rootPath {
                errorMessage = "Não deu para abrir a pasta do projeto."
                rootNodes = []
            } else {
                loadedChildren[path] = nil
                expandedPaths.remove(path)
            }
        }
    }

    private func refreshGit() async {
        do {
            gitStatus = try await gitReader.status(forFolderAt: rootPath)
        } catch {
            gitStatus = nil
            errorMessage = error.localizedDescription
        }
        indexChanges()
    }

    private func indexChanges() {
        changeKinds = [:]
        foldersWithChanges = []
        for change in gitStatus?.changes ?? [] {
            let absolute = rootPath + "/" + change.path
            changeKinds[absolute] = change.kind
            var folder = (absolute as NSString).deletingLastPathComponent
            while folder.count > rootPath.count, foldersWithChanges.insert(folder).inserted {
                folder = (folder as NSString).deletingLastPathComponent
            }
        }
    }

    /// Recarrega só o necessário: as pastas já abertas que mudaram e o git.
    private func apply(_ batch: [FileChange]) async {
        let loadedFolders = Set(loadedChildren.keys).union([rootPath])
        var foldersToReload: Set<String> = []
        for change in batch {
            if change.kind == .requiresRescan {
                foldersToReload = loadedFolders
                break
            }
            let parent = (change.path as NSString).deletingLastPathComponent
            if loadedFolders.contains(parent) { foldersToReload.insert(parent) }
            // Pasta aberta que foi apagada ou renomeada precisa sair da árvore.
            if loadedFolders.contains(change.path), change.kind == .removed || change.kind == .renamed {
                foldersToReload.insert(change.path)
            }
        }
        for folder in foldersToReload.sorted() { await reload(folderAt: folder) }
        await refreshGit()
    }
}

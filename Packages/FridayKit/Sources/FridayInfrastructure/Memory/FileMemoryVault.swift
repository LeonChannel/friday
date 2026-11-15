// Resumo: O vault numa pasta de markdown: lê as notas de cada camada, grava nota e área de trabalho e cria a estrutura inicial sem sobrescrever nada.
// Tags: memoria, pastas

import FridayDomain
import Foundation

/// Vault em disco. Cada chamada lê o disco de novo: o dev edita as notas fora do app, e cópia em memória ficaria velha.
public struct FileMemoryVault: MemoryVaultStoring {
    public let rootPath: String
    private var root: URL { URL(fileURLWithPath: rootPath, isDirectory: true) }

    public init(rootPath: String) {
        self.rootPath = URL(fileURLWithPath: rootPath).standardizedFileURL.path
    }

    public func scaffold(project: Project?, repositories: [CodeRepository]) throws {
        let fm = FileManager.default
        for layer in MemoryLayer.allCases {
            try fm.createDirectory(at: url(layer.folder), withIntermediateDirectories: true)
        }
        try writeIfMissing(VaultPaths.hub, MemorySeeds.hub)
        for (path, text) in MemorySeeds.layerNotes { try writeIfMissing(path, text) }
        guard let project else { return }
        let projectFolder = VaultPaths.project(project.name)
        for kind in MemoryNoteKind.allCases where kind.layer == .project {
            guard let folder = kind.defaultFolder else { continue }
            try fm.createDirectory(at: url("\(projectFolder)/\(folder)"), withIntermediateDirectories: true)
        }
        try writeIfMissing(VaultPaths.projectHub(project.name), MemorySeeds.projectHub(project, repositories: repositories))
    }

    public func load(_ layer: MemoryLayer, projectName: String?) throws -> MemoryLoad {
        let folder: String
        switch layer {
        case .project:
            guard let projectName else { return MemoryLoad() }
            folder = VaultPaths.project(projectName)
        case .abstraction, .process:
            folder = layer.folder
        }
        var result = MemoryLoad()
        for path in try markdownFiles(under: folder) {
            do {
                let text = try String(contentsOf: url(path), encoding: .utf8)
                result.notes.append(try MemoryNote.parse(markdown: text, path: path, layer: layer))
            } catch {
                result.issues.append(MemoryIssue(path: path, message: error.localizedDescription))
            }
        }
        return result
    }

    public func read(_ path: String) throws -> String? {
        guard VaultPaths.isSafeNotePath(path) else { throw MemoryNoteError.invalidPath(path) }
        let file = url(path)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        return try String(contentsOf: file, encoding: .utf8)
    }

    public func save(_ note: MemoryNote) throws {
        guard VaultPaths.isSafeNotePath(note.path) else { throw MemoryNoteError.invalidPath(note.path) }
        try write(note.path, note.markdown)
    }

    public func workArea(projectName: String, subject: Int64) throws -> WorkAreaState? {
        let file = url(VaultPaths.workAreaState(projectName: projectName, subject: subject))
        guard let text = try? String(contentsOf: file, encoding: .utf8) else { return nil }
        return WorkAreaState.parse(markdown: text, subjectID: subject)
    }

    public func workAreas(projectName: String) throws -> [WorkAreaState] {
        let folder = url("\(VaultPaths.project(projectName))/\(VaultPaths.workFolder)")
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        return try names.compactMap { name -> WorkAreaState? in
            guard name.hasPrefix("assunto-"), let id = Int64(name.dropFirst("assunto-".count)) else { return nil }
            return try workArea(projectName: projectName, subject: id)
        }.sorted { $0.updatedAt > $1.updatedAt }
    }

    public func saveWorkArea(_ state: WorkAreaState, projectName: String) throws {
        try write(VaultPaths.workAreaState(projectName: projectName, subject: state.subjectID), state.markdown)
    }

    public func closeWorkArea(projectName: String, subject: Int64) throws {
        let folder = url(VaultPaths.workArea(projectName: projectName, subject: subject))
        if FileManager.default.fileExists(atPath: folder.path) { try FileManager.default.removeItem(at: folder) }
    }

    private func url(_ relative: String) -> URL {
        root.appendingPathComponent(relative)
    }

    private func write(_ relative: String, _ text: String) throws {
        let file = url(relative)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: file, options: .atomic)
    }

    private func writeIfMissing(_ relative: String, _ text: String) throws {
        guard !FileManager.default.fileExists(atPath: url(relative).path) else { return }
        try write(relative, text)
    }

    /// `.md` abaixo da pasta, em ordem de caminho, sem a área de trabalho, o espelho do backlog, `cache/` e arquivos ocultos.
    private func markdownFiles(under folder: String) throws -> [String] {
        let base = url(folder)
        guard let enumerator = FileManager.default.enumerator(
            at: base, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }
        var paths: [String] = []
        let prefix = base.standardizedFileURL.path + "/"
        for case let file as URL in enumerator {
            let isDirectory = (try? file.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDirectory {
                if [VaultPaths.workFolder, VaultPaths.backlogFolder, "cache"].contains(file.lastPathComponent) { enumerator.skipDescendants() }
                continue
            }
            let full = file.standardizedFileURL.path
            guard file.pathExtension == "md", full.hasPrefix(prefix) else { continue }
            paths.append("\(folder)/\(full.dropFirst(prefix.count))")
        }
        return paths.sorted()
    }
}

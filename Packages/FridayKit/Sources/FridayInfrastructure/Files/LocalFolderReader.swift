// Resumo: Lista uma pasta do disco um nível por vez, pastas primeiro e em ordem alfabética, escondendo .git e .DS_Store.
// Tags: pastas

import FridayDomain
import Foundation

/// Leitor de pasta do disco local.
public struct LocalFolderReader: FolderReading {
    /// Nomes que nunca aparecem na árvore.
    public static let hiddenNames: Set<String> = [".git", ".DS_Store"]

    public init() {}

    public func children(ofFolderAt path: String) async throws -> [FileNode] {
        let url = URL(fileURLWithPath: path, isDirectory: true)
        let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [])
        let nodes = urls.compactMap { child -> FileNode? in
            let name = child.lastPathComponent
            guard !Self.hiddenNames.contains(name) else { return nil }
            // Link simbólico para pasta conta como arquivo: seguir poderia entrar em ciclo.
            let isDirectory = (try? child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            return FileNode(name: name, path: child.path, isDirectory: isDirectory)
        }
        return nodes.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}

// Resumo: Acha os repositórios git de um projeto no disco: o próprio projeto, ou as pastas até dois níveis abaixo que têm .git.
// Tags: projetos, pastas, git

import FridayDomain
import Foundation

/// Descoberta de repositórios por varredura rasa, sem rodar git.
public struct LocalRepositoryDiscoverer: RepositoryDiscovering {
    /// Profundidade máxima abaixo da pasta do projeto (1 = filhos diretos).
    let maxDepth: Int
    /// Teto de repositórios devolvidos, para pasta gigante não travar a tela.
    let limit: Int
    /// Pastas que nunca contêm um repositório do dev e custam caro varrer.
    static let skipped: Set<String> = ["node_modules", ".build", "build", "DerivedData", "Pods", "vendor", "dist", ".venv"]

    public init(maxDepth: Int = 2, limit: Int = 200) {
        self.maxDepth = maxDepth
        self.limit = limit
    }

    public func repositories(inProjectAt path: String) -> [CodeRepository] {
        let root = URL(fileURLWithPath: path).standardizedFileURL
        if Self.isRepository(root) { return [CodeRepository(name: root.lastPathComponent, path: root.path)] }
        var found: [CodeRepository] = []
        scan(root, depth: 1, into: &found)
        return found.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }

    private func scan(_ folder: URL, depth: Int, into found: inout [CodeRepository]) {
        guard depth <= maxDepth, found.count < limit else { return }
        let children = (try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey], options: [.skipsHiddenFiles]
        )) ?? []
        for child in children where found.count < limit {
            let values = try? child.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard values?.isDirectory == true, values?.isSymbolicLink != true, !Self.skipped.contains(child.lastPathComponent) else { continue }
            if Self.isRepository(child) {
                found.append(CodeRepository(name: child.lastPathComponent, path: child.path))
            } else {
                scan(child, depth: depth + 1, into: &found)
            }
        }
    }

    /// `.git` é pasta num clone comum e arquivo numa worktree.
    static func isRepository(_ folder: URL) -> Bool {
        FileManager.default.fileExists(atPath: folder.appendingPathComponent(".git").path)
    }
}

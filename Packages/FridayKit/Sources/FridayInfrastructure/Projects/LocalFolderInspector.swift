// Resumo: Olha uma pasta no disco e diz se ela existe e se é repositório git (inclusive worktree).
// Tags: pastas, git

import FridayDomain
import Foundation

/// Consulta o disco local para saber se uma pasta existe e se é git.
public struct LocalFolderInspector: FolderInspecting {
    public init() {}

    public func kind(ofFolderAt path: String) -> ProjectKind? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return nil
        }
        // `.git` é pasta num clone comum e arquivo numa worktree.
        let gitPath = (path as NSString).appendingPathComponent(".git")
        return FileManager.default.fileExists(atPath: gitPath) ? .git : .folder
    }
}

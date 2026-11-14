import FridayDomain
import Foundation

public struct LocalFolderInspector: FolderInspecting {
    public init() {}

    public func kind(ofFolderAt path: String) -> ProjectKind? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return nil
        }
        // `.git` is a directory in a normal clone and a file in a worktree.
        let gitPath = (path as NSString).appendingPathComponent(".git")
        return FileManager.default.fileExists(atPath: gitPath) ? .git : .folder
    }
}

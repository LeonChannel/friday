// Resumo: Descobre o commit atual de um repositório lendo os arquivos do .git (HEAD, refs e packed-refs), sem abrir processo, inclusive em worktree.
// Tags: memoria, git

import Foundation

/// Lê o commit do `HEAD` direto do disco. Roda dentro de hook, onde abrir `git` custaria tempo do agente.
public enum GitHeadReader {
    /// Commit completo do `HEAD`, ou `nil` quando a pasta não é repositório ou o ref não resolve.
    public static func head(ofRepositoryAt path: String) -> String? {
        guard let gitDir = gitDirectory(of: URL(fileURLWithPath: path)) else { return nil }
        guard let head = read(gitDir.appendingPathComponent("HEAD")) else { return nil }
        guard head.hasPrefix("ref: ") else { return isCommit(head) ? head : nil }
        let ref = String(head.dropFirst("ref: ".count))
        let common = read(gitDir.appendingPathComponent("commondir")).map { gitDir.appendingPathComponent($0).standardizedFileURL } ?? gitDir
        for dir in [gitDir, common] {
            if let sha = read(dir.appendingPathComponent(ref)), isCommit(sha) { return sha }
        }
        let packed = read(common.appendingPathComponent("packed-refs")) ?? ""
        for line in packed.split(separator: "\n") where line.hasSuffix(" " + ref) {
            let sha = String(line.prefix { $0 != " " })
            if isCommit(sha) { return sha }
        }
        return nil
    }

    /// `.git` como pasta, ou o `gitdir:` apontado pelo arquivo `.git` de uma worktree.
    private static func gitDirectory(of folder: URL) -> URL? {
        let dotGit = folder.appendingPathComponent(".git")
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: dotGit.path, isDirectory: &isDirectory) else { return nil }
        if isDirectory.boolValue { return dotGit }
        guard let pointer = read(dotGit), pointer.hasPrefix("gitdir: ") else { return nil }
        let target = String(pointer.dropFirst("gitdir: ".count))
        return target.hasPrefix("/") ? URL(fileURLWithPath: target) : folder.appendingPathComponent(target).standardizedFileURL
    }

    private static func read(_ url: URL) -> String? {
        (try? String(contentsOf: url, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isCommit(_ text: String) -> Bool {
        text.count >= 40 && text.allSatisfy(\.isHexDigit)
    }
}

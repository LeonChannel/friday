// Resumo: Traduz a saída `git status --porcelain=v2 -z --branch` em branch, ahead/behind e arquivos alterados.
// Tags: git

import FridayDomain
import Foundation

/// Lê o formato porcelain v2 com separador NUL, que não escapa nomes com espaço ou acento.
public enum GitStatusParser {
    /// Converte a saída bruta do git. Linhas desconhecidas e ignorados (`!`) são descartados.
    public static func parse(_ output: Data) -> GitStatus {
        var status = GitStatus(branch: nil)
        let entries = output.split(separator: 0, omittingEmptySubsequences: true).map { String(decoding: $0, as: UTF8.self) }
        var index = 0
        while index < entries.count {
            let entry = entries[index]
            index += 1
            if entry.hasPrefix("# ") {
                parseHeader(entry, into: &status)
            } else if entry.hasPrefix("1 ") {
                // 1 XY sub mH mI mW hH hI path
                let fields = entry.split(separator: " ", maxSplits: 8, omittingEmptySubsequences: false)
                guard fields.count == 9 else { continue }
                status.changes.append(GitFileChange(path: String(fields[8]), kind: kind(forCode: fields[1])))
            } else if entry.hasPrefix("2 ") {
                // 2 XY sub mH mI mW hH hI Xscore path NUL origPath
                let fields = entry.split(separator: " ", maxSplits: 9, omittingEmptySubsequences: false)
                let original = index < entries.count ? entries[index] : nil
                index += 1
                guard fields.count == 10 else { continue }
                status.changes.append(GitFileChange(path: String(fields[9]), originalPath: original, kind: .renamed))
            } else if entry.hasPrefix("u ") {
                // u XY sub m1 m2 m3 mW h1 h2 h3 path
                let fields = entry.split(separator: " ", maxSplits: 10, omittingEmptySubsequences: false)
                guard fields.count == 11 else { continue }
                status.changes.append(GitFileChange(path: String(fields[10]), kind: .conflicted))
            } else if entry.hasPrefix("? ") {
                status.changes.append(GitFileChange(path: String(entry.dropFirst(2)), kind: .untracked))
            }
        }
        return status
    }

    private static func parseHeader(_ line: String, into status: inout GitStatus) {
        if let value = line.removingPrefix("# branch.head ") {
            status.branch = value == "(detached)" ? nil : value
        } else if let value = line.removingPrefix("# branch.upstream ") {
            status.upstream = value
        } else if let value = line.removingPrefix("# branch.ab ") {
            let parts = value.split(separator: " ")
            guard parts.count == 2, let ahead = Int(parts[0].dropFirst()), let behind = Int(parts[1].dropFirst()) else { return }
            status.ahead = ahead
            status.behind = behind
        }
    }

    /// X é o índice, Y a árvore de trabalho; `A` no índice vence (arquivo novo mesmo se já editado de novo).
    private static func kind(forCode code: Substring) -> GitChangeKind {
        let codes = Array(code)
        if codes.first == "A" { return .added }
        if codes.contains("D") { return .deleted }
        if codes.contains("R") || codes.contains("C") { return .renamed }
        return .modified
    }
}

private extension String {
    func removingPrefix(_ prefix: String) -> String? {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : nil
    }
}

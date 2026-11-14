// Resumo: Prova que a saída porcelain v2 do git é lida certo: cabeçalho, tipos de mudança, nomes com espaço, renomeação e conflito.
// Tags: git, testes

import FridayDomain
import FridayInfrastructure
import Foundation
import Testing

struct GitStatusParserTests {
    private func parse(_ entries: [String]) -> GitStatus {
        GitStatusParser.parse(Data((entries.joined(separator: "\0") + "\0").utf8))
    }

    private let zero = String(repeating: "0", count: 40)

    @Test func readsBranchUpstreamAndAheadBehind() {
        let status = parse(["# branch.oid \(zero)", "# branch.head main", "# branch.upstream origin/main", "# branch.ab +2 -3"])
        #expect(status.branch == "main")
        #expect(status.upstream == "origin/main")
        #expect(status.ahead == 2)
        #expect(status.behind == 3)
    }

    @Test func leavesAheadBehindEmptyWithoutUpstream() {
        let status = parse(["# branch.head feature"])
        #expect(status.upstream == nil)
        #expect(status.ahead == nil)
        #expect(status.behind == nil)
    }

    @Test func detachedHeadHasNoBranch() {
        #expect(parse(["# branch.head (detached)"]).branch == nil)
    }

    @Test func mapsEachChangeKindAndKeepsSpacesInNames() {
        let status = parse([
            "1 .M N... 100644 100644 100644 aaa bbb dir/with space.txt",
            "1 A. N... 000000 100644 100644 aaa bbb added.txt",
            "1 AM N... 000000 100644 100644 aaa bbb addedThenEdited.txt",
            "1 .D N... 100644 100644 000000 aaa bbb gone.txt",
            "1 D. N... 100644 000000 000000 aaa bbb stagedGone.txt",
            "? new file.txt",
            "u UU N... 100644 100644 100644 100644 a b c conflict.txt",
        ])
        #expect(status.changes == [
            GitFileChange(path: "dir/with space.txt", kind: .modified),
            GitFileChange(path: "added.txt", kind: .added),
            GitFileChange(path: "addedThenEdited.txt", kind: .added),
            GitFileChange(path: "gone.txt", kind: .deleted),
            GitFileChange(path: "stagedGone.txt", kind: .deleted),
            GitFileChange(path: "new file.txt", kind: .untracked),
            GitFileChange(path: "conflict.txt", kind: .conflicted),
        ])
    }

    @Test func readsRenameWithOriginalPathFromTheNextEntry() {
        let status = parse([
            "2 R. N... 100644 100644 100644 aaa bbb R100 new name.txt", "old name.txt",
            "? after.txt",
        ])
        #expect(status.changes == [
            GitFileChange(path: "new name.txt", originalPath: "old name.txt", kind: .renamed),
            GitFileChange(path: "after.txt", kind: .untracked),
        ])
    }

    @Test func ignoresIgnoredEntriesAndEmptyOutput() {
        #expect(parse(["! build/"]).changes.isEmpty)
        #expect(GitStatusParser.parse(Data()) == GitStatus(branch: nil))
    }
}

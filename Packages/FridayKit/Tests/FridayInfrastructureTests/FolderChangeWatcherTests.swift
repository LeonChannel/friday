// Resumo: Prova o vigia de pasta com FSEvents real: evento ao escrever, filtro de .git, fim do fluxo ao parar.
// Tags: pastas, git, testes

import FridayDomain
@testable import FridayInfrastructure
import Foundation
import Testing

@Suite(.tags(.integration))
struct FolderChangeWatcherTests {
    /// Espera o primeiro lote que satisfaz `matches`, até o prazo; `nil` se estourar.
    private func firstBatch(
        in stream: AsyncStream<[FileChange]>,
        timeout: Duration = .seconds(10),
        where matches: @escaping @Sendable ([FileChange]) -> Bool
    ) async -> [FileChange]? {
        await withTaskGroup(of: [FileChange]?.self) { group in
            group.addTask {
                for await batch in stream where matches(batch) { return batch }
                return nil
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }
            let result = await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }

    @Test func reportsCreatedFileInsideWatchedFolder() async throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        let watcher = FolderChangeWatcher(latency: 0.1)
        let stream = await watcher.changes(inFolderAt: temp.url.path)
        let target = temp.url.appendingPathComponent("novo arquivo.txt").path

        try Data("oi".utf8).write(to: URL(fileURLWithPath: target))

        let batch = await firstBatch(in: stream) { $0.contains { $0.path == target } }
        #expect(try #require(batch).contains { $0.path == target })
        await watcher.stop()
    }

    @Test func ignoresGitNoiseButReportsIndexAndHead() async throws {
        let repo = try TemporaryGitRepository()
        defer { repo.remove() }
        try repo.write("a.txt")
        try repo.commitAll()
        let watcher = FolderChangeWatcher(latency: 0.1)
        let stream = await watcher.changes(inFolderAt: repo.path)

        try repo.write(".git/objects/noise.tmp")
        try repo.write(".git/index.lock")
        try repo.write(".git/HEAD", "ref: refs/heads/main\n")
        try repo.write("marker.txt")

        // Se o ruído vazasse, estaria no mesmo lote que o HEAD ou o marcador.
        let batch = try #require(await firstBatch(in: stream) { $0.contains { $0.path.hasSuffix("marker.txt") } })
        let paths = Set(batch.map { $0.path.replacingOccurrences(of: repo.path + "/", with: "") })
        #expect(!paths.contains { $0.contains("objects") })
        #expect(!paths.contains { $0.hasSuffix(".lock") })
        #expect(paths.contains("marker.txt"))
        await watcher.stop()
    }

    @Test func finishesStreamWhenStopped() async throws {
        let temp = try TemporaryDirectory()
        defer { temp.remove() }
        let watcher = FolderChangeWatcher(latency: 0.1)
        let stream = await watcher.changes(inFolderAt: temp.url.path)

        await watcher.stop()

        var iterator = stream.makeAsyncIterator()
        #expect(await iterator.next() == nil)
    }

    @Test func filterKeepsOnlyGitFilesThatChangeStatus() {
        #expect(FileChangeFilter.accepts(relativePath: ".git/index"))
        #expect(FileChangeFilter.accepts(relativePath: ".git/HEAD"))
        #expect(FileChangeFilter.accepts(relativePath: ".git/refs/heads/main"))
        #expect(!FileChangeFilter.accepts(relativePath: ".git/index.lock"))
        #expect(!FileChangeFilter.accepts(relativePath: ".git/objects/ab/cdef"))
        #expect(!FileChangeFilter.accepts(relativePath: ".git/logs/HEAD"))
        #expect(!FileChangeFilter.accepts(relativePath: "vendor/.git/index"))
        #expect(!FileChangeFilter.accepts(relativePath: "dir/.DS_Store"))
        #expect(FileChangeFilter.accepts(relativePath: ".gitignore"))
        #expect(FileChangeFilter.accepts(relativePath: "src/main.swift"))
    }
}

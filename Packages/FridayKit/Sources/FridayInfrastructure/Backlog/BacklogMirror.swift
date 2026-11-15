// Resumo: Pasta espelho do backlog no vault (um .md por item e o índice), regravada a cada escrita, e o repositório que faz isso sozinho depois de gravar no banco.
// Tags: backlog, memoria, pastas

import FridayDomain
import Foundation
import OSLog

/// Escreve `Projetos/<projeto>/Backlog/` no vault a partir do banco. Só sai do banco para a pasta, nunca volta.
public struct BacklogMirror: Sendable {
    private let vaultRoot: @Sendable () -> String?
    private let projectName: @Sendable (Int64) -> String?

    /// `vaultRoot` é lido a cada escrita (trocar o vault vale na hora); sem vault, o espelho fica calado.
    public init(vaultRoot: @escaping @Sendable () -> String?, projectName: @escaping @Sendable (Int64) -> String?) {
        self.vaultRoot = vaultRoot
        self.projectName = projectName
    }

    /// Regrava a pasta do projeto inteira: um arquivo por item, o índice, e apaga arquivo de item que não existe mais.
    public func sync(projectID: Int64, items: [BacklogItem]) throws {
        guard let root = vaultRoot(), let name = projectName(projectID) else { return }
        let key = BacklogCode.key(forProjectName: name)
        let base = URL(fileURLWithPath: root, isDirectory: true)
        let folder = base.appendingPathComponent(VaultPaths.backlog(projectName: name), isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let byID = Dictionary(uniqueKeysWithValues: items.compactMap { item in item.id.map { ($0, item) } })
        let children = BacklogProjection.children(items)
        var kept: Set<String> = [(VaultPaths.backlogIndex(projectName: name) as NSString).lastPathComponent]
        for item in items {
            let relative = VaultPaths.backlogItem(projectName: name, code: BacklogCode.format(key: key, number: item.number))
            let text = BacklogMarkdown.render(item, key: key, parent: item.parentID.flatMap { byID[$0] }, children: item.id.flatMap { children[$0] } ?? [])
            try writeIfChanged(text, to: base.appendingPathComponent(relative))
            kept.insert((relative as NSString).lastPathComponent)
        }
        try writeIfChanged(BacklogMarkdown.index(items, key: key, projectName: name), to: base.appendingPathComponent(VaultPaths.backlogIndex(projectName: name)))
        // A pasta é do Friday: .md que não corresponde a item atual (apagado, sigla trocada ao renomear o projeto) sai.
        for file in try FileManager.default.contentsOfDirectory(atPath: folder.path) where file.hasSuffix(".md") && !kept.contains(file) {
            try FileManager.default.removeItem(at: folder.appendingPathComponent(file))
        }
    }

    /// Não regrava arquivo igual: o vigia de pasta e o Obsidian não precisam acordar à toa.
    private func writeIfChanged(_ text: String, to url: URL) throws {
        let data = Data(text.utf8)
        if (try? Data(contentsOf: url)) == data { return }
        try data.write(to: url, options: .atomic)
    }
}

/// Repositório que grava no banco e depois atualiza o espelho. Falha do espelho vira log: o banco é a fonte e já gravou.
public struct MirroredBacklogRepository: BacklogRepository {
    private let inner: any BacklogRepository
    private let mirror: BacklogMirror
    private static let logger = Logger(subsystem: "com.leonchannel.friday", category: "backlog")

    public init(inner: any BacklogRepository, mirror: BacklogMirror) {
        self.inner = inner
        self.mirror = mirror
    }

    public func observeAll(projectID: Int64) -> AsyncThrowingStream<[BacklogItem], any Error> { inner.observeAll(projectID: projectID) }
    public func all(projectID: Int64) throws -> [BacklogItem] { try inner.all(projectID: projectID) }
    public func item(projectID: Int64, number: Int) throws -> BacklogItem? { try inner.item(projectID: projectID, number: number) }
    public func item(id: Int64) throws -> BacklogItem? { try inner.item(id: id) }

    @discardableResult
    public func insert(_ item: BacklogItem) throws -> BacklogItem {
        let saved = try inner.insert(item)
        sync(saved.projectID)
        return saved
    }

    @discardableResult
    public func update(id: Int64, _ change: @Sendable (inout BacklogItem) throws -> Void) throws -> BacklogItem {
        let saved = try inner.update(id: id, change)
        sync(saved.projectID)
        return saved
    }

    public func delete(id: Int64) throws {
        let projectID = try inner.item(id: id)?.projectID
        try inner.delete(id: id)
        if let projectID { sync(projectID) }
    }

    private func sync(_ projectID: Int64) {
        do {
            try mirror.sync(projectID: projectID, items: inner.all(projectID: projectID))
        } catch {
            Self.logger.error("Espelho do backlog não gravou: \(error.localizedDescription)")
        }
    }
}

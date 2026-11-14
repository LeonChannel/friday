// Resumo: Vigia uma pasta com FSEvents e entrega lotes de mudanças, ignorando o ruído de dentro de .git exceto o que muda o status.
// Tags: pastas, git

import CoreServices
import FridayDomain
import Foundation

/// Vigia de pastas. Cada chamada a `changes(inFolderAt:)` abre um fluxo próprio, encerrado quando o consumidor para de ouvir.
public actor FolderChangeWatcher: ChangeWatching {
    private let latency: TimeInterval
    private var subscriptions: [UUID: FSEventsSubscription] = [:]

    /// `latency` é a janela que agrupa uma rajada de eventos num único lote (0,3 s por padrão).
    public init(latency: TimeInterval = 0.3) {
        self.latency = latency
    }

    public func changes(inFolderAt path: String) -> AsyncStream<[FileChange]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [FileChange].self, bufferingPolicy: .unbounded)
        let id = UUID()
        guard let subscription = FSEventsSubscription(folderPath: path, latency: latency, continuation: continuation) else {
            continuation.finish()
            return stream
        }
        subscriptions[id] = subscription
        continuation.onTermination = { [weak self] _ in
            Task { await self?.release(id) }
        }
        return stream
    }

    /// Encerra todos os fluxos abertos e libera os streams do sistema.
    public func stop() {
        let all = subscriptions.values
        subscriptions.removeAll()
        for subscription in all { subscription.stop() }
    }

    private func release(_ id: UUID) {
        subscriptions.removeValue(forKey: id)?.stop()
    }
}

/// Traduz eventos crus do sistema em `FileChange`, aplicando os filtros de `.git` e `.DS_Store`.
enum FileChangeFilter {
    /// Dentro de `.git`, só interessam arquivos que mudam o status: índice, HEAD e referências.
    static func affectsGitStatus(gitRelativeComponents components: [Substring]) -> Bool {
        guard let first = components.first else { return false }
        if components.last?.hasSuffix(".lock") == true { return false }
        switch first {
        case "index", "HEAD", "MERGE_HEAD", "packed-refs": return components.count == 1
        case "refs": return components.count > 1
        default: return false
        }
    }

    /// `false` quando o evento deve ser ignorado (ruído de `.git`, `.DS_Store`).
    static func accepts(relativePath: String) -> Bool {
        let components = relativePath.split(separator: "/")
        guard let last = components.last else { return true }
        if last == ".DS_Store" { return false }
        if let gitIndex = components.firstIndex(of: ".git") {
            // `.git` aninhado (submódulo, repositório dentro do projeto) não é o repositório do projeto.
            guard gitIndex == 0 else { return false }
            return affectsGitStatus(gitRelativeComponents: Array(components.dropFirst()))
        }
        return true
    }
}

/// Um stream do FSEvents ligado a um `AsyncStream`. Parar libera o stream do sistema.
private final class FSEventsSubscription: @unchecked Sendable {
    private let queue = DispatchQueue(label: "friday.folder-watcher", qos: .utility)
    // SAFETY: `stream` é escrito só no init e `stop()` é idempotente por `stopped`, sempre na `queue`.
    private var stream: FSEventStreamRef?
    private var stopped = false
    private let sink: EventSink

    init?(folderPath: String, latency: TimeInterval, continuation: AsyncStream<[FileChange]>.Continuation) {
        let requested = URL(fileURLWithPath: folderPath).standardizedFileURL.path
        // O FSEvents reporta caminhos reais (`/private/var`), então comparamos contra a raiz resolvida.
        let resolved = Self.realPath(requested)
        sink = EventSink(requestedRoot: requested, resolvedRoot: resolved, continuation: continuation)

        var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(sink).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        let callback: FSEventStreamCallback = { _, info, count, eventPaths, eventFlags, _ in
            guard let info else { return }
            let sink = Unmanaged<EventSink>.fromOpaque(info).takeUnretainedValue()
            let paths = unsafeBitCast(eventPaths, to: CFArray.self) as? [String] ?? []
            sink.handle(paths: paths, flags: Array(UnsafeBufferPointer(start: eventFlags, count: count)))
        }
        let flags = UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagWatchRoot)
        guard let created = FSEventStreamCreate(nil, callback, &context, [resolved] as CFArray, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), latency, flags) else {
            return nil
        }
        stream = created
        FSEventStreamSetDispatchQueue(created, queue)
        guard FSEventStreamStart(created) else {
            FSEventStreamInvalidate(created)
            FSEventStreamRelease(created)
            stream = nil
            return nil
        }
    }

    /// `resolvingSymlinksInPath` deixa `/var` como está; só `realpath` entrega o `/private/var` que o FSEvents usa.
    private static func realPath(_ path: String) -> String {
        guard let resolved = realpath(path, nil) else { return path }
        defer { free(resolved) }
        return String(cString: resolved)
    }

    func stop() {
        queue.sync {
            guard !stopped, let stream else { return }
            stopped = true
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
        sink.finish()
    }

    deinit { stop() }
}

/// Recebe os eventos na fila do FSEvents, filtra, junta repetições e empurra o lote para o `AsyncStream`.
private final class EventSink: @unchecked Sendable {
    private let requestedRoot: String
    private let resolvedRoot: String
    private let continuation: AsyncStream<[FileChange]>.Continuation

    init(requestedRoot: String, resolvedRoot: String, continuation: AsyncStream<[FileChange]>.Continuation) {
        self.requestedRoot = requestedRoot
        self.resolvedRoot = resolvedRoot
        self.continuation = continuation
    }

    func finish() { continuation.finish() }

    func handle(paths: [String], flags: [FSEventStreamEventFlags]) {
        var order: [String] = []
        var byPath: [String: FileChangeKind] = [:]
        for (path, flag) in zip(paths, flags) {
            guard let change = translate(path: path, flags: flag) else { continue }
            if byPath[change.path] == nil { order.append(change.path) }
            byPath[change.path] = change.kind
        }
        guard !order.isEmpty else { return }
        continuation.yield(order.compactMap { path in byPath[path].map { FileChange(path: path, kind: $0) } })
    }

    private func translate(path: String, flags: FSEventStreamEventFlags) -> FileChange? {
        if flags & UInt32(kFSEventStreamEventFlagMustScanSubDirs | kFSEventStreamEventFlagRootChanged | kFSEventStreamEventFlagUserDropped | kFSEventStreamEventFlagKernelDropped) != 0 {
            return FileChange(path: requestedRoot, kind: .requiresRescan)
        }
        let relative: String
        if path == resolvedRoot {
            relative = ""
        } else if path.hasPrefix(resolvedRoot + "/") {
            relative = String(path.dropFirst(resolvedRoot.count + 1))
        } else {
            return nil
        }
        guard FileChangeFilter.accepts(relativePath: relative) else { return nil }
        let absolute = relative.isEmpty ? requestedRoot : requestedRoot + "/" + relative
        return FileChange(path: absolute, kind: kind(for: flags, absolutePath: absolute))
    }

    private func kind(for flags: FSEventStreamEventFlags, absolutePath: String) -> FileChangeKind {
        let created = flags & UInt32(kFSEventStreamEventFlagItemCreated) != 0
        let removed = flags & UInt32(kFSEventStreamEventFlagItemRemoved) != 0
        let renamed = flags & UInt32(kFSEventStreamEventFlagItemRenamed) != 0
        // Eventos agrupados trazem várias flags; a existência no disco desempata.
        if removed || renamed {
            if !FileManager.default.fileExists(atPath: absolutePath) { return renamed && !removed ? .renamed : .removed }
            return renamed ? .renamed : (created ? .created : .modified)
        }
        return created ? .created : .modified
    }
}

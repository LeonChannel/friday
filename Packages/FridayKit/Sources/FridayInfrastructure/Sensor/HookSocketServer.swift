// Resumo: Servidor local (Unix socket) que recebe uma mensagem por conexão dos scripts de hook dos agentes e a entrega ao app.
// Tags: sensor

import Darwin
import Dispatch
import Foundation
import os

/// Falhas ao abrir o socket dos hooks.
public enum HookSocketError: Error, Equatable, Sendable {
    case pathTooLong
    case unsafeDirectory
    case system(String, Int32)
}

/// Uma mensagem inteira lida de uma conexão, com o momento da chegada.
public struct HookMessage: Sendable {
    public let data: Data
    public let receivedAt: Date
}

/// Escuta num Unix socket (diretório 0700, socket 0600). Cada conexão manda uma mensagem e fecha; lixo e excesso de tamanho são ignorados.
public actor HookSocketServer {
    private let socketPath: String
    private let maxMessageBytes: Int
    private let readTimeoutSeconds: Int
    private let logger = Logger(subsystem: "com.leonchannel.friday", category: "sensor")
    private var listener: ListenerState?

    /// - Parameters:
    ///   - maxMessageBytes: conexão que passar disso é descartada inteira.
    ///   - readTimeoutSeconds: cliente que abre e não termina de enviar é cortado.
    public init(socketPath: String, maxMessageBytes: Int = 1 << 20, readTimeoutSeconds: Int = 2) {
        self.socketPath = socketPath
        self.maxMessageBytes = maxMessageBytes
        self.readTimeoutSeconds = readTimeoutSeconds
    }

    /// Abre o socket e devolve o fluxo de mensagens recebidas. O fluxo termina em `stop()`.
    public func start() throws -> AsyncStream<HookMessage> {
        if listener != nil { stop() }
        let fd = try Self.openListener(path: socketPath)
        let (stream, continuation) = AsyncStream<HookMessage>.makeStream(bufferingPolicy: .bufferingNewest(1024))
        let queue = DispatchQueue(label: "friday.hooks.accept")
        let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
        let maxBytes = maxMessageBytes
        let timeout = readTimeoutSeconds
        let log = logger
        source.setEventHandler {
            while true {
                let client = accept(fd, nil, nil)
                if client < 0 { return }
                DispatchQueue.global(qos: .utility).async {
                    if let message = Self.readAll(client, maxBytes: maxBytes, timeoutSeconds: timeout, logger: log) {
                        continuation.yield(HookMessage(data: message, receivedAt: Date()))
                    }
                    close(client)
                }
            }
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        listener = ListenerState(source: source, continuation: continuation)
        return stream
    }

    /// Fecha o socket, apaga o arquivo e encerra o fluxo.
    public func stop() {
        guard let listener else { return }
        listener.source.cancel()
        listener.continuation.finish()
        unlink(socketPath)
        self.listener = nil
    }

    private struct ListenerState: Sendable {
        let source: any DispatchSourceRead
        let continuation: AsyncStream<HookMessage>.Continuation
    }

    // MARK: Socket

    private static func openListener(path: String) throws -> Int32 {
        guard path.utf8.count < MemoryLayout<sockaddr_un>.size - MemoryLayout<sockaddr_un>.offset(of: \.sun_path)! else {
            throw HookSocketError.pathTooLong
        }
        let directory = (path as NSString).deletingLastPathComponent
        try prepareDirectory(directory)
        unlink(path)

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw HookSocketError.system("socket", errno) }
        do {
            var address = sockaddr_un()
            address.sun_family = sa_family_t(AF_UNIX)
            withUnsafeMutableBytes(of: &address.sun_path) { buffer in
                buffer.copyBytes(from: path.utf8)
                buffer[path.utf8.count] = 0
            }
            let bound = withUnsafePointer(to: &address) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
            }
            guard bound == 0 else { throw HookSocketError.system("bind", errno) }
            guard chmod(path, 0o600) == 0 else { throw HookSocketError.system("chmod", errno) }
            guard listen(fd, 64) == 0 else { throw HookSocketError.system("listen", errno) }
            _ = fcntl(fd, F_SETFL, fcntl(fd, F_GETFL) | O_NONBLOCK)
            return fd
        } catch {
            close(fd)
            throw error
        }
    }

    /// Cria o diretório com 0700 e recusa um que não seja do usuário ou que outros possam acessar.
    private static func prepareDirectory(_ directory: String) throws {
        if mkdir(directory, 0o700) != 0 {
            guard errno == EEXIST else { throw HookSocketError.system("mkdir", errno) }
        }
        var info = stat()
        guard lstat(directory, &info) == 0,
              (info.st_mode & S_IFMT) == S_IFDIR,
              info.st_uid == getuid()
        else { throw HookSocketError.unsafeDirectory }
        if info.st_mode & 0o077 != 0 {
            guard chmod(directory, 0o700) == 0 else { throw HookSocketError.unsafeDirectory }
        }
    }

    /// Lê até EOF. Devolve `nil` se estourar o limite, der timeout, erro ou vier vazio.
    private static func readAll(_ fd: Int32, maxBytes: Int, timeoutSeconds: Int, logger: Logger) -> Data? {
        var timeout = timeval(tv_sec: timeoutSeconds, tv_usec: 0)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        _ = fcntl(fd, F_SETFL, fcntl(fd, F_GETFL) & ~O_NONBLOCK)
        var data = Data()
        var chunk = [UInt8](repeating: 0, count: 16 * 1024)
        while true {
            let count = read(fd, &chunk, chunk.count)
            if count == 0 { return data.isEmpty ? nil : data }
            if count < 0 {
                if errno == EINTR { continue }
                logger.debug("leitura do socket falhou: errno \(errno)")
                return nil
            }
            data.append(chunk, count: count)
            if data.count > maxBytes {
                logger.debug("mensagem acima do limite descartada")
                return nil
            }
        }
    }
}

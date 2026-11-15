// Resumo: Liga o sensor: abre o socket dos hooks, decodifica cada mensagem recebida e grava o evento (ou a cota vinda da statusline) no banco.
// Tags: sensor, persistencia, cota

import FridayDomain
import Foundation
import os

/// Serviço que mantém o socket aberto e transforma mensagens de hook em eventos gravados. Loga só metadado, nunca conteúdo.
public actor SensorService {
    private let server: HookSocketServer
    private let repository: any AgentEventRepository
    private let quotas: (any UsageQuotaRepository)?
    private let logger = Logger(subsystem: "com.leonchannel.friday", category: "sensor")
    private var task: Task<Void, Never>?

    /// `quotas` recebe a cota que chega pela statusline; sem ele, essas mensagens são ignoradas.
    public init(server: HookSocketServer, repository: any AgentEventRepository, quotas: (any UsageQuotaRepository)? = nil) {
        self.server = server
        self.repository = repository
        self.quotas = quotas
    }

    /// Cabeçalho das mensagens da statusline (`statusline <sessão>\n<JSON>`).
    static let statuslinePrefix = Data("statusline ".utf8)

    /// Abre o socket e começa a gravar. Chamar de novo reinicia.
    public func start() async throws {
        task?.cancel()
        let messages = try await server.start()
        let repository = repository
        let quotas = quotas
        let logger = logger
        task = Task {
            for await message in messages {
                if message.data.starts(with: Self.statuslinePrefix) {
                    guard let quotas, let newline = message.data.firstIndex(of: 0x0A),
                          let quota = UsageQuota.decode(statusline: message.data[message.data.index(after: newline)...], capturedAt: message.receivedAt) else { continue }
                    do { try quotas.save(quota) } catch {
                        logger.error("falha ao gravar cota: \(String(describing: error), privacy: .public)")
                    }
                    continue
                }
                do {
                    let event = try AgentEventDecoder.decode(message.data, receivedAt: message.receivedAt)
                    try repository.record(event)
                    logger.debug("evento gravado: \(event.kind.hookName, privacy: .public)")
                } catch let error as AgentEventDecodingError {
                    logger.debug("mensagem ignorada: \(String(describing: error), privacy: .public)")
                } catch {
                    logger.error("falha ao gravar evento: \(String(describing: error), privacy: .public)")
                }
            }
        }
    }

    /// Fecha o socket e para de gravar.
    public func stop() async {
        await server.stop()
        task?.cancel()
        task = nil
    }
}

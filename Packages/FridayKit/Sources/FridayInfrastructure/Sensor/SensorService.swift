// Resumo: Liga o sensor: abre o socket dos hooks, decodifica cada mensagem recebida e grava o evento no banco.
// Tags: sensor, persistencia

import FridayDomain
import Foundation
import os

/// Serviço que mantém o socket aberto e transforma mensagens de hook em eventos gravados. Loga só metadado, nunca conteúdo.
public actor SensorService {
    private let server: HookSocketServer
    private let repository: any AgentEventRepository
    private let logger = Logger(subsystem: "com.leonchannel.friday", category: "sensor")
    private var task: Task<Void, Never>?

    public init(server: HookSocketServer, repository: any AgentEventRepository) {
        self.server = server
        self.repository = repository
    }

    /// Abre o socket e começa a gravar. Chamar de novo reinicia.
    public func start() async throws {
        task?.cancel()
        let messages = try await server.start()
        let repository = repository
        let logger = logger
        task = Task {
            for await message in messages {
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

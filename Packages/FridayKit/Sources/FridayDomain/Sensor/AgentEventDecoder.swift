// Resumo: Lê a mensagem que o script de hook manda (linha de cabeçalho com agente e sessão, depois o JSON) e monta o evento.
// Tags: sensor

import Foundation

/// Motivos pelos quais uma mensagem recebida pelo socket não vira evento.
public enum AgentEventDecodingError: Error, Equatable, Sendable {
    case malformedHeader
    case unsupportedAgent
    case invalidSessionID
    case payloadIsNotJSONObject
}

/// Converte bytes do socket em `AgentEvent`. Formato: `<agente> <uuid-da-sessão>\n<JSON do hook>`.
public enum AgentEventDecoder {
    /// Limite de tamanho do alvo (comando ou arquivo) guardado em coluna própria; o JSON bruto fica inteiro.
    static let maxTargetLength = 500

    /// Decodifica uma mensagem completa. Lança se o cabeçalho ou o JSON não forem válidos.
    public static func decode(_ message: Data, receivedAt: Date) throws -> AgentEvent {
        guard let newline = message.firstIndex(of: 0x0A) else { throw AgentEventDecodingError.malformedHeader }
        let header = String(decoding: message[message.startIndex..<newline], as: UTF8.self)
        let parts = header.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count == 2 else { throw AgentEventDecodingError.malformedHeader }
        guard let agent = AgentKind(rawValue: String(parts[0])), agent != .shell else { throw AgentEventDecodingError.unsupportedAgent }
        guard let uuid = UUID(uuidString: String(parts[1])) else { throw AgentEventDecodingError.invalidSessionID }

        let body = message[message.index(after: newline)...]
        guard let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            throw AgentEventDecodingError.payloadIsNotJSONObject
        }
        let input = object["tool_input"] as? [String: Any]
        return AgentEvent(
            sessionID: AgentSessionID(uuid),
            agent: agent,
            kind: AgentEventKind(hookName: object["hook_event_name"] as? String ?? ""),
            occurredAt: receivedAt,
            toolName: object["tool_name"] as? String,
            target: target(from: input),
            rawJSON: String(decoding: body, as: UTF8.self)
        )
    }

    private static func target(from input: [String: Any]?) -> String? {
        guard let input else { return nil }
        for key in ["file_path", "notebook_path", "command", "path", "pattern", "url"] {
            if let value = input[key] as? String, !value.isEmpty { return String(value.prefix(maxTargetLength)) }
        }
        return nil
    }
}

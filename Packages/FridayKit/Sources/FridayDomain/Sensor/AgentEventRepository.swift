// Resumo: Contrato de onde os eventos dos agentes ficam guardados e como a tela os acompanha ao vivo.
// Tags: sensor, persistencia

/// Onde os eventos dos agentes são guardados. Produção usa o banco; teste usa memória.
public protocol AgentEventRepository: Sendable {
    /// Grava o evento e devolve a cópia com `id`.
    @discardableResult func record(_ event: AgentEvent) throws -> AgentEvent
    /// Entrega todos os eventos da sessão, do mais antigo ao mais novo, agora e a cada novo evento.
    func observe(session: AgentSessionID) -> AsyncThrowingStream<[AgentEvent], any Error>
    /// Entrega os `limit` eventos mais recentes de todas as sessões, do mais novo ao mais antigo, agora e a cada mudança.
    func observeRecent(limit: Int) -> AsyncThrowingStream<[AgentEvent], any Error>
}

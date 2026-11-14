// Resumo: Acompanha ao vivo os eventos de uma sessão de agente e o resumo deduzido deles, para o painel da linha do tempo.
// Tags: linha-do-tempo, interface

import FridayDomain
import Observation

/// Eventos e resumo de uma sessão, atualizados conforme o banco muda.
@MainActor
@Observable
public final class SessionTimelineModel {
    public private(set) var events: [AgentEvent] = []
    /// Linhas da linha do tempo, da mais antiga à mais nova, com subagentes seguidos já agrupados.
    public private(set) var entries: [TimelineEntry] = []
    public private(set) var activity = SessionActivity(events: [])
    public private(set) var loadError: String?

    public let session: AgentSessionID
    private let repository: any AgentEventRepository

    public init(session: AgentSessionID, repository: any AgentEventRepository) {
        self.session = session
        self.repository = repository
    }

    /// Espelha os eventos da sessão até a tarefa ser cancelada (use dentro de `.task`).
    public func observe() async {
        do {
            for try await events in repository.observe(session: session) {
                self.events = events
                entries = TimelineProjection.entries(from: events)
                activity = SessionActivity(events: events)
            }
        } catch is CancellationError {
        } catch {
            loadError = error.localizedDescription
        }
    }
}

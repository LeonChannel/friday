// Resumo: Painel da sessão: fase atual, arquivos alterados e a linha do tempo dos eventos do agente, mais recente em cima.
// Tags: linha-do-tempo, interface

import FridayDomain
import SwiftUI

/// Linha do tempo de uma sessão, montada só a partir dos eventos gravados.
public struct SessionTimelineView: View {
    @State private var model: SessionTimelineModel

    public init(model: SessionTimelineModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        List {
            Section {
                row("Fase") { PhaseLabel(phase: model.activity.phase) }
                row("Pedidos") { MonoLabel("\(model.activity.prompts)") }
                row("Ferramentas usadas") { MonoLabel("\(model.activity.toolUses)") }
            } footer: {
                MonoLabel("fonte: \(model.events.count) eventos de hooks")
            }
            if !model.activity.changedFiles.isEmpty {
                Section {
                    ForEach(model.activity.changedFiles, id: \.self) { path in
                        Text((path as NSString).lastPathComponent)
                            .typography(.metadado)
                            .foregroundStyle(Theme.texto)
                            .textSelection(.enabled)
                            .help(path)
                            .listRowBackground(Color.clear)
                    }
                } header: {
                    MonoLabel("Arquivos alterados", kind: .secao)
                }
            }
            Section {
                if model.events.isEmpty {
                    Text("Nenhum evento ainda. Eventos chegam quando o Claude Code roda nesta sessão.")
                        .typography(.secundario)
                        .foregroundStyle(Theme.textoSecundario)
                        .listRowBackground(Color.clear)
                }
                ForEach(model.events.reversed()) { event in
                    EventRow(event: event).listRowBackground(Color.clear)
                }
            } header: {
                MonoLabel("Linha do tempo", kind: .secao)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.superficie)
        .task(id: model.session) { await model.observe() }
    }

    private func row<Value: View>(_ title: String, @ViewBuilder value: () -> Value) -> some View {
        HStack {
            Text(title).typography(.secundario).foregroundStyle(Theme.textoSecundario)
            Spacer()
            value()
        }
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
    }
}

/// Fase da sessão com o ponto da vez: esperando você é limão, trabalhando é coral, iniciando e encerrada são parado.
struct PhaseLabel: View {
    let phase: SessionPhase

    var body: some View {
        switch phase {
        case .starting: TurnBadge(.parado, text: "Iniciando")
        case .working: TurnBadge(.claude, text: "Trabalhando")
        case .waitingForYou: TurnBadge(.voce, text: "Esperando você")
        case .finished: TurnBadge(.parado, text: "Encerrada")
        }
    }
}

struct EventRow: View {
    let event: AgentEvent

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(title).typography(.secundario).foregroundStyle(Theme.texto)
                Spacer()
                Text(event.occurredAt, format: .dateTime.hour().minute().second())
                    .typography(.metadado).foregroundStyle(Theme.textoSecundario)
            }
            if let target = event.target {
                Text(target).typography(.metadado).foregroundStyle(Theme.textoSecundario).lineLimit(2).truncationMode(.middle).textSelection(.enabled)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        switch event.kind {
        case .sessionStart: "Sessão iniciada"
        case .userPromptSubmit: "Você enviou um pedido"
        case .preToolUse: "Vai usar \(event.toolName ?? "ferramenta")"
        case .postToolUse: "Usou \(event.toolName ?? "ferramenta")"
        case .notification: "Aviso do agente"
        case .stop: "Terminou o turno"
        case .subagentStop: "Subagente terminou"
        case .sessionEnd: "Sessão encerrada"
        case .preCompact: "Compactando contexto"
        case .unknown(let name): name
        }
    }
}

#if DEBUG
import FridayInfrastructure

private struct SampleEvents: AgentEventRepository {
    let events: [AgentEvent]
    func record(_ event: AgentEvent) throws -> AgentEvent { event }
    func observe(session: AgentSessionID) -> AsyncThrowingStream<[AgentEvent], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(events)
            continuation.finish()
        }
    }
    func observeRecent(limit: Int) -> AsyncThrowingStream<[AgentEvent], any Error> {
        AsyncThrowingStream { $0.finish() }
    }
}

@MainActor
private func sampleModel(_ kinds: [(AgentEventKind, String?, String?)]) -> SessionTimelineModel {
    let session = AgentSessionID()
    let events = kinds.enumerated().map { index, item in
        AgentEvent(sessionID: session, agent: .claude, kind: item.0, occurredAt: Date(timeIntervalSince1970: 1_800_000_000 + Double(index) * 20), toolName: item.1, target: item.2, rawJSON: "{}")
    }
    return SessionTimelineModel(session: session, repository: SampleEvents(events: events))
}

private let waiting: [(AgentEventKind, String?, String?)] = [
    (.sessionStart, nil, nil), (.userPromptSubmit, nil, nil),
    (.postToolUse, "Edit", "/exemplo/Sources/App.swift"), (.stop, nil, nil),
]
private let working: [(AgentEventKind, String?, String?)] = [(.sessionStart, nil, nil), (.userPromptSubmit, nil, nil), (.preToolUse, "Bash", "swift test")]

#Preview("Esperando você, escuro") {
    SessionTimelineView(model: sampleModel(waiting)).frame(width: 320, height: 420).preferredColorScheme(.dark)
}
#Preview("Esperando você, claro") {
    SessionTimelineView(model: sampleModel(waiting)).frame(width: 320, height: 420).preferredColorScheme(.light)
}
#Preview("Trabalhando, escuro") {
    SessionTimelineView(model: sampleModel(working)).frame(width: 320, height: 420).preferredColorScheme(.dark)
}
#Preview("Encerrada, claro") {
    SessionTimelineView(model: sampleModel(waiting + [(.sessionEnd, nil, nil)])).frame(width: 320, height: 420).preferredColorScheme(.light)
}
#Preview("Vazia, escuro") {
    SessionTimelineView(model: sampleModel([])).frame(width: 320, height: 300).preferredColorScheme(.dark)
}
#endif

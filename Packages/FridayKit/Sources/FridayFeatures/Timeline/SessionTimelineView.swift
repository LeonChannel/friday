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
                LabeledContent("Fase") { PhaseLabel(phase: model.activity.phase) }
                LabeledContent("Pedidos", value: "\(model.activity.prompts)")
                LabeledContent("Ferramentas usadas", value: "\(model.activity.toolUses)")
            } footer: {
                Text("Fonte: \(model.events.count) eventos de hooks")
            }
            if !model.activity.changedFiles.isEmpty {
                Section("Arquivos alterados") {
                    ForEach(model.activity.changedFiles, id: \.self) { path in
                        Text((path as NSString).lastPathComponent)
                            .monospaced()
                            .help(path)
                    }
                }
            }
            Section("Linha do tempo") {
                if model.events.isEmpty {
                    Text("Nenhum evento ainda. Eventos chegam quando o Claude Code roda nesta sessão.")
                        .foregroundStyle(.secondary)
                }
                ForEach(model.events.reversed()) { event in
                    EventRow(event: event)
                }
            }
        }
        .task(id: model.session) { await model.observe() }
    }
}

struct PhaseLabel: View {
    let phase: SessionPhase

    var body: some View {
        switch phase {
        case .starting: Label("Iniciando", systemImage: "circle.dotted")
        case .working: Label("Trabalhando", systemImage: "circle.fill").foregroundStyle(.tint)
        case .waitingForYou: Label("Esperando você", systemImage: "circle.fill").foregroundStyle(.orange)
        case .finished: Label("Encerrada", systemImage: "circle").foregroundStyle(.secondary)
        }
    }
}

struct EventRow: View {
    let event: AgentEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title).font(.callout)
                Spacer()
                Text(event.occurredAt, format: .dateTime.hour().minute().second())
                    .font(.caption).monospaced().foregroundStyle(.secondary)
            }
            if let target = event.target {
                Text(target).font(.caption).monospaced().foregroundStyle(.secondary).lineLimit(2).truncationMode(.middle)
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

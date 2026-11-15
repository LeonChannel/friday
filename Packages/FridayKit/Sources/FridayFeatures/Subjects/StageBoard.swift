// Resumo: Lousa de progresso do assunto: as etapas da jornada lado a lado, cada uma com estado na cor da vez e a nota do que saiu dela.
// Tags: jornadas, assuntos, interface

import FridayDomain
import SwiftUI

/// Etapas da jornada em colunas. Só mostra o estado gravado (`friday etapa`); nada anima.
struct StageBoard: View {
    let activity: ActivityKind?
    let stages: [Stage]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            MonoLabel(header, kind: .secao)
            if stages.isEmpty {
                Text("A jornada deste tipo não tem etapas. Defina em Ajustes › Jornadas (⌘,) para os próximos assuntos.")
                    .typography(.secundario).foregroundStyle(Theme.textoSecundario)
            } else {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                        StageCard(number: index + 1, stage: stage)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(Theme.superficie)
    }

    private var header: String {
        let done = stages.filter { $0.state == .done }.count
        let kind = activity?.displayName ?? "Jornada"
        return stages.isEmpty ? kind : "\(kind) · \(done) de \(stages.count) etapas"
    }
}

/// Uma etapa: número, nome, estado e nota.
private struct StageCard: View {
    let number: Int
    let stage: Stage

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                MonoLabel("\(number)")
                Text(stage.name).typography(.corpo).fontWeight(.semibold)
                    .foregroundStyle(stage.state == .pending ? Theme.textoSecundario : Theme.texto)
                    .lineLimit(1)
            }
            stateLine
            if let note = stage.note {
                Text(note).typography(.secundario).foregroundStyle(Theme.textoSecundario).lineLimit(3).textSelection(.enabled)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: Radius.peca).fill(fill))
        .overlay(border)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("etapa \(number), \(stage.name), \(label)")
    }

    @ViewBuilder
    private var stateLine: some View {
        switch stage.state {
        case .pending: Text(label).typography(.metadado).foregroundStyle(Theme.textoSecundario)
        case .running: TurnBadge(.claude, text: label)
        case .waitingForYou: TurnBadge(.voce, text: label)
        case .done: Text(label).typography(.metadado).foregroundStyle(Theme.textoSecundario)
        }
    }

    private var label: String {
        switch stage.state {
        case .pending: "pendente"
        case .running: "rodando"
        case .waitingForYou: "esperando você"
        case .done: "concluída"
        }
    }

    private var fill: Color {
        switch stage.state {
        case .running: Theme.claudeFundo
        case .waitingForYou: Theme.voceFundo
        case .pending, .done: Theme.superficieElevada
        }
    }

    @ViewBuilder
    private var border: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.peca)
        switch stage.state {
        case .pending: shape.strokeBorder(Theme.linha, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        case .running: shape.strokeBorder(Theme.claudeBorda)
        case .waitingForYou: shape.strokeBorder(Theme.voceBorda)
        case .done: shape.strokeBorder(Theme.linha)
        }
    }
}

#if DEBUG
private let previewStages = [
    Stage(name: "Reproduzir", state: .done, note: "Quebra só com o cache frio."),
    Stage(name: "Causa", state: .running),
    Stage(name: "Correção"),
    Stage(name: "Prova"),
]

#Preview("Lousa, Claude, escuro") {
    StageBoard(activity: .error, stages: previewStages).frame(width: 900).preferredColorScheme(.dark)
}

#Preview("Lousa, você, claro") {
    var stages = previewStages
    stages[1].state = .waitingForYou
    return StageBoard(activity: .error, stages: stages).frame(width: 900).preferredColorScheme(.light)
}

#Preview("Lousa, sem etapas, escuro") {
    StageBoard(activity: .question, stages: []).frame(width: 900).preferredColorScheme(.dark)
}
#endif

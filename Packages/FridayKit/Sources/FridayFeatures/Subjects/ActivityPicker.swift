// Resumo: Escolha do tipo de atividade (erro, teste, tarefa, marco, dúvida) que abre um assunto na Mesa.
// Tags: jornadas, interface

import FridayDomain
import SwiftUI

/// Controle segmentado dos tipos de atividade. Neutro: o tipo escolhido não é vez de ninguém.
struct ActivityPicker: View {
    @Binding var selection: ActivityKind?

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Array(ActivityKind.allCases.enumerated()), id: \.element) { index, kind in
                Button { selection = kind } label: {
                    Text(kind.displayName)
                        .typography(.secundario)
                        .foregroundStyle(selection == kind ? Theme.texto : Theme.textoSecundario)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs + 2)
                        .background(RoundedRectangle(cornerRadius: Radius.botao).fill(selection == kind ? Theme.superficieAtiva : .clear))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                .help("\(kind.summary) (⌘\(index + 1))")
                .accessibilityAddTraits(selection == kind ? .isSelected : [])
            }
        }
        .padding(Spacing.xs)
        .background(RoundedRectangle(cornerRadius: Radius.campo).fill(Theme.superficieElevada))
        .overlay(RoundedRectangle(cornerRadius: Radius.campo).strokeBorder(Theme.linha))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tipo de atividade")
    }
}

#Preview("Tipo, escuro") {
    @Previewable @State var kind: ActivityKind? = .error
    ActivityPicker(selection: $kind).padding(Spacing.xxl).background(Theme.fundo).preferredColorScheme(.dark)
}

#Preview("Tipo, claro") {
    @Previewable @State var kind: ActivityKind? = nil
    ActivityPicker(selection: $kind).padding(Spacing.xxl).background(Theme.fundo).preferredColorScheme(.light)
}

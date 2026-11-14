// Resumo: Estilos de botão do Friday: o comum (superfície elevada com borda) e o principal (limão), um por tela.
// Tags: visual, interface

import SwiftUI

/// Botão comum: `superficieElevada`, borda `linha`, raio 6.
public struct FridayButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .typography(.secundario)
            .foregroundStyle(Theme.texto)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs + 2)
            .background(configuration.isPressed ? Theme.superficieAtiva : Theme.superficieElevada, in: .rect(cornerRadius: Radius.botao))
            .overlay(RoundedRectangle(cornerRadius: Radius.botao).strokeBorder(Theme.linha, lineWidth: 1))
            .opacity(isEnabled ? 1 : 0.5)
    }
}

/// Botão principal: preenchimento `voce`, texto `textoSobreVoce`. Um por tela, e só para ação sua.
public struct FridayPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .typography(.secundario)
            .fontWeight(.semibold)
            .foregroundStyle(Theme.textoSobreVoce)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs + 2)
            .background(Theme.voce.opacity(configuration.isPressed ? 0.8 : 1), in: .rect(cornerRadius: Radius.botao))
            .opacity(isEnabled ? 1 : 0.5)
    }
}

extension ButtonStyle where Self == FridayButtonStyle {
    /// Botão comum do Friday.
    public static var friday: FridayButtonStyle { FridayButtonStyle() }
}

extension ButtonStyle where Self == FridayPrimaryButtonStyle {
    /// Botão principal do Friday.
    public static var fridayPrimary: FridayPrimaryButtonStyle { FridayPrimaryButtonStyle() }
}

private struct ButtonsPreview: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            Button("Abrir terminal") {}.buttonStyle(.friday)
            Button("Passar a vez") {}.buttonStyle(.fridayPrimary)
            Button("Desligado") {}.buttonStyle(.friday).disabled(true)
        }
        .padding(Spacing.xxl)
        .background(Theme.superficie)
    }
}

#Preview("Botões, escuro") { ButtonsPreview().preferredColorScheme(.dark) }
#Preview("Botões, claro") { ButtonsPreview().preferredColorScheme(.light) }

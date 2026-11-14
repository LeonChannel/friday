// Resumo: Ponto de 8 pt que mostra de quem é a vez, cheio (você, Claude) ou vazado (parado), sempre com rótulo para VoiceOver.
// Tags: visual, interface

import SwiftUI

/// Ponto da vez. Use `TurnBadge` quando o texto também aparece.
public struct TurnDot: View {
    let style: TurnStyle

    public init(_ style: TurnStyle) { self.style = style }

    public var body: some View {
        Circle()
            .fill(style.isFilled ? style.dotColor : .clear)
            .overlay(Circle().strokeBorder(style.dotColor, lineWidth: style.isFilled ? 0 : 1.5))
            .frame(width: 8, height: 8)
            .accessibilityLabel(style.label)
    }
}

/// Ponto da vez seguido do texto, na cor da vez.
public struct TurnBadge: View {
    let style: TurnStyle
    let text: String?

    public init(_ style: TurnStyle, text: String? = nil) {
        self.style = style
        self.text = text
    }

    public var body: some View {
        HStack(spacing: Spacing.sm) {
            TurnDot(style).accessibilityHidden(true)
            Text(text ?? style.label)
                .typography(.secundario)
                .foregroundStyle(style.textColor)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Vez, escuro") {
    VStack(alignment: .leading, spacing: Spacing.md) {
        ForEach(TurnStyle.allCases, id: \.self) { TurnBadge($0) }
    }
    .padding(Spacing.xxl)
    .background(Theme.superficie)
    .preferredColorScheme(.dark)
}

#Preview("Vez, claro") {
    VStack(alignment: .leading, spacing: Spacing.md) {
        ForEach(TurnStyle.allCases, id: \.self) { TurnBadge($0) }
    }
    .padding(Spacing.xxl)
    .background(Theme.superficie)
    .preferredColorScheme(.light)
}

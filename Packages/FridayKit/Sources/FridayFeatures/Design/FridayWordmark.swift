// Resumo: A marca do Friday: a palavra "friday" em Geist Mono seguida de um bloco limão parado, no formato de um cursor.
// Tags: visual, interface

import SwiftUI

/// Marca do app. O cursor nunca pisca.
public struct FridayWordmark: View {
    public init() {}

    public var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: Spacing.xs) {
            Text("friday")
                .typography(.marca)
                .foregroundStyle(Theme.texto)
            Rectangle()
                .fill(Theme.voce)
                .frame(width: 8, height: 15)
                .alignmentGuide(.lastTextBaseline) { $0[.bottom] }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Friday")
    }
}

#Preview("Marca") {
    FridayWordmark().padding(Spacing.xxl).background(Theme.superficie)
        .preferredColorScheme(.dark)
}

#Preview("Marca, claro") {
    FridayWordmark().padding(Spacing.xxl).background(Theme.superficie)
        .preferredColorScheme(.light)
}

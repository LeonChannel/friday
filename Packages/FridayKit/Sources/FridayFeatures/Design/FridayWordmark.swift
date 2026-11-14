// Resumo: Marca do Friday: o logo dos dois traços ao lado da palavra friday em Geist.
// Tags: visual

import SwiftUI

/// Marca completa (logo e nome) para o topo da lateral.
public struct FridayWordmark: View {
    public init() {}

    public var body: some View {
        HStack(spacing: Spacing.sm) {
            FridayMark(size: 22)
            Text("friday")
                .typography(.marca)
                .foregroundStyle(Theme.texto)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Friday")
    }
}

#Preview("Marca, escuro") {
    FridayWordmark().padding(Spacing.lg).background(Theme.superficie).preferredColorScheme(.dark)
}

#Preview("Marca, claro") {
    FridayWordmark().padding(Spacing.lg).background(Theme.superficie).preferredColorScheme(.light)
}

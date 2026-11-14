// Resumo: O logo do Friday desenhado com as cores de vez, com o quanto de cada traço já foi escrito (para a animação de abertura).
// Tags: visual

import SwiftUI

/// Logo do Friday. `you` e `claude` vão de 0 a 1: o quanto de cada traço aparece.
public struct FridayMark: View {
    let size: CGFloat
    let you: CGFloat
    let claude: CGFloat

    public init(size: CGFloat, you: CGFloat = 1, claude: CGFloat = 1) {
        self.size = size
        self.you = you
        self.claude = claude
    }

    public var body: some View {
        let width = size * FridayMarkMetrics.strokeRatio
        ZStack {
            FridayYouStroke()
                .trim(from: 0, to: you)
                .stroke(Theme.voce, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            FridayClaudeStroke()
                .trim(from: 0, to: claude)
                .stroke(Theme.claude, style: StrokeStyle(lineWidth: width, lineCap: .round))
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Friday")
    }
}

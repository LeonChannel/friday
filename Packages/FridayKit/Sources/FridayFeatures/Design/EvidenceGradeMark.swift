// Resumo: Marca do grau da evidência desenhada por forma (quadrado cheio medido, </> no código, círculo tracejado inferido), com o texto ao lado.
// Tags: visual, assuntos

import FridayDomain
import SwiftUI

/// Grau da evidência como o guia visual pede: forma, não cor.
public struct EvidenceGradeMark: View {
    let grade: EvidenceGrade

    public init(_ grade: EvidenceGrade) { self.grade = grade }

    public var body: some View {
        HStack(spacing: Spacing.xs) {
            switch grade {
            case .measured:
                Rectangle().fill(Theme.texto).frame(width: 7, height: 7)
            case .inCode:
                Text("</>").typography(.metadado).fontWeight(.semibold).foregroundStyle(Theme.texto)
            case .inferred:
                Circle().strokeBorder(Theme.textoSecundario, style: StrokeStyle(lineWidth: 1, dash: [2, 2])).frame(width: 7, height: 7)
            }
            Text(grade.label)
                .typography(.metadado)
                .italic(grade == .inferred)
                .foregroundStyle(Theme.textoSecundario)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("grau: \(grade.label)")
    }
}

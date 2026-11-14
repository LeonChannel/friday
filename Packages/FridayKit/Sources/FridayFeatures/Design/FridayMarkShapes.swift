// Resumo: Geometria do logo do Friday: o traço do dev (o f que sobe e vira) e o traço do Claude (a barra que atravessa). Fonte única para app, animação e ícone.
// Tags: visual

import SwiftUI

/// Traço do dev: a haste do f, escrita de baixo para cima (a ordem importa para a animação de desenho).
public struct FridayYouStroke: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height)
        let o = CGPoint(x: rect.midX - s / 2, y: rect.midY - s / 2)
        var path = Path()
        path.move(to: CGPoint(x: o.x + s * 0.38, y: o.y + s * 0.84))
        path.addLine(to: CGPoint(x: o.x + s * 0.38, y: o.y + s * 0.42))
        path.addQuadCurve(to: CGPoint(x: o.x + s * 0.74, y: o.y + s * 0.22), control: CGPoint(x: o.x + s * 0.38, y: o.y + s * 0.18))
        return path
    }
}

/// Traço do Claude: a barra que atravessa o f, da esquerda para a direita, com uma onda leve.
public struct FridayClaudeStroke: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height)
        let o = CGPoint(x: rect.midX - s / 2, y: rect.midY - s / 2)
        var path = Path()
        path.move(to: CGPoint(x: o.x + s * 0.22, y: o.y + s * 0.52))
        path.addQuadCurve(to: CGPoint(x: o.x + s * 0.64, y: o.y + s * 0.48), control: CGPoint(x: o.x + s * 0.42, y: o.y + s * 0.56))
        return path
    }
}

/// Espessura do traço em relação ao lado do logo.
public enum FridayMarkMetrics {
    public static let strokeRatio: CGFloat = 0.115
}

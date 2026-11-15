// Resumo: Fundo líquido da tela de seleção de projetos: malha de cor escura com limão e coral ondulando sem parar; parado com "Reduzir movimento".
// Tags: visual, interface

import SwiftUI

/// Malha 4×4: os quatro pontos internos e os das bordas derivam em senoides defasadas, com velocidades diferentes,
/// para o movimento nunca se repetir de um jeito que o olho perceba. Só para telas de passagem, nunca de trabalho.
public struct LiquidBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Segundos por volta do ponto mais lento.
    var period: Double = 9

    public init() {}

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: reduceMotion)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            MeshGradient(width: 4, height: 4, points: points(t), colors: colors(t), smoothsColors: true)
        }
        .background(Theme.fundo)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    /// As manchas de cor também respiram (intensidade sobe e desce), além de se mover.
    private func colors(_ t: Double) -> [Color] {
        let w = 2 * Double.pi / period
        func breathe(_ base: Double, _ phase: Double) -> Double { base * (0.75 + 0.25 * sin(w * 0.6 * t + phase)) }
        let f = Theme.fundo
        return [
            f, Theme.claude.opacity(breathe(0.12, 0)), f, Theme.voce.opacity(breathe(0.10, 1)),
            Theme.voce.opacity(breathe(0.16, 2)), f, Theme.claude.opacity(breathe(0.22, 3)), f,
            f, Theme.voce.opacity(breathe(0.20, 4)), f, Theme.claude.opacity(breathe(0.14, 5)),
            Theme.claude.opacity(breathe(0.10, 6)), f, Theme.voce.opacity(breathe(0.14, 7)), f,
        ]
    }

    /// Cantos fixos, bordas deslizando ao longo do lado, centro passeando nos dois eixos.
    /// Amplitudes de no máximo 0,12: vizinhos ficam a 1/3 de distância e nunca se cruzam (cruzar dobra a malha e cria borda dura).
    private func points(_ t: Double) -> [SIMD2<Float>] {
        let w = 2 * Double.pi / period
        func wave(_ phase: Double, _ amp: Double, _ speed: Double) -> Float { Float(amp * sin(w * speed * t + phase)) }
        let a: Float = 1.0 / 3, b: Float = 2.0 / 3
        return [
            [0, 0], [a + wave(0.0, 0.10, 1.0), 0], [b + wave(1.1, 0.10, 0.8), 0], [1, 0],
            [0, a + wave(2.0, 0.10, 0.9)], [a + wave(0.4, 0.12, 1.3), a + wave(2.7, 0.12, 1.1)], [b + wave(3.3, 0.12, 0.9), a + wave(1.6, 0.12, 1.4)], [1, a + wave(4.1, 0.10, 1.2)],
            [0, b + wave(5.0, 0.10, 1.1)], [a + wave(2.2, 0.12, 1.0), b + wave(4.4, 0.12, 1.2)], [b + wave(5.6, 0.12, 1.4), b + wave(0.9, 0.12, 0.8)], [1, b + wave(3.7, 0.10, 0.9)],
            [0, 1], [a + wave(1.7, 0.10, 1.2), 1], [b + wave(4.8, 0.10, 1.0), 1], [1, 1],
        ]
    }
}

#Preview("Fundo líquido, escuro") { LiquidBackground().frame(width: 900, height: 600).preferredColorScheme(.dark) }
#Preview("Fundo líquido, claro") { LiquidBackground().frame(width: 900, height: 600).preferredColorScheme(.light) }

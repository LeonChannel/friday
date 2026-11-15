// Resumo: Botão vivo da tela de seleção: reconhece o mouse (limão suave e um halo que segue o cursor) e solta um brilho de luz a partir do ponto do clique.
// Tags: visual, interface

import SwiftUI

/// Botão que reage ao mouse. `padded: false` é para linhas que já têm o próprio espaçamento e fundo (como a linha de projeto).
public struct FridayLiveButtonStyle: ButtonStyle {
    var padded: Bool
    var cornerRadius: CGFloat

    public init(padded: Bool = true, cornerRadius: CGFloat = Radius.botao) {
        self.padded = padded
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        LiveButtonBody(configuration: configuration, padded: padded, cornerRadius: cornerRadius)
    }
}

/// Corpo com estado: onde o mouse está, se está em cima e o progresso do brilho do último clique.
private struct LiveButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let padded: Bool
    let cornerRadius: CGFloat
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false
    @State private var pointer: CGPoint?
    @State private var flash: Flash?

    /// Um brilho: onde nasceu e quanto já se espalhou (0 a 1).
    struct Flash: Equatable {
        /// `nil` quando o clique veio do teclado: o brilho nasce no centro.
        var origin: CGPoint?
        var progress: Double
        var id = UUID()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        label
            .background {
                if padded {
                    shape.fill(Theme.superficieElevada)
                }
                shape.fill(Theme.voce.opacity(hovering ? (padded ? 0.06 : 0.04) : 0))
            }
            // Halo que acompanha o cursor dentro do botão, com atraso suave para não parecer colado.
            .overlay {
                GeometryReader { proxy in
                    let size = max(proxy.size.width, proxy.size.height) * 1.4
                    Circle()
                        .fill(RadialGradient(colors: [Theme.voce.opacity(0.14), .clear], center: .center, startRadius: 0, endRadius: size / 2))
                        .frame(width: size, height: size)
                        .position(pointer ?? CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2))
                        .opacity(hovering ? 1 : 0)
                        .animation(.smooth(duration: 0.3), value: pointer)
                }
                .clipShape(shape)
                .allowsHitTesting(false)
            }
            .overlay {
                GeometryReader { proxy in
                    if let flash {
                        let reach = max(proxy.size.width, proxy.size.height) * 2.2
                        Circle()
                            .fill(RadialGradient(colors: [Theme.voce.opacity(0.38), Theme.voce.opacity(0.12), .clear],
                                                 center: .center, startRadius: 0, endRadius: reach / 2))
                            .frame(width: reach * flash.progress, height: reach * flash.progress)
                            .position(flash.origin ?? CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2))
                            .opacity(1 - flash.progress)
                            .blendMode(.plusLighter)
                    }
                }
                .clipShape(shape)
                .allowsHitTesting(false)
            }
            .overlay { shape.strokeBorder(hovering ? Theme.voce.opacity(0.32) : Theme.linha, lineWidth: 1) }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(isEnabled ? 1 : 0.5)
            .contentShape(shape)
            .onContinuousHover { phase in
                switch phase {
                case .active(let location): pointer = location
                case .ended: pointer = nil
                }
            }
            // Entra em 0,35 s e sai mais devagar ainda (0,55 s): a cor chega e vai embora, nunca pisca.
            .onHover { inside in
                withAnimation(.smooth(duration: inside ? 0.35 : 0.55)) { hovering = inside && isEnabled }
            }
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { wasPressed, isPressed in
                if wasPressed && !isPressed { fire() }
            }
    }

    @ViewBuilder
    private var label: some View {
        if padded {
            configuration.label
                .typography(.secundario)
                .foregroundStyle(hovering ? Theme.voceTexto : Theme.texto)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs + 2)
        } else {
            configuration.label
        }
    }

    /// Brilho a partir do ponto do clique (ou do centro, se veio do teclado). Com "Reduzir movimento", só um lampejo sem crescer.
    private func fire() {
        let start = Flash(origin: pointer, progress: reduceMotion ? 0.6 : 0)
        flash = start
        withAnimation(.easeOut(duration: reduceMotion ? 0.3 : 0.9)) { flash?.progress = 1 } completion: {
            if flash?.id == start.id { flash = nil }
        }
    }
}

extension ButtonStyle where Self == FridayLiveButtonStyle {
    /// Botão vivo: reage ao mouse e acende no clique. Só em telas de passagem (seleção de projetos).
    public static var fridayLive: FridayLiveButtonStyle { FridayLiveButtonStyle() }
    /// Linha viva (sem espaçamento nem fundo próprios), com o raio da peça.
    public static var fridayLiveRow: FridayLiveButtonStyle { FridayLiveButtonStyle(padded: false, cornerRadius: Radius.peca) }
}

#Preview("Botão vivo") {
    HStack(spacing: Spacing.sm) {
        Button("Abrir pasta…", systemImage: "folder") {}.buttonStyle(.fridayLive)
        Button("Clonar repositório…", systemImage: "arrow.down.circle") {}.buttonStyle(.fridayLive)
    }
    .padding(Spacing.huge)
    .background(LiquidBackground())
    .preferredColorScheme(.dark)
}

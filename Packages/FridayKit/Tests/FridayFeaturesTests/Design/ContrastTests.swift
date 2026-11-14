// Resumo: Calcula a razão de contraste WCAG dos pares de texto do guia visual e falha se algum ficar abaixo do valor anotado.
// Tags: visual, testes

import Foundation
import Testing
@testable import FridayFeatures

@Suite("Contraste WCAG")
struct ContrastTests {
    /// Par de texto sobre fundo, na aparência dada, com a razão mínima anotada em `docs/VISUAL.md`.
    struct Pair: CustomTestStringConvertible, Sendable {
        let text: ThemeToken
        let background: ThemeToken
        let appearance: ThemeAppearance
        let minimum: Double
        var testDescription: String { "\(text) sobre \(background) (\(appearance))" }
    }

    static let pairs: [Pair] = [
        Pair(text: .textoSecundario, background: .superficie, appearance: .dark, minimum: 6.9),
        Pair(text: .textoSecundario, background: .superficie, appearance: .light, minimum: 6.7),
        Pair(text: .voceTexto, background: .superficie, appearance: .light, minimum: 6.8),
        Pair(text: .claudeTexto, background: .superficie, appearance: .light, minimum: 6.0),
        Pair(text: .textoSobreVoce, background: .voce, appearance: .dark, minimum: 13),
        Pair(text: .textoSobreVoce, background: .voce, appearance: .light, minimum: 13),
    ]

    /// O guia anota uma casa decimal; a tolerância cobre só o arredondamento.
    static let rounding = 0.06

    @Test(arguments: pairs)
    func meetsRatioNotedInGuide(pair: Pair) {
        let ratio = ContrastRatio.between(pair.text.hex(pair.appearance), pair.background.hex(pair.appearance))
        #expect(ratio >= pair.minimum - Self.rounding, "razão \(ratio) abaixo de \(pair.minimum)")
    }

    @Test func allTextOverMainSurfacesPassesAA() {
        let texts: [ThemeToken] = [.texto, .textoSecundario, .voceTexto, .claudeTexto, .erro]
        let surfaces: [ThemeToken] = [.fundo, .superficie, .superficieElevada]
        for appearance in ThemeAppearance.allCases {
            for text in texts {
                for surface in surfaces {
                    let ratio = ContrastRatio.between(text.hex(appearance), surface.hex(appearance))
                    #expect(ratio >= 4.5, "\(text) sobre \(surface) em \(appearance): \(ratio)")
                }
            }
        }
    }

    @Test func ratioMatchesKnownWCAGExtremes() {
        #expect(abs(ContrastRatio.between(0x000000, 0xFFFFFF) - 21) < 0.001)
        #expect(abs(ContrastRatio.between(0x777777, 0x777777) - 1) < 0.001)
    }
}

/// Razão de contraste WCAG 2.x entre duas cores `0xRRGGBB`.
enum ContrastRatio {
    static func between(_ a: UInt32, _ b: UInt32) -> Double {
        let (high, low) = (max(luminance(a), luminance(b)), min(luminance(a), luminance(b)))
        return (high + 0.05) / (low + 0.05)
    }

    static func luminance(_ hex: UInt32) -> Double {
        func channel(_ shift: UInt32) -> Double {
            let c = Double((hex >> shift) & 0xFF) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0)
    }
}

// Resumo: Prova que todo token de cor tem as duas aparências, que os valores batem com o guia visual e que as opacidades das cores de vez estão certas.
// Tags: visual, testes

import AppKit
import Testing
@testable import FridayFeatures

@Suite("Tokens de cor")
struct ThemeTokenTests {
    @Test func hasFourteenTokensFromTheGuide() {
        #expect(ThemeToken.allCases.count == 14)
    }

    @Test func everyTokenResolvesToItsHexInBothAppearances() throws {
        for token in ThemeToken.allCases {
            for (appearanceName, appearance) in [(NSAppearance.Name.darkAqua, ThemeAppearance.dark), (.aqua, .light)] {
                let resolved = try rgb(of: token, in: appearanceName)
                let expected = token.hex(appearance)
                #expect(resolved == expected, "\(token) em \(appearance)")
            }
        }
    }

    @Test func tokensThatShouldDifferDoDifferBetweenAppearances() {
        let same: Set<ThemeToken> = [.textoSobreVoce]
        for token in ThemeToken.allCases where !same.contains(token) {
            #expect(token.hex(.dark) != token.hex(.light), "\(token) deveria mudar entre escuro e claro")
        }
        #expect(ThemeToken.textoSobreVoce.hex(.dark) == ThemeToken.textoSobreVoce.hex(.light))
    }

    @Test func referenceValuesMatchGuideDarkColumn() {
        #expect(ThemeToken.fundo.hex(.dark) == 0x0E0F11)
        #expect(ThemeToken.voce.hex(.dark) == 0xC8F169)
        #expect(ThemeToken.claude.hex(.dark) == 0xFF8A65)
        #expect(ThemeToken.erro.hex(.light) == 0xC42B2B)
    }

    @Test func turnColorsUseGuideOpacities() {
        #expect(Theme.Opacity.voceFundo == 0.08)
        #expect(Theme.Opacity.claudeFundo == 0.10)
        #expect(Theme.Opacity.borda == 0.35)
    }

    @Test func spacingScaleAndRadiiFollowTheGuide() {
        #expect(Spacing.scale == [4, 8, 12, 16, 20, 24, 32, 40])
        #expect([Radius.tecla, Radius.botao, Radius.campo, Radius.peca, Radius.bloco] == [4, 6, 8, 10, 12])
    }

    @Test func everyTurnHasLabelAndOnlyIdleIsHollow() {
        #expect(TurnStyle.allCases.map(\.label) == ["Sua vez", "Vez do Claude", "parado"])
        #expect(TurnStyle.allCases.filter { !$0.isFilled } == [.parado])
    }

    private func rgb(of token: ThemeToken, in name: NSAppearance.Name) throws -> UInt32 {
        let appearance = try #require(NSAppearance(named: name))
        var value: UInt32 = 0
        appearance.performAsCurrentDrawingAppearance {
            let color = token.nsColor.usingColorSpace(.sRGB) ?? .black
            let r = UInt32((color.redComponent * 255).rounded())
            let g = UInt32((color.greenComponent * 255).rounded())
            let b = UInt32((color.blueComponent * 255).rounded())
            value = (r << 16) | (g << 8) | b
        }
        return value
    }
}

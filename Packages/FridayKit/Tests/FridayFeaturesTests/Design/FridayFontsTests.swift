// Resumo: Prova que as fontes Geist e Geist Mono embarcadas são registradas e ficam disponíveis, e que cada papel tipográfico aponta para uma fonte existente.
// Tags: visual, testes

import AppKit
import Testing
@testable import FridayFeatures

@Suite("Fontes embarcadas")
struct FridayFontsTests {
    @Test func registersEveryBundledFontWithoutFailures() {
        let report = FridayFonts.register()
        #expect(report.failed.isEmpty, "falharam: \(report.failed)")
        #expect(report.registered == 4)
    }

    @Test func familiesAreAvailableAfterRegistration() {
        FridayFonts.register()
        let families = NSFontManager.shared.availableFontFamilies
        #expect(families.contains("Geist"))
        #expect(families.contains("Geist Mono"))
    }

    @Test func everyTypographyRoleResolvesToARealFont() {
        FridayFonts.register()
        for role in Typography.allCases {
            let font = NSFont(name: role.postScriptName, size: role.size)
            #expect(font != nil, "\(role) -> \(role.postScriptName)")
            #expect(font?.familyName == (role.isMono ? "Geist Mono" : "Geist"))
        }
    }

    @Test func terminalFontIsGeistMono() {
        #expect(Typography.terminalFont().familyName == "Geist Mono")
    }

    @Test func sectionLabelIsUppercaseAndOthersAreNot() {
        #expect(Typography.allCases.filter(\.isUppercase) == [.rotuloSecao])
    }
}

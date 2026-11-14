// Resumo: Tabela de cores do Friday: cada token com o valor hexadecimal nas aparências escura e clara, única fonte de cor do app.
// Tags: visual, interface

import AppKit
import SwiftUI

/// Aparência para a qual um token de cor é resolvido.
public enum ThemeAppearance: CaseIterable, Sendable {
    case dark, light
}

/// Cada cor de `docs/VISUAL.md`, com os dois valores. O escuro é a referência.
public enum ThemeToken: CaseIterable, Sendable {
    case fundo, superficie, superficieElevada, superficieAtiva, linha
    case texto, textoSecundario, concluido
    case voce, voceTexto, textoSobreVoce
    case claude, claudeTexto
    case erro

    /// Valor `0xRRGGBB` do token na aparência pedida.
    public func hex(_ appearance: ThemeAppearance) -> UInt32 {
        let pair: (dark: UInt32, light: UInt32) = switch self {
        case .fundo: (0x0E0F11, 0xEEF0F2)
        case .superficie: (0x15171A, 0xFFFFFF)
        case .superficieElevada: (0x1C1F23, 0xF6F7F8)
        case .superficieAtiva: (0x262A30, 0xE3E6EA)
        case .linha: (0x2C3036, 0xDADDE2)
        case .texto: (0xECEDEE, 0x111316)
        case .textoSecundario: (0x9BA1A8, 0x565D66)
        case .concluido: (0x5C636B, 0x9AA0A8)
        case .voce: (0xC8F169, 0xB8E94A)
        case .voceTexto: (0xC8F169, 0x3F6600)
        case .textoSobreVoce: (0x11140A, 0x11140A)
        case .claude: (0xFF8A65, 0xF26B43)
        case .claudeTexto: (0xFF9D7E, 0xB23A12)
        case .erro: (0xFF6B6B, 0xC42B2B)
        }
        return appearance == .dark ? pair.dark : pair.light
    }

    /// Cor que troca sozinha entre escuro e claro conforme a aparência de quem a desenha.
    public var nsColor: NSColor {
        let dark = hex(.dark), light = hex(.light)
        return NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        }
    }

    /// Mesma cor para SwiftUI.
    public var color: Color { Color(nsColor: nsColor) }
}

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

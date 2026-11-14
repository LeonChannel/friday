// Resumo: Papéis tipográficos do Friday (Geist e Geist Mono) ligados ao tamanho de texto do usuário.
// Tags: visual, interface

import AppKit
import SwiftUI

/// Um papel por linha da tabela de tipografia do guia visual.
public enum Typography: CaseIterable, Sendable {
    case tituloTela, tituloAssunto, corpo, secundario, rotuloSecao, metadado, numeroDestaque
    /// Palavra `friday` ao lado do logo na lateral.
    case marca
    /// Palavra `friday` grande, na abertura do app.
    case marcaAbertura

    var postScriptName: String {
        switch self {
        case .tituloTela, .tituloAssunto, .marca, .marcaAbertura: FridayFonts.Name.semibold
        case .corpo, .secundario: FridayFonts.Name.regular
        case .rotuloSecao, .numeroDestaque: FridayFonts.Name.monoSemibold
        case .metadado: FridayFonts.Name.monoRegular
        }
    }

    /// Tamanho em pontos no tamanho de texto padrão.
    public var size: CGFloat {
        switch self {
        case .tituloTela: 26
        case .tituloAssunto: 22
        case .corpo: 13
        case .secundario: 12
        case .rotuloSecao: 10.5
        case .metadado: 11
        case .numeroDestaque: 30
        case .marca: 17
        case .marcaAbertura: 44
        }
    }

    /// Estilo do sistema que escala o papel quando o usuário muda o tamanho do texto.
    public var relativeStyle: Font.TextStyle {
        switch self {
        case .tituloTela, .marcaAbertura: .largeTitle
        case .tituloAssunto, .numeroDestaque: .title
        case .corpo: .body
        case .marca: .headline
        case .secundario: .callout
        case .rotuloSecao, .metadado: .caption
        }
    }

    /// Espaçamento entre letras como fração do tamanho (−2% é −0,02).
    public var tracking: CGFloat {
        switch self {
        case .tituloTela: -0.02
        case .numeroDestaque: -0.03
        case .marca, .marcaAbertura: -0.035
        case .rotuloSecao: 0.08
        default: 0
        }
    }

    public var isUppercase: Bool { self == .rotuloSecao }
    public var isMono: Bool { self == .rotuloSecao || self == .metadado || self == .numeroDestaque }

    /// Fonte SwiftUI do papel. Sem a Geist registrada, o SwiftUI usa a fonte do sistema.
    public var font: Font {
        FridayFonts.register()
        return .custom(postScriptName, size: size, relativeTo: relativeStyle)
    }

    /// Fonte do terminal embutido: Geist Mono, ou mono do sistema se a fonte faltar.
    public static func terminalFont(size: CGFloat = 13) -> NSFont {
        FridayFonts.register()
        return NSFont(name: FridayFonts.Name.monoRegular, size: size)
            ?? .monospacedSystemFont(ofSize: size, weight: .regular)
    }
}

private struct TypographyModifier: ViewModifier {
    let role: Typography

    func body(content: Content) -> some View {
        content
            .font(role.font)
            .tracking(role.tracking * role.size)
            .textCase(role.isUppercase ? .uppercase : nil)
    }
}

extension View {
    /// Aplica um papel tipográfico (fonte, tracking e caixa).
    public func typography(_ role: Typography) -> some View {
        modifier(TypographyModifier(role: role))
    }
}

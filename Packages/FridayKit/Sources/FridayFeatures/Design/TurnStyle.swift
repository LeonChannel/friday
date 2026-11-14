// Resumo: Como cada vez (sua, do Claude, parado) aparece na tela: cor, texto e se o ponto é cheio ou vazado.
// Tags: visual, interface

import SwiftUI

/// Apresentação da vez. Tipo local de visual; quem calcula a vez de verdade liga a este enum.
public enum TurnStyle: CaseIterable, Sendable {
    case voce, claude, parado

    /// Texto curto que acompanha o ponto; cor nunca é a única pista.
    public var label: String {
        switch self {
        case .voce: "Sua vez"
        case .claude: "Vez do Claude"
        case .parado: "parado"
        }
    }

    /// Cor do ponto.
    public var dotColor: Color {
        switch self {
        case .voce: Theme.voce
        case .claude: Theme.claude
        case .parado: Theme.textoSecundario
        }
    }

    /// Cor para texto na cor da vez.
    public var textColor: Color {
        switch self {
        case .voce: Theme.voceTexto
        case .claude: Theme.claudeTexto
        case .parado: Theme.textoSecundario
        }
    }

    /// Parado é ponto vazado; as outras vezes são cheias.
    public var isFilled: Bool { self != .parado }
}

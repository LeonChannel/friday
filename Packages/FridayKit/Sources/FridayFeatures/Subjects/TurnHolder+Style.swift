// Resumo: Liga a vez calculada do assunto ao estilo visual da vez (limão você, coral Claude, vazado parado).
// Tags: assuntos, visual

import FridayDomain

extension TurnStyle {
    /// Estilo visual de quem está com a vez.
    public init(_ holder: TurnHolder) {
        switch holder {
        case .you: self = .voce
        case .claude: self = .claude
        case .idle: self = .parado
        }
    }
}

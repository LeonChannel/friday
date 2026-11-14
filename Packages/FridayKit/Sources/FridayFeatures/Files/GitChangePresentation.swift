// Resumo: Como cada tipo de alteração do git aparece na tela: letra, texto para VoiceOver e cor do tema.
// Tags: git, interface

import FridayDomain
import SwiftUI

extension GitChangeKind {
    /// Letra curta mostrada ao lado do arquivo.
    var badge: String {
        switch self {
        case .modified: "M"
        case .added: "A"
        case .deleted: "D"
        case .renamed: "R"
        case .untracked: "?"
        case .conflicted: "U"
        }
    }

    /// Texto lido pelo VoiceOver e usado em dicas.
    var accessibilityText: String {
        switch self {
        case .modified: "modificado"
        case .added: "adicionado"
        case .deleted: "apagado"
        case .renamed: "renomeado"
        case .untracked: "não rastreado"
        case .conflicted: "em conflito"
        }
    }

    /// Só erro tem cor: apagado e conflito. O resto é neutro; a letra já diz o tipo.
    var tint: Color {
        switch self {
        case .deleted, .conflicted: Theme.erro
        case .modified, .added, .renamed, .untracked: Theme.textoSecundario
        }
    }
}

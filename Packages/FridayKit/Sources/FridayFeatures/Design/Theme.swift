// Resumo: Cores prontas para uso nas views (fundos, textos, cores de vez e suas versões com opacidade); nenhuma view escreve hexadecimal.
// Tags: visual, interface

import SwiftUI

/// Acesso às cores do tema. As versões com opacidade das cores de vez vivem aqui, não nas views.
public enum Theme {
    public static let fundo = ThemeToken.fundo.color
    public static let superficie = ThemeToken.superficie.color
    public static let superficieElevada = ThemeToken.superficieElevada.color
    public static let superficieAtiva = ThemeToken.superficieAtiva.color
    public static let linha = ThemeToken.linha.color
    public static let texto = ThemeToken.texto.color
    public static let textoSecundario = ThemeToken.textoSecundario.color
    public static let concluido = ThemeToken.concluido.color
    public static let voce = ThemeToken.voce.color
    public static let voceTexto = ThemeToken.voceTexto.color
    public static let textoSobreVoce = ThemeToken.textoSobreVoce.color
    public static let claude = ThemeToken.claude.color
    public static let claudeTexto = ThemeToken.claudeTexto.color
    public static let erro = ThemeToken.erro.color

    /// Fundo da peça ou do trilho que espera você (`voce` a 8%).
    public static let voceFundo = voce.opacity(Opacity.voceFundo)
    /// Borda de um elemento seu (`voce` a 35%).
    public static let voceBorda = voce.opacity(Opacity.borda)
    /// Fundo de algo que é do Claude (`claude` a 10%).
    public static let claudeFundo = claude.opacity(Opacity.claudeFundo)
    /// Borda de um elemento do Claude (`claude` a 35%).
    public static let claudeBorda = claude.opacity(Opacity.borda)

    /// Opacidades de `docs/VISUAL.md`, expostas para o teste conferir.
    public enum Opacity {
        public static let voceFundo = 0.08
        public static let claudeFundo = 0.10
        public static let borda = 0.35
    }
}

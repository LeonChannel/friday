// Resumo: Escala de espaçamento de 4 em 4 pontos usada em todas as telas.
// Tags: visual, interface

import CoreGraphics

/// Escala de espaçamento do guia visual. Nenhum número fora dela.
public enum Spacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 20
    public static let xxl: CGFloat = 24
    public static let xxxl: CGFloat = 32
    public static let huge: CGFloat = 40

    /// Todos os valores da escala, em ordem.
    public static let scale: [CGFloat] = [xs, sm, md, lg, xl, xxl, xxxl, huge]
}

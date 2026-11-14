// Resumo: Raios de canto permitidos no Friday, um por tipo de elemento.
// Tags: visual, interface

import CoreGraphics

/// Raios do guia visual. A pílula (raio total) é só do indicador de vez e usa `Capsule`.
public enum Radius {
    /// Tecla e chip.
    public static let tecla: CGFloat = 4
    /// Botão e controle pequeno.
    public static let botao: CGFloat = 6
    /// Nota, campo e controle segmentado.
    public static let campo: CGFloat = 8
    /// Peça do mapa e item da mesa.
    public static let peca: CGFloat = 10
    /// Bloco e campo de comando.
    public static let bloco: CGFloat = 12
}

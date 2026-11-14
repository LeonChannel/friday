// Resumo: Rótulo em Geist Mono para metadado (caminho, atalho, contagem) e para título de seção em maiúsculas.
// Tags: visual, interface

import SwiftUI

/// Rótulo mono. `.secao` vira maiúsculo com tracking aberto; `.metadado` é texto corrido pequeno.
public struct MonoLabel: View {
    public enum Kind: Sendable { case secao, metadado }

    let text: String
    let kind: Kind

    public init(_ text: String, kind: Kind = .metadado) {
        self.text = text
        self.kind = kind
    }

    public var body: some View {
        Text(text)
            .typography(kind == .secao ? .rotuloSecao : .metadado)
            .foregroundStyle(Theme.textoSecundario)
    }
}

private struct MonoLabelPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            MonoLabel("Arquivos alterados", kind: .secao)
            MonoLabel("Sources/App.swift  ⌘↵")
        }
        .padding(Spacing.xxl)
        .background(Theme.superficie)
    }
}

#Preview("Rótulo mono, escuro") { MonoLabelPreview().preferredColorScheme(.dark) }
#Preview("Rótulo mono, claro") { MonoLabelPreview().preferredColorScheme(.light) }

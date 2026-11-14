// Resumo: Linha de um projeto na lateral (nome e caminho) e os rótulos e ícones do tipo de projeto.
// Tags: projetos, interface

import FridayDomain
import SwiftUI

/// Linha de projeto na lateral: nome e caminho em mono.
struct ProjectRow: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(project.name)
                .typography(.corpo)
                .foregroundStyle(Theme.texto)
                .lineLimit(1)
            Text(project.path)
                .typography(.metadado)
                .foregroundStyle(Theme.textoSecundario)
                .lineLimit(1)
                .truncationMode(.head)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(project.name), \(project.kind.label)")
    }
}

extension ProjectKind {
    var symbolName: String {
        switch self {
        case .git: "arrow.triangle.branch"
        case .folder: "folder"
        }
    }

    var label: String {
        switch self {
        case .git: "Repositório git"
        case .folder: "Pasta"
        }
    }
}

// Resumo: Resumo do git do projeto: branch, quantos commits à frente ou atrás do remoto e quantos arquivos estão alterados.
// Tags: git, interface

import FridayDomain
import SwiftUI

/// Faixa com o essencial do git. Sem repositório, diz isso em vez de sumir.
public struct GitSummaryView: View {
    let status: GitStatus?

    public init(status: GitStatus?) {
        self.status = status
    }

    public var body: some View {
        Group {
            if let status {
                HStack(spacing: Spacing.md) {
                    Text(status.branch ?? "HEAD solto")
                        .typography(.metadado)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.texto)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                        .accessibilityLabel("Branch \(status.branch ?? "HEAD solto")")
                    if let ahead = status.ahead, let behind = status.behind, ahead > 0 || behind > 0 {
                        HStack(spacing: Spacing.sm) {
                            if ahead > 0 { MonoLabel("↑\(ahead)").accessibilityLabel("\(ahead) à frente do remoto") }
                            if behind > 0 { MonoLabel("↓\(behind)").accessibilityLabel("\(behind) atrás do remoto") }
                        }
                    }
                    Spacer()
                    MonoLabel(changesText(status.changes.count))
                }
            } else {
                MonoLabel("Sem git nesta pasta")
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Theme.superficie)
    }

    private func changesText(_ count: Int) -> String {
        switch count {
        case 0: "Sem alterações"
        case 1: "1 alterado"
        default: "\(count) alterados"
        }
    }
}

private struct GitSummaryPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GitSummaryView(status: GitStatus(branch: "fase/visual", upstream: "origin/main", ahead: 2, behind: 1, changes: [
                GitFileChange(path: "a.swift", kind: .modified), GitFileChange(path: "b.swift", kind: .untracked),
            ]))
            GitSummaryView(status: GitStatus(branch: "main"))
            GitSummaryView(status: GitStatus(branch: nil, changes: [GitFileChange(path: "a", kind: .added)]))
            GitSummaryView(status: nil)
        }
        .frame(width: 360)
        .background(Theme.superficie)
    }
}

#Preview("Resumo do git, escuro") { GitSummaryPreview().preferredColorScheme(.dark) }
#Preview("Resumo do git, claro") { GitSummaryPreview().preferredColorScheme(.light) }

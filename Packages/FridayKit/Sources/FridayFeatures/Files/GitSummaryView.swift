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
        if let status {
            HStack(spacing: 12) {
                Label(status.branch ?? "HEAD solto", systemImage: "arrow.triangle.branch")
                    .font(.headline)
                    .accessibilityLabel("Branch \(status.branch ?? "HEAD solto")")
                if let ahead = status.ahead, let behind = status.behind, ahead > 0 || behind > 0 {
                    HStack(spacing: 8) {
                        if ahead > 0 { Label("\(ahead)", systemImage: "arrow.up").accessibilityLabel("\(ahead) à frente do remoto") }
                        if behind > 0 { Label("\(behind)", systemImage: "arrow.down").accessibilityLabel("\(behind) atrás do remoto") }
                    }
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Text(changesText(status.changes.count))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else {
            Label("Sem git nesta pasta", systemImage: "arrow.triangle.branch")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func changesText(_ count: Int) -> String {
        switch count {
        case 0: "Sem alterações"
        case 1: "1 alterado"
        default: "\(count) alterados"
        }
    }
}

#Preview("Resumo do git") {
    VStack(alignment: .leading, spacing: 16) {
        GitSummaryView(status: GitStatus(branch: "fase/pastas", upstream: "origin/main", ahead: 2, behind: 1, changes: [
            GitFileChange(path: "a.swift", kind: .modified), GitFileChange(path: "b.swift", kind: .untracked),
        ]))
        GitSummaryView(status: GitStatus(branch: "main"))
        GitSummaryView(status: GitStatus(branch: nil, changes: [GitFileChange(path: "a", kind: .added)]))
        GitSummaryView(status: nil)
    }
    .padding()
    .frame(width: 420)
}

#Preview("Resumo do git, escuro") {
    GitSummaryView(status: GitStatus(branch: "main", upstream: "origin/main", ahead: 1, behind: 0, changes: []))
        .padding()
        .frame(width: 420)
        .preferredColorScheme(.dark)
}

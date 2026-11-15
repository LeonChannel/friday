// Resumo: Cartão de um item do backlog no quadro: código, quem anotou, título, onde mora com o grau, prioridade alta e para onde foi levado.
// Tags: backlog, interface

import FridayDomain
import SwiftUI

/// Um item do quadro de bugs. Coral só marca o que o Claude anotou; o resto é neutro.
struct BacklogCard: View {
    let item: BacklogItem
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                MonoLabel(code).textSelection(.enabled)
                if item.priority >= .high {
                    Text(item.priority.label).typography(.metadado).fontWeight(.semibold).foregroundStyle(Theme.texto)
                }
                Spacer(minLength: 0)
                if item.author == .claude {
                    HStack(spacing: Spacing.xs) {
                        TurnDot(.claude)
                        Text("Claude").typography(.metadado).foregroundStyle(Theme.claudeTexto)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("anotado pelo Claude")
                }
            }
            Text(item.title).typography(.corpo).foregroundStyle(Theme.texto).lineLimit(3).fixedSize(horizontal: false, vertical: true)
            if let location = item.location {
                MonoLabel(location).lineLimit(1).truncationMode(.middle).help(location)
            }
            if item.grade != nil || item.externalRef != nil {
                HStack(spacing: Spacing.sm) {
                    if let grade = item.grade { EvidenceGradeMark(grade) }
                    Spacer(minLength: 0)
                    if let externalRef = item.externalRef { MonoLabel("→ \(externalRef)").lineLimit(1).help("Levado para \(externalRef)") }
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.peca).fill(Theme.superficie))
        .overlay(RoundedRectangle(cornerRadius: Radius.peca).strokeBorder(Theme.linha))
        .contentShape(RoundedRectangle(cornerRadius: Radius.peca))
    }
}

/// Menu de contexto comum ao quadro e à árvore: mover, copiar o código.
struct BacklogItemMenu: View {
    let item: BacklogItem
    let code: String
    let move: (BacklogStatus) -> Void

    var body: some View {
        Menu("Mover para") {
            ForEach(BacklogStatus.allCases, id: \.self) { status in
                Button(status.label) { move(status) }.disabled(status == item.status)
            }
        }
        Button("Copiar código") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(code, forType: .string)
        }
        if item.status != .discarded {
            Divider()
            Button("Descartar") { move(.discarded) }
        }
    }
}

#if DEBUG
private let previewItems: [BacklogItem] = [
    try! BacklogItem(id: 1, projectID: 1, number: 7, kind: .bug, title: "Token de sessão aparece no log de erro do login", location: "Sources/Auth/LoginService.swift:88", grade: .inCode, priority: .critical, author: .claude, createdAt: .now),
    try! BacklogItem(id: 2, projectID: 1, number: 9, kind: .bug, title: "Lista pisca ao trocar de projeto", priority: .medium, status: .doing, author: .you, externalRef: "AB#68134", createdAt: .now),
]

#Preview("Cartão, escuro") {
    VStack(spacing: Spacing.md) { ForEach(previewItems) { BacklogCard(item: $0, code: "FRI-\($0.number)") } }
        .padding(Spacing.xxl).frame(width: 280).background(Theme.fundo).preferredColorScheme(.dark)
}

#Preview("Cartão, claro") {
    VStack(spacing: Spacing.md) { ForEach(previewItems) { BacklogCard(item: $0, code: "FRI-\($0.number)") } }
        .padding(Spacing.xxl).frame(width: 280).background(Theme.fundo).preferredColorScheme(.light)
}
#endif

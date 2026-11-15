// Resumo: Quadro de bugs do projeto: colunas Novo, A fazer, Fazendo, Revisão e Feito, arrastar para mover, anotar um bug à mão e abrir a ficha.
// Tags: backlog, interface

import FridayDomain
import SwiftUI

/// Kanban dos bugs. "Novo" é a triagem: o que o Claude anotou sem interromper você.
struct BugBoardView: View {
    let model: BacklogModel
    @State private var newTitle = ""
    @State private var errorMessage: String?
    @State private var opened: BacklogItem?
    @State private var targeted: BacklogStatus?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Bugs").typography(.tituloTela).foregroundStyle(Theme.texto)
                MonoLabel(summary)
            }
            captureBar
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Spacing.lg) {
                    ForEach(model.board, id: \.status) { column in
                        self.column(column.status, items: column.items)
                    }
                }
                .padding(.bottom, Spacing.lg)
            }
            .scrollIndicators(.automatic)
        }
        .padding(Spacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.fundo)
        .task { await model.observe() }
        .sheet(item: $opened) { item in BacklogItemSheet(model: model, item: item) }
    }

    /// De onde sai cada número: contagem dos bugs gravados.
    private var summary: String {
        let open = model.items.count { $0.kind == .bug && !$0.status.isClosed }
        var parts = ["\(open) abertos", "\(model.newBugCount) para triar"]
        if model.discardedBugCount > 0 { parts.append("\(model.discardedBugCount) descartados") }
        return parts.joined(separator: " · ")
    }

    private var captureBar: some View {
        HStack(spacing: Spacing.md) {
            TextField("Anotar um bug para depois…", text: $newTitle)
                .textFieldStyle(.plain)
                .typography(.corpo)
                .foregroundStyle(Theme.texto)
                .onSubmit(create)
            Button("Anotar", action: create)
                .buttonStyle(.fridayPrimary)
                .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(Spacing.md)
        .background(RoundedRectangle(cornerRadius: Radius.bloco).fill(Theme.superficieElevada))
        .overlay(RoundedRectangle(cornerRadius: Radius.bloco).strokeBorder(Theme.linha))
        .overlay(alignment: .bottomLeading) {
            if let errorMessage {
                Text(errorMessage).typography(.metadado).foregroundStyle(Theme.erro).offset(y: 22)
            }
        }
    }

    private func column(_ status: BacklogStatus, items: [BacklogItem]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            MonoLabel("\(status.label) · \(items.count)", kind: .secao)
            if items.isEmpty {
                Text(emptyText(status))
                    .typography(.secundario)
                    .foregroundStyle(Theme.textoSecundario)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: Radius.peca).strokeBorder(Theme.linha, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
            }
            ForEach(items) { item in
                let code = model.code(item)
                Button { opened = item } label: { BacklogCard(item: item, code: code) }
                    .buttonStyle(.plain)
                    .draggable(code)
                    .contextMenu { BacklogItemMenu(item: item, code: code) { move(item, to: $0) } }
                    .accessibilityHint("Abre a ficha. Arraste para outra coluna para mudar o estado.")
            }
            Spacer(minLength: Spacing.huge)
        }
        .padding(Spacing.sm)
        .frame(width: 248, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: Radius.bloco)
                .strokeBorder(targeted == status ? Theme.textoSecundario : .clear, lineWidth: 1)
        )
        .dropDestination(for: String.self) { codes, _ in
            model.move(codes: codes, to: status)
        } isTargeted: { inside in
            targeted = inside ? status : (targeted == status ? nil : targeted)
        }
    }

    private func emptyText(_ status: BacklogStatus) -> String {
        switch status {
        case .new: "Nada para triar. O que o Claude achar enquanto trabalha cai aqui."
        case .todo: "Arraste para cá o que vale corrigir."
        case .doing: "Nenhum bug em andamento."
        case .review: "Nada esperando revisão."
        case .done, .discarded: "Nenhum bug fechado ainda."
        }
    }

    private func move(_ item: BacklogItem, to status: BacklogStatus) {
        do { try model.move(item, to: status) } catch { errorMessage = error.localizedDescription }
    }

    private func create() {
        let text = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        do {
            try model.create(kind: .bug, title: text)
            newTitle = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

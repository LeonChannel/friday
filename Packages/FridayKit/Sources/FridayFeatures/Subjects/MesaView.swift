// Resumo: Mesa, a tela inicial: a pergunta "O que está te incomodando?" para abrir um assunto e os assuntos em três colunas por vez.
// Tags: assuntos, interface

import FridayDomain
import SwiftUI

/// Tela inicial do Friday.
struct MesaView: View {
    @Environment(SubjectsModel.self) private var subjects
    let open: (Int64) -> Void
    @State private var concern = ""
    @State private var errorMessage: String?
    @FocusState private var commandFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
            Text("Mesa").typography(.tituloTela).foregroundStyle(Theme.texto)
            commandBar
            HStack(alignment: .top, spacing: Spacing.lg) {
                column("Sua vez", style: .voce, rows: subjects.rows(for: .you), empty: "Nada esperando você.")
                column("Com o Claude", style: .claude, rows: subjects.rows(for: .claude), empty: "O Claude não está trabalhando em nenhum assunto.")
                column("Parados", style: .parado, rows: subjects.rows(for: .idle), empty: "Nenhum assunto parado.")
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.fundo)
        .onAppear { if subjects.rows.isEmpty { commandFocused = true } }
    }

    private var commandBar: some View {
        HStack(spacing: Spacing.md) {
            TextField("O que está te incomodando?", text: $concern)
                .textFieldStyle(.plain)
                .typography(.corpo)
                .foregroundStyle(Theme.texto)
                .focused($commandFocused)
                .onSubmit(create)
            Button("Começar", action: create)
                .buttonStyle(.fridayPrimary)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(concern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

    private func column(_ title: String, style: TurnStyle, rows: [SubjectRow], empty: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                TurnDot(style)
                MonoLabel("\(title) · \(rows.count)", kind: .secao)
            }
            if rows.isEmpty {
                Text(empty)
                    .typography(.secundario)
                    .foregroundStyle(Theme.textoSecundario)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: Radius.peca).strokeBorder(Theme.linha, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
            }
            ForEach(rows) { row in
                Button { if let id = row.subject.id { open(id) } } label: { SubjectCard(row: row) }
                    .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func create() {
        let text = concern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        do {
            let title = String(text.prefix(SubjectLimits.title))
            let intent = text.count > SubjectLimits.title ? String(text.prefix(SubjectLimits.intent)) : ""
            let subject = try subjects.create(title: title, intent: intent)
            concern = ""
            errorMessage = nil
            if let id = subject.id { open(id) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// Cartão de assunto na Mesa: título, motivo da vez e quando mudou.
struct SubjectCard: View {
    let row: SubjectRow

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(row.subject.title).typography(.corpo).fontWeight(.semibold).foregroundStyle(Theme.texto).lineLimit(2)
            Text(row.turn.reason).typography(.secundario).foregroundStyle(TurnStyle(row.turn.holder).textColor)
            Text(row.subject.updatedAt, format: .relative(presentation: .named)).typography(.metadado).foregroundStyle(Theme.textoSecundario)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.peca).fill(Theme.superficie))
        .overlay(RoundedRectangle(cornerRadius: Radius.peca).strokeBorder(Theme.linha))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

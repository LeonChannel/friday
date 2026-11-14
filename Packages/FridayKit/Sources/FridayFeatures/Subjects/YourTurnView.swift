// Resumo: Sua vez: fila de triagem com os assuntos que esperam você à esquerda e a decisão em foco à direita, com opções de mesmo peso.
// Tags: assuntos, interface

import FridayDomain
import SwiftUI

/// Fila de decisões que dependem do dev.
struct YourTurnView: View {
    @Environment(SubjectsModel.self) private var subjects
    @Environment(WorkspaceModel.self) private var workspace
    let open: (Int64) -> Void
    @State private var focused: Int64?

    var body: some View {
        let waiting = subjects.rows(for: .you)
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Sua vez").typography(.tituloTela).foregroundStyle(Theme.texto)
                if waiting.isEmpty {
                    Text("Nada esperando você. Pode dar atenção a outra coisa.")
                        .typography(.secundario).foregroundStyle(Theme.textoSecundario)
                }
                ForEach(waiting) { row in
                    Button { focused = row.subject.id } label: {
                        HStack(spacing: Spacing.sm) {
                            TurnDot(.voce)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.subject.title).typography(.corpo).foregroundStyle(Theme.texto).lineLimit(1)
                                Text(row.turn.reason).typography(.metadado).foregroundStyle(Theme.voceTexto)
                            }
                        }
                        .padding(Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: Radius.botao).fill(focused == row.subject.id ? Theme.superficieAtiva : .clear))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(Spacing.xxl)
            .frame(width: 300, alignment: .topLeading)
            .background(Theme.superficie)
            Rectangle().fill(Theme.linha).frame(width: 1)
            Group {
                if let id = focused ?? waiting.first?.subject.id {
                    DecisionFocus(model: workspace.subject(id), open: { open(id) }).id(id)
                } else {
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.fundo)
    }
}

/// Decisões abertas de um assunto, uma embaixo da outra.
struct DecisionFocus: View {
    let model: SubjectModel
    let open: () -> Void
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if let subject = model.subject {
                    HStack {
                        Text(subject.title).typography(.tituloAssunto).foregroundStyle(Theme.texto)
                        Spacer()
                        Button("Abrir assunto", action: open).buttonStyle(.friday)
                    }
                    if model.questionsForYou.isEmpty {
                        Text(model.turn?.reason ?? "").typography(.secundario).foregroundStyle(Theme.textoSecundario)
                    }
                    ForEach(model.questionsForYou) { question in
                        QuestionCard(question: question) { option in
                            do { try model.answer(question, with: option) } catch { errorMessage = error.localizedDescription }
                        }
                    }
                    if let errorMessage {
                        Text(errorMessage).typography(.metadado).foregroundStyle(Theme.erro)
                    }
                }
            }
            .padding(Spacing.xxxl)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .task { await model.observe() }
    }
}

/// Uma pergunta que espera o dev: opções com o mesmo peso, cada uma com a consequência e a tecla.
struct QuestionCard: View {
    let question: Question
    let choose: (QuestionOption) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(question.text).typography(.corpo).foregroundStyle(Theme.texto)
            if question.options.isEmpty {
                Text("Pergunta sem opções: responda no terminal do Claude.").typography(.secundario).foregroundStyle(Theme.textoSecundario)
            }
            HStack(alignment: .top, spacing: Spacing.md) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    Button { choose(option) } label: {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Text(option.label).typography(.corpo).fontWeight(.semibold).foregroundStyle(Theme.texto)
                                Spacer()
                                if index < 9 { Text("\(index + 1)").typography(.metadado).foregroundStyle(Theme.textoSecundario) }
                            }
                            Text(option.consequence).typography(.secundario).foregroundStyle(Theme.textoSecundario)
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: Radius.campo).fill(Theme.superficieElevada))
                        .overlay(RoundedRectangle(cornerRadius: Radius.campo).strokeBorder(Theme.linha))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(KeyEquivalent(Character("\(min(index + 1, 9))")), modifiers: [])
                }
            }
        }
        .padding(Spacing.lg)
        .background(RoundedRectangle(cornerRadius: Radius.peca).fill(Theme.voceFundo))
        .overlay(RoundedRectangle(cornerRadius: Radius.peca).strokeBorder(Theme.voceBorda))
    }
}

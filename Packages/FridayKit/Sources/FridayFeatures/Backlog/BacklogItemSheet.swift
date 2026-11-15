// Resumo: Ficha de um item do backlog numa folha: título, detalhe, onde mora, estado, prioridade e o card externo (Jira/Azure) para onde foi levado.
// Tags: backlog, interface

import FridayDomain
import SwiftUI

/// Folha para ler e editar um item. Grava só ao confirmar.
struct BacklogItemSheet: View {
    let model: BacklogModel
    let item: BacklogItem
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var detail: String
    @State private var location: String
    @State private var priority: BacklogPriority
    @State private var status: BacklogStatus
    @State private var externalRef: String
    @State private var errorMessage: String?

    init(model: BacklogModel, item: BacklogItem) {
        self.model = model
        self.item = item
        _title = State(initialValue: item.title)
        _detail = State(initialValue: item.detail)
        _location = State(initialValue: item.location ?? "")
        _priority = State(initialValue: item.priority)
        _status = State(initialValue: item.status)
        _externalRef = State(initialValue: item.externalRef ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(spacing: Spacing.sm) {
                MonoLabel("\(model.code(item)) · \(item.kind.label)", kind: .secao).textSelection(.enabled)
                if let parent = model.parent(of: item) {
                    MonoLabel("dentro de \(model.code(parent))")
                }
                Spacer()
                if item.author == .claude {
                    TurnBadge(.claude, text: "anotado pelo Claude")
                }
            }
            TextField("Título", text: $title).textFieldStyle(.roundedBorder).typography(.corpo)
            HStack(spacing: Spacing.lg) {
                Picker("Estado", selection: $status) {
                    ForEach(BacklogStatus.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                Picker("Prioridade", selection: $priority) {
                    ForEach(BacklogPriority.allCases, id: \.self) { Text($0.label).tag($0) }
                }
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                MonoLabel("Onde", kind: .secao)
                HStack(spacing: Spacing.sm) {
                    TextField("arquivo:linha, tela ou comando", text: $location).textFieldStyle(.roundedBorder).typography(.metadado)
                    if let grade = item.grade { EvidenceGradeMark(grade) }
                }
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                MonoLabel("Detalhe", kind: .secao)
                TextEditor(text: $detail)
                    .typography(.corpo)
                    .scrollContentBackground(.hidden)
                    .padding(Spacing.sm)
                    .frame(minHeight: 120)
                    .background(RoundedRectangle(cornerRadius: Radius.campo).fill(Theme.superficieElevada))
                    .overlay(RoundedRectangle(cornerRadius: Radius.campo).strokeBorder(Theme.linha))
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                MonoLabel("Levado para", kind: .secao)
                TextField("card no Jira ou Azure DevOps (código ou link)", text: $externalRef).textFieldStyle(.roundedBorder).typography(.metadado)
                Text("Cite \(model.code(item)) no card da sprint para achar este item de volta.")
                    .typography(.secundario).foregroundStyle(Theme.textoSecundario)
            }
            if let errorMessage {
                Text(errorMessage).typography(.secundario).foregroundStyle(Theme.erro)
            }
            HStack {
                Spacer()
                Button("Cancelar") { dismiss() }.buttonStyle(.friday).keyboardShortcut(.cancelAction)
                Button("Salvar", action: save).buttonStyle(.fridayPrimary).keyboardShortcut(.defaultAction)
            }
        }
        .padding(Spacing.xxl)
        .frame(width: 520)
        .background(Theme.superficie)
    }

    private func save() {
        do {
            try model.save(item, title: title, detail: detail, location: location, priority: priority, status: status, externalRef: externalRef)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

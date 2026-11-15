// Resumo: Backlog do projeto em árvore (épico, história, task, subtask e bug dentro deles), com a barra para criar item já pendurado no pai certo.
// Tags: backlog, interface

import FridayDomain
import SwiftUI

/// Hierarquia do backlog. Bug solto mora no quadro de bugs; aqui aparece só o que está dentro de um item.
struct BacklogView: View {
    let model: BacklogModel
    @State private var kind: BacklogKind = .epic
    @State private var parentID: Int64?
    @State private var newTitle = ""
    @State private var errorMessage: String?
    @State private var opened: BacklogItem?
    @AppStorage("backlog.showsDone") private var showsDone = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Backlog").typography(.tituloTela).foregroundStyle(Theme.texto)
                    MonoLabel("códigos \(model.key)-n · \(model.items.count { !$0.status.isClosed }) abertos")
                }
                Spacer()
                Toggle("Mostrar feitos", isOn: $showsDone).toggleStyle(.checkbox).typography(.secundario)
            }
            creationBar
            let nodes = model.tree(includingDone: showsDone)
            if nodes.isEmpty {
                Text("Nenhum item ainda. Crie um épico acima e pendure histórias e tasks nele.")
                    .typography(.secundario)
                    .foregroundStyle(Theme.textoSecundario)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: Radius.peca).strokeBorder(Theme.linha, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                Spacer(minLength: 0)
            } else {
                List(nodes, children: \.children) { node in
                    row(node.item)
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
        .padding(Spacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.fundo)
        .task { await model.observe() }
        .sheet(item: $opened) { item in BacklogItemSheet(model: model, item: item) }
        .onChange(of: kind) { parentID = nil }
    }

    private var creationBar: some View {
        HStack(spacing: Spacing.md) {
            Picker("Tipo", selection: $kind) {
                ForEach(BacklogKind.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            .labelsHidden()
            .fixedSize()
            let parents = model.possibleParents(for: kind)
            if !kind.allowedParents.isEmpty {
                Picker("Dentro de", selection: $parentID) {
                    if !kind.requiresParent { Text("Sem pai").tag(Int64?.none) }
                    ForEach(parents) { parent in
                        Text("\(model.code(parent)) · \(parent.title)").lineLimit(1).tag(Optional(parent.id ?? 0))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 220)
                .help("Item onde o novo fica pendurado")
            }
            TextField("Título do \(kind.label.lowercased())", text: $newTitle)
                .textFieldStyle(.plain)
                .typography(.corpo)
                .foregroundStyle(Theme.texto)
                .onSubmit(create)
            Button("Criar", action: create)
                .buttonStyle(.fridayPrimary)
                .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (kind.requiresParent && parentID == nil))
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

    private func row(_ item: BacklogItem) -> some View {
        let code = model.code(item)
        return HStack(spacing: Spacing.md) {
            MonoLabel(item.kind.label, kind: .secao).frame(width: 72, alignment: .leading)
            MonoLabel(code).frame(width: 64, alignment: .leading)
            Text(item.title)
                .typography(.corpo)
                .foregroundStyle(item.status == .done ? Theme.textoSecundario : Theme.texto)
                .lineLimit(1)
            if item.author == .claude {
                TurnDot(.claude).help("Anotado pelo Claude")
            }
            Spacer()
            if let externalRef = item.externalRef { MonoLabel("→ \(externalRef)").lineLimit(1) }
            if item.priority >= .high {
                Text(item.priority.label).typography(.metadado).fontWeight(.semibold).foregroundStyle(Theme.texto)
            }
            MonoLabel(item.status.label).frame(width: 72, alignment: .trailing)
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { opened = item }
        .contextMenu {
            Button("Abrir ficha") { opened = item }
            BacklogItemMenu(item: item, code: code) { status in
                do { try model.move(item, to: status) } catch { errorMessage = error.localizedDescription }
            }
        }
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Clique duas vezes para abrir a ficha.")
    }

    private func create() {
        let text = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        do {
            let parent = parentID.flatMap { id in model.items.first { $0.id == id } }
            try model.create(kind: kind, title: text, parent: parent)
            newTitle = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// Resumo: Mesa, a tela inicial: escolher o tipo de atividade e descrever o pedido abre o assunto e inicia a jornada; os assuntos em três colunas por vez.
// Tags: assuntos, interface, jornadas

import FridayDomain
import SwiftUI

/// Tela inicial do Friday.
struct MesaView: View {
    @Environment(SubjectsModel.self) private var subjects
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(AppSettings.self) private var settings
    /// Projeto aberto: é nele que o Claude da jornada roda.
    let project: Project?
    let open: (Int64) -> Void
    @State private var concern = ""
    @State private var activity: ActivityKind?
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
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ActivityPicker(selection: $activity)
            HStack(spacing: Spacing.md) {
                TextField(activity?.prompt ?? "Escolha o tipo de atividade acima", text: $concern)
                    .textFieldStyle(.plain)
                    .typography(.corpo)
                    .foregroundStyle(Theme.texto)
                    .focused($commandFocused)
                    .disabled(activity == nil)
                    .onSubmit(create)
                Button("Começar", action: create)
                    .buttonStyle(.fridayPrimary)
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(!canCreate)
                MonoLabel("⌘↵")
            }
            .padding(Spacing.md)
            .background(RoundedRectangle(cornerRadius: Radius.bloco).fill(Theme.superficieElevada))
            .overlay(RoundedRectangle(cornerRadius: Radius.bloco).strokeBorder(Theme.linha))
            if let activity { journeyLine(settings.journey(for: activity)) }
            if let errorMessage { Text(errorMessage).typography(.metadado).foregroundStyle(Theme.erro) }
        }
        .onChange(of: activity) { if activity != nil { commandFocused = true } }
    }

    /// O que a jornada escolhida vai fazer, para o dev saber antes de começar.
    private func journeyLine(_ journey: Journey) -> some View {
        let text: String
        if journey.isEmpty {
            text = "\(journey.kind.summary) Jornada vazia: o Claude recebe só o pedido. Configure em Ajustes › Jornadas (⌘,)."
        } else {
            let stages = journey.cleanStages.count, skills = journey.cleanSkills.count
            text = "\(journey.kind.summary) \(stages) \(stages == 1 ? "etapa" : "etapas") · \(skills) \(skills == 1 ? "skill" : "skills")"
                + (journey.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : " · prompt próprio")
        }
        return Text(text).typography(.metadado).foregroundStyle(Theme.textoSecundario)
    }

    private var canCreate: Bool {
        activity != nil && !concern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

    /// Grava o assunto com as etapas da jornada e já chama o Claude no bastidor.
    private func create() {
        let text = concern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let activity, !text.isEmpty else { return }
        let journey = settings.journey(for: activity)
        do {
            let title = String(text.prefix(SubjectLimits.title))
            let intent = text.count > SubjectLimits.title ? String(text.prefix(SubjectLimits.intent)) : ""
            let subject = try subjects.create(title: title, intent: intent, projectID: project?.id, activity: activity, stages: journey.cleanStages)
            concern = ""
            errorMessage = nil
            if let project { errorMessage = workspace.startJourney(subject: subject, journey: journey, project: project) }
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

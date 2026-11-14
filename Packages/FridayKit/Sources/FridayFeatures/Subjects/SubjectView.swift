// Resumo: Tela do assunto: "Onde você parou" à esquerda, o dossiê com as partes no centro e as trilhas embaixo, com o terminal do projeto como gaveta.
// Tags: assuntos, interface

import FridayDomain
import SwiftUI

/// Um assunto aberto.
struct SubjectView: View {
    let model: SubjectModel
    @Environment(ProjectsModel.self) private var projects
    @Environment(WorkspaceModel.self) private var workspace
    @State private var showsResume = true
    @State private var showsTerminal = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let subject = model.subject {
                content(subject)
            } else if let error = model.loadError {
                Text(error).typography(.secundario).foregroundStyle(Theme.erro)
            } else {
                Text("Abrindo o assunto…").typography(.secundario).foregroundStyle(Theme.textoSecundario)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.fundo)
        .task { await model.observe() }
    }

    private func content(_ subject: Subject) -> some View {
        VStack(spacing: 0) {
            header(subject)
            Rectangle().fill(Theme.linha).frame(height: 1)
            HStack(spacing: 0) {
                if showsResume, let resume = model.resume {
                    ResumeColumn(resume: resume)
                        .frame(width: 300)
                        .background(Theme.superficie)
                    Rectangle().fill(Theme.linha).frame(width: 1)
                }
                Dossier(subject: subject, model: model)
            }
            Rectangle().fill(Theme.linha).frame(height: 1)
            Tracks(fronts: subject.fronts, showsTerminal: $showsTerminal)
            if showsTerminal {
                drawer(subject)
                    .frame(height: 300)
            }
        }
    }

    private func header(_ subject: Subject) -> some View {
        HStack(spacing: Spacing.md) {
            Button(showsResume ? "Esconder onde você parou" : "Mostrar onde você parou", systemImage: "sidebar.left") { showsResume.toggle() }
                .labelStyle(.iconOnly).buttonStyle(.friday)
            VStack(alignment: .leading, spacing: 2) {
                Text(subject.title).typography(.tituloAssunto).foregroundStyle(Theme.texto).lineLimit(1)
                MonoLabel("assunto \(subject.id ?? 0) · atualizado \(subject.updatedAt.formatted(.relative(presentation: .named)))")
            }
            Spacer()
            projectMenu(subject)
            if let turn = model.turn {
                TurnBadge(TurnStyle(turn.holder), text: turn.reason)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(Theme.superficie)
        .overlay(alignment: .bottomLeading) {
            if let errorMessage { Text(errorMessage).typography(.metadado).foregroundStyle(Theme.erro).padding(.leading, Spacing.xl) }
        }
    }

    private func projectMenu(_ subject: Subject) -> some View {
        Menu {
            ForEach(projects.projects) { project in
                Button(project.name) { link(project.id) }
            }
            if subject.projectID != nil {
                Divider()
                Button("Desligar do projeto") { link(nil) }
            }
        } label: {
            MonoLabel(projects.projects.first { $0.id == subject.projectID }.map { "projeto: \($0.name)" } ?? "sem projeto")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    @ViewBuilder
    private func drawer(_ subject: Subject) -> some View {
        if let project = projects.projects.first(where: { $0.id == subject.projectID }), let terminals = workspace.terminals(for: project) {
            TerminalArea(model: terminals, sessionEnvironment: ["FRIDAY_ASSUNTO": "\(subject.id ?? 0)"])
        } else {
            Text("Ligue o assunto a um projeto (no topo) para abrir o terminal do Claude aqui.")
                .typography(.secundario).foregroundStyle(Theme.textoSecundario)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.fundo)
        }
    }

    private func link(_ projectID: Int64?) {
        do { try model.link(projectID: projectID); errorMessage = nil } catch { errorMessage = error.localizedDescription }
    }
}

/// "Onde você parou": as cinco linhas do retorno, montadas do estado do assunto.
struct ResumeColumn: View {
    let resume: SubjectResume

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                MonoLabel("Onde você parou", kind: .secao)
                line("Objetivo") {
                    if let goal = resume.goal { Text(goal).typography(.corpo).foregroundStyle(Theme.texto) }
                }
                line("Confirmado") {
                    ForEach(Array(resume.confirmed.enumerated()), id: \.offset) { _, fact in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fact.text).typography(.corpo).foregroundStyle(Theme.texto)
                            EvidenceGradeMark(fact.grade)
                        }
                    }
                }
                line("Em aberto") {
                    ForEach(Array(resume.open.enumerated()), id: \.offset) { _, item in
                        Text(item.text).typography(.corpo).italic(item.grade == .inferred).foregroundStyle(Theme.textoSecundario)
                    }
                }
                line("Sua vez", color: Theme.voceTexto) {
                    ForEach(Array(resume.yourTurn.enumerated()), id: \.offset) { _, item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.text).typography(.corpo).foregroundStyle(Theme.texto)
                            ForEach(Array(item.options.enumerated()), id: \.offset) { _, option in
                                Text("\(option.label) → \(option.consequence)").typography(.metadado).foregroundStyle(Theme.textoSecundario)
                            }
                        }
                    }
                }
                line("Depois") {
                    ForEach(Array(resume.next.enumerated()), id: \.offset) { _, step in
                        Text("\(step.front): \(step.step)").typography(.corpo).foregroundStyle(Theme.texto)
                    }
                }
                MonoLabel(resume.sourceLine)
            }
            .padding(Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func line(_ title: String, color: Color = Theme.textoSecundario, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title.uppercased()).typography(.rotuloSecao).foregroundStyle(color)
            content()
        }
    }
}

/// O dossiê do assunto: intenção, perguntas, evidências, alternativas e decisões.
struct Dossier: View {
    let subject: Subject
    let model: SubjectModel
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                section("Intenção") {
                    Text(subject.intent.isEmpty ? "Sem intenção escrita ainda. O Claude registra com `friday assunto intencao`." : subject.intent)
                        .typography(.corpo).foregroundStyle(subject.intent.isEmpty ? Theme.textoSecundario : Theme.texto)
                }
                if !model.questionsForYou.isEmpty {
                    section("Esperando você") {
                        ForEach(model.questionsForYou) { question in
                            QuestionCard(question: question) { option in
                                do { try model.answer(question, with: option) } catch { errorMessage = error.localizedDescription }
                            }
                        }
                    }
                }
                section("Perguntas") {
                    let others = subject.questions.filter { !($0.isOpen && $0.waitsForYou) }
                    if others.isEmpty { empty("Nenhuma pergunta.") }
                    ForEach(others) { question in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            MonoLabel("\(question.id)")
                            Text(question.text).typography(.corpo).foregroundStyle(question.isOpen ? Theme.texto : Theme.textoSecundario).strikethrough(!question.isOpen)
                        }
                    }
                }
                section("Evidências") {
                    if subject.evidences.isEmpty { empty("Nenhuma evidência.") }
                    ForEach(subject.evidences) { evidence in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(evidence.fact).typography(.corpo).italic(evidence.grade == .inferred)
                                .foregroundStyle(evidence.grade == .inferred ? Theme.textoSecundario : Theme.texto)
                            HStack(spacing: Spacing.md) {
                                EvidenceGradeMark(evidence.grade)
                                MonoLabel("fonte: \(evidence.source)")
                            }
                        }
                    }
                }
                section("Alternativas") {
                    if subject.alternatives.isEmpty { empty("Nenhuma alternativa.") }
                    ForEach(subject.alternatives) { alternative in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(alternative.name).typography(.corpo).fontWeight(.semibold).foregroundStyle(Theme.texto)
                            Grid(alignment: .leading, horizontalSpacing: Spacing.md, verticalSpacing: 2) {
                                criterion("ganho", alternative.gain)
                                criterion("risco", alternative.risk)
                                criterion("esforço", alternative.effort)
                                criterion("reversível", alternative.reversibility)
                            }
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: Radius.peca).fill(Theme.superficie))
                        .overlay(RoundedRectangle(cornerRadius: Radius.peca).strokeBorder(Theme.linha))
                    }
                }
                section("Decisões") {
                    if subject.decisions.isEmpty { empty("Nenhuma decisão.") }
                    ForEach(subject.decisions) { decision in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(decision.text).typography(.corpo).fontWeight(.semibold).foregroundStyle(Theme.texto)
                            Text("porque \(decision.reason)").typography(.secundario).foregroundStyle(Theme.textoSecundario)
                            if let changeIf = decision.changeIf {
                                Text("mudaria se \(changeIf)").typography(.metadado).foregroundStyle(Theme.textoSecundario)
                            }
                        }
                    }
                }
                if let errorMessage { Text(errorMessage).typography(.metadado).foregroundStyle(Theme.erro) }
            }
            .padding(Spacing.xxl)
            .frame(maxWidth: 820, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            MonoLabel(title, kind: .secao)
            content()
        }
    }

    private func empty(_ text: String) -> some View {
        Text(text).typography(.secundario).foregroundStyle(Theme.textoSecundario)
    }

    private func criterion(_ name: String, _ value: String) -> some View {
        GridRow {
            MonoLabel(name)
            Text(value).typography(.secundario).foregroundStyle(Theme.texto)
        }
    }
}

/// Trilhas: uma linha por frente com o trilho de passos, e o botão da gaveta do terminal.
struct Tracks: View {
    let fronts: [Front]
    @Binding var showsTerminal: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                MonoLabel("Trilhas · \(fronts.count)", kind: .secao)
                Spacer()
                Button(showsTerminal ? "Fechar terminal" : "Abrir terminal", systemImage: "terminal") { showsTerminal.toggle() }
                    .buttonStyle(.friday)
                    .keyboardShortcut("`", modifiers: .control)
                MonoLabel("⌃`")
            }
            if fronts.isEmpty {
                Text("Nenhuma frente. O Claude abre com `friday frente`.").typography(.secundario).foregroundStyle(Theme.textoSecundario)
            }
            ForEach(Array(fronts.enumerated()), id: \.offset) { _, front in
                HStack(spacing: Spacing.md) {
                    Text(front.name).typography(.corpo).foregroundStyle(Theme.texto).frame(width: 220, alignment: .leading).lineLimit(1)
                    Rail(front: front)
                    TurnBadge(style(front.state), text: label(front.state))
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(Theme.superficie)
    }

    private func style(_ state: FrontState) -> TurnStyle {
        switch state {
        case .running: .claude
        case .waitingForYou: .voce
        case .done: .parado
        }
    }

    private func label(_ state: FrontState) -> String {
        switch state {
        case .running: "rodando"
        case .waitingForYou: "esperando você"
        case .done: "concluída"
        }
    }
}

/// Trilho segmentado de uma frente: um segmento por passo.
struct Rail: View {
    let front: Front

    var body: some View {
        let steps = front.steps.isEmpty ? [FrontStep(text: front.criterion, isDone: front.state == .done)] : front.steps
        let current = steps.firstIndex { !$0.isDone }
        HStack(spacing: 3) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(fill(step: step, isCurrent: index == current))
                    .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(index == current && front.state == .waitingForYou ? Theme.voce : .clear))
                    .frame(height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("passo \((current ?? steps.count - 1) + 1) de \(steps.count), \(front.state == .running ? "rodando" : front.state == .done ? "concluída" : "esperando você")")
    }

    private func fill(step: FrontStep, isCurrent: Bool) -> Color {
        if step.isDone { return Theme.concluido }
        guard isCurrent else { return Theme.superficieAtiva }
        switch front.state {
        case .running: return Theme.claude
        case .waitingForYou: return Theme.voceFundo
        case .done: return Theme.concluido
        }
    }
}

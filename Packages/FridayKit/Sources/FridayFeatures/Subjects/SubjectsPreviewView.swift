// Resumo: Telas mínimas e neutras da lista de assuntos e do "Onde você parou", só para prévia até o tema chegar.
// Tags: assuntos, interface

import FridayDomain
import SwiftUI

/// Lista simples de assuntos com a vez de cada um.
public struct SubjectsPreviewView: View {
    let model: SubjectsModel

    public init(model: SubjectsModel) {
        self.model = model
    }

    public var body: some View {
        List(model.rows) { row in
            HStack {
                TurnDot(holder: row.turn.holder)
                VStack(alignment: .leading) {
                    Text(row.subject.title)
                    Text(row.turn.reason).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .task { await model.observe() }
    }
}

/// Ponto da vez: cheio para você e Claude, vazado para parado. A cor final vem do tema.
struct TurnDot: View {
    let holder: TurnHolder

    var body: some View {
        Circle()
            .strokeBorder(.primary, lineWidth: 1)
            .background(Circle().fill(holder == .idle ? Color.clear : Color.primary))
            .frame(width: 8, height: 8)
            .accessibilityLabel(holder == .you ? "Sua vez" : holder == .claude ? "Vez do Claude" : "Parado")
    }
}

/// Dossiê simples de um assunto: "Onde você parou" no topo.
public struct SubjectResumePreviewView: View {
    let model: SubjectModel

    public init(model: SubjectModel) {
        self.model = model
    }

    public var body: some View {
        ScrollView {
            if let subject = model.subject, let resume = model.resume, let turn = model.turn {
                VStack(alignment: .leading, spacing: 12) {
                    Text(subject.title).font(.title2)
                    Label(turn.reason, systemImage: "circle").labelStyle(.titleOnly).foregroundStyle(.secondary)
                    line("Objetivo", resume.goal.map { [$0] } ?? [])
                    line("Confirmado", resume.confirmed.map { "\($0.text) (\($0.grade.label))" })
                    line("Em aberto", resume.open.map(\.text))
                    line("Sua vez", resume.yourTurn.map { item in
                        ([item.text] + item.options.map { "  \($0.label) → \($0.consequence)" }).joined(separator: "\n")
                    })
                    line("Depois", resume.next.map { "\($0.front): \($0.step)" })
                    Text(resume.sourceLine).font(.caption).foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .task { await model.observe() }
    }

    @ViewBuilder private func line(_ title: String, _ items: [String]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                ForEach(items, id: \.self) { Text($0) }
            }
        }
    }
}

#if DEBUG
private struct PreviewSubjectRepository: SubjectRepository {
    let subjects: [Subject]
    func observeAll() -> AsyncThrowingStream<[Subject], any Error> { AsyncThrowingStream { $0.yield(subjects) } }
    func observe(id: Int64) -> AsyncThrowingStream<Subject?, any Error> { AsyncThrowingStream { $0.yield(subjects.first { $0.id == id }) } }
    func all() throws -> [Subject] { subjects }
    func subject(id: Int64) throws -> Subject? { subjects.first { $0.id == id } }
    func insert(_ subject: Subject) throws -> Subject { subject }
    func update(id: Int64, _ change: @Sendable (inout Subject) throws -> Void) throws -> Subject { throw SubjectError.subjectNotFound(id) }
    func delete(id: Int64) throws {}
}

private func previewSubjects() -> [Subject] {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    guard var waiting = try? Subject(id: 1, title: "Cache do catálogo", intent: "Cortar a latência do catálogo pela metade.", createdAt: now),
          var running = try? Subject(id: 2, title: "Fila de eventos", createdAt: now),
          let idle = try? Subject(id: 3, title: "Migração de login", createdAt: now)
    else { return [] }
    _ = try? waiting.addEvidence(fact: "p95 do catálogo é 840 ms", source: "trace de produção", grade: .measured, at: now)
    _ = try? waiting.addQuestion(text: "Invalidar por tempo ou por evento?", options: [QuestionOption(label: "Tempo", consequence: "simples, dado velho por até 60 s")], waitsForYou: true, at: now)
    _ = try? running.upsertFront(name: "Medir fila", criterion: "p95 por consumidor", steps: ["coletar", "comparar"], doneSteps: 1, at: now)
    return [waiting, running, idle]
}

#Preview("Lista") {
    SubjectsPreviewView(model: SubjectsModel(repository: PreviewSubjectRepository(subjects: previewSubjects())))
        .frame(width: 320, height: 240)
}

#Preview("Onde você parou") {
    SubjectResumePreviewView(model: SubjectModel(id: 1, repository: PreviewSubjectRepository(subjects: previewSubjects())))
        .frame(width: 420, height: 360)
}
#endif

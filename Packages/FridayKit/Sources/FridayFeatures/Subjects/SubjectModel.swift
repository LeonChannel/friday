// Resumo: Estado de um assunto aberto na tela: as partes, a vez e o "Onde você parou", acompanhando o banco ao vivo.
// Tags: assuntos, interface

import FridayDomain
import Foundation
import Observation

/// Estado de um assunto que a interface mostra.
@MainActor
@Observable
public final class SubjectModel {
    public private(set) var subject: Subject?
    public private(set) var loadError: String?

    private let id: Int64
    private let repository: any SubjectRepository

    public init(id: Int64, repository: any SubjectRepository) {
        self.id = id
        self.repository = repository
    }

    /// De quem é a vez, ou `nil` se o assunto não existe mais.
    public var turn: SubjectTurn? { subject?.turn }
    /// O "Onde você parou" do assunto.
    public var resume: SubjectResume? { subject.map(SubjectResume.init) }

    /// Espelha o banco até a tarefa que chamou ser cancelada (use dentro de `.task`).
    public func observe() async {
        do {
            for try await subject in repository.observe(id: id) {
                self.subject = subject
            }
        } catch is CancellationError {
        } catch {
            loadError = error.localizedDescription
        }
    }

    /// Perguntas abertas que esperam o dev.
    public var questionsForYou: [Question] {
        subject?.questions.filter { $0.isOpen && $0.waitsForYou } ?? []
    }

    /// Responde uma pergunta escolhendo uma opção; vira decisão registrada no assunto.
    public func answer(_ question: Question, with option: QuestionOption) throws {
        _ = try repository.update(id: id) { subject in
            _ = try subject.recordDecision(
                text: option.label, reason: option.consequence, answering: question.id, at: Date()
            )
        }
    }

    /// Liga o assunto a um projeto (é nele que os terminais do assunto abrem).
    public func link(projectID: Int64?) throws {
        _ = try repository.update(id: id) { subject in subject.projectID = projectID }
    }
}

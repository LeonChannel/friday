// Resumo: Lista de assuntos na tela, cada um com a sua vez, acompanhando o banco ao vivo.
// Tags: assuntos, interface

import FridayDomain
import Foundation
import Observation

/// Um assunto da lista com a vez já calculada.
public struct SubjectRow: Identifiable, Equatable, Sendable {
    public var subject: Subject
    public var turn: SubjectTurn
    public var id: Int64? { subject.id }
}

/// Estado da lista de assuntos que a interface mostra.
@MainActor
@Observable
public final class SubjectsModel {
    public private(set) var rows: [SubjectRow] = []
    public private(set) var loadError: String?

    private let repository: any SubjectRepository

    public init(repository: any SubjectRepository) {
        self.repository = repository
    }

    /// Linhas de uma vez só (para a Mesa agrupar em colunas).
    public func rows(for holder: TurnHolder) -> [SubjectRow] {
        rows.filter { $0.turn.holder == holder }
    }

    /// Espelha o banco até a tarefa que chamou ser cancelada (use dentro de `.task`).
    public func observe() async {
        do {
            for try await subjects in repository.observeAll() {
                rows = subjects.map { SubjectRow(subject: $0, turn: $0.turn) }
            }
        } catch is CancellationError {
        } catch {
            loadError = error.localizedDescription
        }
    }

    /// Cria um assunto novo.
    @discardableResult
    public func create(title: String, intent: String = "", projectID: Int64? = nil, now: Date = Date()) throws -> Subject {
        try repository.insert(Subject(title: title, projectID: projectID, intent: intent, createdAt: now))
    }
}

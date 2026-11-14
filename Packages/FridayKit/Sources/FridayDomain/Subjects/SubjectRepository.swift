// Resumo: Contrato de onde os assuntos ficam guardados: lista ao vivo, leitura, criação e alteração atômica.
// Tags: assuntos, persistencia

import Foundation

/// Onde os assuntos ficam guardados. Produção usa o banco; teste usa memória.
public protocol SubjectRepository: Sendable {
    /// Todos os assuntos, do mais recente ao mais antigo, agora e a cada mudança (inclusive de outro processo).
    func observeAll() -> AsyncThrowingStream<[Subject], any Error>
    /// Um assunto, agora e a cada mudança; `nil` se não existir.
    func observe(id: Int64) -> AsyncThrowingStream<Subject?, any Error>
    /// Todos os assuntos agora, do mais recente ao mais antigo.
    func all() throws -> [Subject]
    func subject(id: Int64) throws -> Subject?
    @discardableResult func insert(_ subject: Subject) throws -> Subject
    /// Lê, altera e grava numa transação só, para duas escritas simultâneas não se perderem.
    @discardableResult func update(id: Int64, _ change: @Sendable (inout Subject) throws -> Void) throws -> Subject
    func delete(id: Int64) throws
}

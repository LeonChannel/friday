// Resumo: Lista ao vivo de uma consulta ao banco que também acorda com o aviso de escrita da CLI, sem repetir valor igual.
// Tags: persistencia

import Foundation
import GRDB

/// Observa uma consulta no banco: o GRDB avisa as escritas deste processo e o `SubjectChangeSignal`, as da CLI `friday`.
enum DatabaseLiveStream {
    /// Junta a observação do GRDB (escritas deste processo) com o aviso do sistema (escritas de outro processo).
    static func values<Value: Sendable & Equatable>(
        in writer: any DatabaseWriter, fetch: @escaping @Sendable (Database) throws -> Value
    ) -> AsyncThrowingStream<Value, any Error> {
        let local = ValueObservation.tracking(fetch).values(in: writer)
        return AsyncThrowingStream { continuation in
            // O aviso entre processos é global: qualquer gravação de qualquer `friday` relê, então valor repetido não é repassado.
            let last = LastEmitted<Value>()
            let localTask = Task {
                do {
                    for try await value in local where await last.isNew(value) { continuation.yield(value) }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            let remoteTask = Task {
                for await _ in SubjectChangeSignal.changes() {
                    do {
                        let value = try await writer.read(fetch)
                        if await last.isNew(value) { continuation.yield(value) }
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
            continuation.onTermination = { _ in
                localTask.cancel()
                remoteTask.cancel()
            }
        }
    }
}

/// Último valor entregue por um stream, compartilhado pelas duas fontes (banco local e aviso entre processos).
private actor LastEmitted<Value: Equatable & Sendable> {
    private var last: Value?

    /// `true` e guarda o valor quando ele difere do último entregue.
    func isNew(_ value: Value) -> Bool {
        guard value != last else { return false }
        last = value
        return true
    }
}

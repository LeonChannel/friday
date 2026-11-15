// Resumo: Estado da cota de uso do Claude na tela, acompanhando o último retrato gravado no banco.
// Tags: cota, interface

import FridayDomain
import Observation

/// Cota mostrada no rodapé da lateral. `nil` até a primeira statusline com cota chegar.
@MainActor
@Observable
public final class UsageQuotaModel {
    public private(set) var quota: UsageQuota?
    private let repository: (any UsageQuotaRepository)?

    /// Sem repositório (prévias), a cota fica vazia.
    public init(repository: (any UsageQuotaRepository)?) {
        self.repository = repository
    }

    /// Espelha o banco até a tarefa ser cancelada (use dentro de `.task`).
    public func observe() async {
        guard let repository else { return }
        do {
            for try await latest in repository.observeLatest() { quota = latest }
        } catch {}
    }
}

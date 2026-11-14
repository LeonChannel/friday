// Resumo: Preferências do usuário guardadas no UserDefaults (hoje: ligar a linha do tempo do Codex), injetáveis para teste.
// Tags: configuracoes, interface

import Foundation
import Observation

/// Preferências do app. Cada propriedade grava no `UserDefaults` ao mudar.
@MainActor
@Observable
public final class AppSettings {
    /// Chave da preferência "Linha do tempo do Codex".
    public nonisolated static let codexTimelineKey = "friday.settings.codexTimeline"

    /// Liga os hooks do Friday nas sessões do Codex. Desligada por padrão, porque exige
    /// `--dangerously-bypass-hook-trust` e isso também executa hooks do usuário ainda não aprovados.
    public var codexTimelineEnabled: Bool {
        didSet { defaults.set(codexTimelineEnabled, forKey: Self.codexTimelineKey) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.codexTimelineEnabled = defaults.bool(forKey: Self.codexTimelineKey)
    }

    /// Leitor da preferência para a infraestrutura (`CodexSessionHooks`), que roda fora da main thread.
    /// Lê o `UserDefaults` na hora, então vale para a próxima sessão aberta. `suiteName` nil é o padrão do app
    /// (guardar o nome e não o `UserDefaults` evita capturar um tipo não `Sendable`).
    public nonisolated static func codexTimelineReader(suiteName: String? = nil) -> @Sendable () -> Bool {
        {
            let defaults = suiteName.flatMap { UserDefaults(suiteName: $0) } ?? .standard
            return defaults.bool(forKey: codexTimelineKey)
        }
    }
}

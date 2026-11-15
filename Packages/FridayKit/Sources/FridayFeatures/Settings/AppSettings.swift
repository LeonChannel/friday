// Resumo: Preferências do usuário guardadas no UserDefaults (linha do tempo do Codex, pasta do vault e as jornadas de cada tipo de atividade), injetáveis para teste.
// Tags: configuracoes, interface, memoria, jornadas

import FridayDomain
import Foundation
import FridayInfrastructure
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

    /// Pasta do vault da memória; `nil` enquanto o dev não escolheu. Vale para as próximas sessões abertas.
    public var vaultPath: String? {
        didSet {
            if let vaultPath, !vaultPath.isEmpty { defaults.set(vaultPath, forKey: VaultPreference.key) } else { defaults.removeObject(forKey: VaultPreference.key) }
        }
    }

    /// Chave das jornadas (JSON com uma jornada por tipo de atividade).
    public nonisolated static let journeysKey = "friday.settings.journeys"

    /// Jornadas configuradas pelo dev. Tipo ausente é jornada vazia.
    public private(set) var journeys: [ActivityKind: Journey] = [:]

    @ObservationIgnored private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.codexTimelineEnabled = defaults.bool(forKey: Self.codexTimelineKey)
        let vault = defaults.string(forKey: VaultPreference.key)
        self.vaultPath = vault?.isEmpty == false ? vault : nil
        if let data = defaults.data(forKey: Self.journeysKey), let saved = try? JSONDecoder().decode([Journey].self, from: data) {
            journeys = Dictionary(saved.map { ($0.kind, $0) }, uniquingKeysWith: { _, last in last })
        }
    }

    /// Jornada do tipo; vazia enquanto o dev não configurou.
    public func journey(for kind: ActivityKind) -> Journey {
        journeys[kind] ?? Journey(kind: kind)
    }

    /// Grava a jornada do tipo. Vale para os próximos assuntos; os que já existem guardam as etapas com que nasceram.
    public func setJourney(_ journey: Journey) {
        journeys[journey.kind] = journey
        let ordered = ActivityKind.allCases.compactMap { journeys[$0] }
        if let data = try? JSONEncoder().encode(ordered) { defaults.set(data, forKey: Self.journeysKey) }
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

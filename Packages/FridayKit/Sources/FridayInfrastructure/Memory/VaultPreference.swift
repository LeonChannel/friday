// Resumo: Onde fica guardada a pasta do vault escolhida pelo dev e como app, sessões e CLI leem essa escolha.
// Tags: memoria, configuracoes

import Foundation

/// Preferência da pasta do vault no `UserDefaults` do app. A CLI roda dentro do executável do app e lê o mesmo domínio.
public enum VaultPreference {
    /// Chave da pasta do vault.
    public static let key = "friday.settings.vaultPath"

    /// Leitor para quem roda fora da main thread (customizador de sessão, CLI). `suiteName` nil é o padrão do app.
    public static func reader(suiteName: String? = nil) -> @Sendable () -> String? {
        {
            let defaults = suiteName.flatMap { UserDefaults(suiteName: $0) } ?? .standard
            let path = defaults.string(forKey: key)
            return path?.isEmpty == false ? path : nil
        }
    }

    /// Vault da sessão: `FRIDAY_VAULT` do ambiente vence a preferência.
    public static func resolve(environment: [String: String], preference: () -> String?) -> String? {
        if let path = environment["FRIDAY_VAULT"], !path.isEmpty { return path }
        return preference()
    }
}

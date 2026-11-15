// Resumo: Avisa cada sessão aberta pelo Friday onde fica o vault (FRIDAY_VAULT), para os hooks e a CLI acharem a memória sem configuração global.
// Tags: memoria, agentes, terminal

import FridayDomain
import Foundation

/// Exporta `FRIDAY_VAULT` para toda sessão (shell, Claude, Codex) quando há vault escolhido e a pasta existe.
public struct MemoryLaunchCustomizer: AgentLaunchCustomizing {
    private let vaultPath: @Sendable () -> String?

    /// `vaultPath` é lido a cada sessão nova, para a troca de pasta valer sem reabrir o app.
    public init(vaultPath: @escaping @Sendable () -> String?) {
        self.vaultPath = vaultPath
    }

    public func extraArguments(agent: AgentKind, session: AgentSessionID) throws -> [String] { [] }

    public func extraEnvironment(agent: AgentKind, session: AgentSessionID) throws -> [String: String] {
        var isDirectory: ObjCBool = false
        guard let path = vaultPath(), !path.isEmpty,
              FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else { return [:] }
        return ["FRIDAY_VAULT": path]
    }
}

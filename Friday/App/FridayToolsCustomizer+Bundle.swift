// Resumo: Acha dentro do pacote do app a pasta do comando `friday` e o plugin do Claude com a skill do assunto.
// Tags: composicao, agentes

import FridayInfrastructure
import Foundation

extension FridayToolsCustomizer {
    /// Caminhos do `friday` e do plugin dentro de `Friday.app/Contents/Resources`.
    static func bundled(_ bundle: Bundle = .main) -> FridayToolsCustomizer {
        let resources = bundle.resourceURL ?? URL(fileURLWithPath: ".")
        let plugin = resources.appendingPathComponent("claude-plugin")
        return FridayToolsCustomizer(
            binDirectory: resources.appendingPathComponent("bin").path,
            pluginDirectory: FileManager.default.fileExists(atPath: plugin.path) ? plugin.path : nil
        )
    }
}

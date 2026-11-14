// Resumo: Tela de Ajustes do app (cena Settings): hoje só o interruptor da linha do tempo do Codex, com o aviso do que ele libera.
// Tags: configuracoes, interface

import SwiftUI

/// Conteúdo da cena `Settings`. Recebe as preferências por parâmetro; não cria estado próprio.
public struct SettingsView: View {
    @Bindable var settings: AppSettings

    public init(settings: AppSettings) { self.settings = settings }

    public var body: some View {
        Form {
            Section {
                Toggle("Linha do tempo do Codex", isOn: $settings.codexTimelineEnabled)
                Label {
                    Text("Ligar faz o Codex rodar com --dangerously-bypass-hook-trust. Isso também executa hooks seus que o Codex ainda não aprovou. Vale para as próximas sessões do Codex abertas pelo Friday.")
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            } header: {
                Text("Agentes")
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Ajustes") {
    SettingsView(settings: AppSettings(defaults: UserDefaults(suiteName: "friday.preview") ?? .standard))
}

// Resumo: Tela de Ajustes do app (cena Settings): aba Geral (vault da memória e linha do tempo do Codex) e aba Jornadas (como cada tipo de atividade funciona).
// Tags: configuracoes, interface, memoria, jornadas

import AppKit
import FridayDomain
import SwiftUI

/// Conteúdo da cena `Settings`. Recebe as preferências por parâmetro; não cria estado próprio.
public struct SettingsView: View {
    @Bindable var settings: AppSettings
    let skills: (any SkillCataloging)?

    /// `skills` lista as skills instaladas para a aba Jornadas; nil deixa só a entrada à mão.
    public init(settings: AppSettings, skills: (any SkillCataloging)? = nil) {
        self.settings = settings
        self.skills = skills
    }

    public var body: some View {
        TabView {
            general.tabItem { Label("Geral", systemImage: "gearshape") }
            JourneysSettingsView(settings: settings, catalog: skills).tabItem { Label("Jornadas", systemImage: "point.topleft.down.to.point.bottomright.curvepath") }
        }
    }

    private var general: some View {
        Form {
            Section {
                LabeledContent("Pasta do vault") {
                    HStack(spacing: Spacing.sm) {
                        Text(settings.vaultPath ?? "nenhuma")
                            .font(.callout.monospaced())
                            .foregroundStyle(settings.vaultPath == nil ? .secondary : .primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                        Button("Escolher…") {
                            if let url = FolderPanel.choose(prompt: "Usar como vault") { settings.vaultPath = url.path }
                        }
                        if settings.vaultPath != nil {
                            Button("Esquecer") { settings.vaultPath = nil }
                        }
                    }
                }
                Text("Pasta de markdown com as três camadas da memória (abstração, processual, projeto). As próximas sessões abertas pelo Friday recebem o contexto dela; nada vai para ~/.claude.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Memória")
            }
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
        .frame(width: 520)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Ajustes") {
    SettingsView(settings: AppSettings(defaults: UserDefaults(suiteName: "friday.preview") ?? .standard))
}

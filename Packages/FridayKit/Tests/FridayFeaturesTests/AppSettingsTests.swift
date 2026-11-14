// Resumo: Prova as preferências: Codex desligado por padrão, persistência no UserDefaults e leitura pela infraestrutura.
// Tags: testes, configuracoes

import FridayFeatures
import Foundation
import Testing

@MainActor
struct AppSettingsTests {
    private func freshSuite() -> (name: String, defaults: UserDefaults) {
        let name = "friday.tests.\(UUID().uuidString)"
        return (name, UserDefaults(suiteName: name)!)
    }

    @Test func codexTimelineIsOffByDefault() {
        let suite = freshSuite()
        defer { suite.defaults.removePersistentDomain(forName: suite.name) }
        #expect(AppSettings(defaults: suite.defaults).codexTimelineEnabled == false)
        #expect(AppSettings.codexTimelineReader(suiteName: suite.name)() == false)
    }

    @Test func codexTimelinePersistsAcrossInstances() {
        let suite = freshSuite()
        defer { suite.defaults.removePersistentDomain(forName: suite.name) }
        AppSettings(defaults: suite.defaults).codexTimelineEnabled = true
        #expect(AppSettings(defaults: suite.defaults).codexTimelineEnabled)
        #expect(AppSettings.codexTimelineReader(suiteName: suite.name)())
    }

    @Test func turningItOffAgainPersists() {
        let suite = freshSuite()
        defer { suite.defaults.removePersistentDomain(forName: suite.name) }
        let settings = AppSettings(defaults: suite.defaults)
        settings.codexTimelineEnabled = true
        settings.codexTimelineEnabled = false
        #expect(AppSettings(defaults: suite.defaults).codexTimelineEnabled == false)
    }
}

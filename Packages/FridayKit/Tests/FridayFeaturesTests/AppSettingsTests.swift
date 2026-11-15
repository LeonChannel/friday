// Resumo: Prova as preferências: Codex desligado por padrão, persistência no UserDefaults e leitura pela infraestrutura.
// Tags: testes, configuracoes, jornadas

import FridayDomain
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

    @Test func journeysStartEmptyAndPersistAcrossInstances() {
        let suite = freshSuite()
        defer { suite.defaults.removePersistentDomain(forName: suite.name) }
        let settings = AppSettings(defaults: suite.defaults)
        #expect(ActivityKind.allCases.allSatisfy { settings.journey(for: $0).isEmpty })
        settings.setJourney(Journey(kind: .error, prompt: "Log primeiro", skills: ["investigar"], stages: ["Reproduzir", "Causa"]))
        let reopened = AppSettings(defaults: suite.defaults)
        #expect(reopened.journey(for: .error) == Journey(kind: .error, prompt: "Log primeiro", skills: ["investigar"], stages: ["Reproduzir", "Causa"]))
        #expect(reopened.journey(for: .test).isEmpty)
    }
}

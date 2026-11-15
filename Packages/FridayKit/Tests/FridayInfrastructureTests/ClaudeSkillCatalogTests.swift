// Resumo: Prova que o catálogo acha as skills do usuário e dos plugins instalados numa pasta .claude temporária, com nome e descrição do SKILL.md.
// Tags: jornadas, testes

import Foundation
import Testing
@testable import FridayInfrastructure

@Suite(.tags(.integration))
struct ClaudeSkillCatalogTests {
    private func write(_ text: String, to path: URL) throws {
        try FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: path, atomically: true, encoding: .utf8)
    }

    @Test func listsUserAndPluginSkillsSortedWithPluginPrefix() throws {
        let home = try TemporaryDirectory()
        defer { home.remove() }
        let root = home.url
        try write("---\nname: investigar\ndescription: \"Acha a causa de um erro.\"\n---\n# x", to: root.appending(path: "skills/investigar/SKILL.md"))
        try write("sem cabeçalho", to: root.appending(path: "skills/solta/SKILL.md"))
        let plugin = root.appending(path: "plugins/cache/mk/revisor/1.0.0")
        try write("---\nname: revisar\ndescription: Revisa o diff.\n---\n", to: plugin.appending(path: "skills/revisar/SKILL.md"))
        try write(#"{"version":2,"plugins":{"revisor@mk":[{"scope":"user","installPath":"\#(plugin.path)"}]}}"#, to: root.appending(path: "plugins/installed_plugins.json"))

        let skills = ClaudeSkillCatalog(claudeHome: root.path).installedSkills()
        #expect(skills.map(\.name) == ["investigar", "revisor:revisar", "solta"])
        #expect(skills[0].summary == "Acha a causa de um erro.")
        #expect(skills[1].origin == "revisor")
    }

    @Test func missingFolderIsEmptyNotError() {
        #expect(ClaudeSkillCatalog(claudeHome: "/caminho/que/nao/existe").installedSkills().isEmpty)
    }
}

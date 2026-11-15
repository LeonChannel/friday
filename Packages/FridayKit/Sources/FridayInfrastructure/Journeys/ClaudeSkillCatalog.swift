// Resumo: Lê, sem alterar nada, as skills do Claude instaladas no usuário e nos plugins, com nome e descrição tirados do SKILL.md.
// Tags: jornadas, agentes, pastas

import FridayDomain
import Foundation

/// Catálogo de skills lido de `~/.claude/skills` e dos plugins em `~/.claude/plugins/installed_plugins.json`.
/// Só leitura: a configuração global do agente nunca é escrita.
public struct ClaudeSkillCatalog: SkillCataloging {
    private let claudeHome: String

    /// `claudeHome` é a pasta `.claude` do usuário; o parâmetro existe para os testes.
    public init(claudeHome: String = NSHomeDirectory() + "/.claude") {
        self.claudeHome = claudeHome
    }

    public func installedSkills() -> [InstalledSkill] {
        var skills = Self.skills(in: claudeHome + "/skills", prefix: nil, origin: "usuário")
        for plugin in installedPlugins() {
            skills += Self.skills(in: plugin.path + "/skills", prefix: plugin.name, origin: plugin.name)
        }
        var seen = Set<String>()
        return skills.filter { seen.insert($0.name).inserted }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private struct InstalledPlugins: Decodable {
        struct Install: Decodable { var installPath: String }
        var plugins: [String: [Install]]
    }

    private func installedPlugins() -> [(name: String, path: String)] {
        guard let data = FileManager.default.contents(atPath: claudeHome + "/plugins/installed_plugins.json"),
              let file = try? JSONDecoder().decode(InstalledPlugins.self, from: data) else { return [] }
        return file.plugins.flatMap { key, installs in
            // A chave é "plugin@marketplace"; o prefixo da skill é só o plugin.
            let name = String(key.split(separator: "@").first ?? Substring(key))
            return installs.map { (name, $0.installPath) }
        }
    }

    private static func skills(in folder: String, prefix: String?, origin: String) -> [InstalledSkill] {
        let manager = FileManager.default
        guard let entries = try? manager.contentsOfDirectory(atPath: folder) else { return [] }
        return entries.compactMap { entry in
            let file = folder + "/" + entry + "/SKILL.md"
            guard let data = manager.contents(atPath: file) else { return nil }
            let front = frontMatter(String(decoding: data, as: UTF8.self))
            let base = front["name"].flatMap { $0.isEmpty ? nil : $0 } ?? entry
            return InstalledSkill(name: prefix.map { "\($0):\(base)" } ?? base, summary: front["description"] ?? "", origin: origin)
        }
    }

    /// Campos `chave: valor` de uma linha do cabeçalho YAML; o suficiente para nome e descrição.
    static func frontMatter(_ text: String) -> [String: String] {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else { return [:] }
        var fields: [String: String] = [:]
        for line in lines.dropFirst() {
            if line.trimmingCharacters(in: .whitespaces) == "---" { break }
            guard !line.hasPrefix(" "), let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces)
            var value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            if value.count >= 2, let first = value.first, first == value.last, first == "\"" || first == "'" {
                value = String(value.dropFirst().dropLast())
            }
            fields[key] = value
        }
        return fields
    }
}

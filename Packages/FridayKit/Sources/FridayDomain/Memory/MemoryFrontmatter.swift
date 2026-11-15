// Resumo: Lê e escreve o cabeçalho YAML simples das notas do vault (texto, lista e sim/não), sem depender de biblioteca de YAML.
// Tags: memoria

import Foundation

/// Cabeçalho de uma nota: os campos entre as duas linhas `---` do começo do arquivo.
/// Entende só o que o vault usa: `chave: valor`, `chave: [a, b]`, lista com `- item` e aspas simples ou duplas.
public struct MemoryFrontmatter: Equatable, Sendable {
    public var values: [String: String] = [:]
    public var lists: [String: [String]] = [:]

    public init(values: [String: String] = [:], lists: [String: [String]] = [:]) {
        self.values = values
        self.lists = lists
    }

    /// Separa cabeçalho e corpo. Sem cabeçalho, devolve cabeçalho vazio e o texto inteiro como corpo.
    public static func split(_ markdown: String) -> (frontmatter: MemoryFrontmatter, body: String) {
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false).map { $0.hasSuffix("\r") ? String($0.dropLast()) : String($0) }
        guard lines.first == "---", let end = lines.dropFirst().firstIndex(of: "---") else {
            return (MemoryFrontmatter(), markdown)
        }
        let header = parse(Array(lines[1..<end]))
        var body = lines[(end + 1)...].joined(separator: "\n")
        while body.hasPrefix("\n") { body.removeFirst() }
        return (header, body)
    }

    private static func parse(_ lines: [String]) -> MemoryFrontmatter {
        var result = MemoryFrontmatter()
        var openList: String?
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            if trimmed.hasPrefix("- "), let key = openList {
                result.lists[key, default: []].append(unquoted(String(trimmed.dropFirst(2))))
                continue
            }
            guard let colon = line.firstIndex(of: ":"), !line.hasPrefix(" ") else { openList = nil; continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces)
            let raw = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            if raw.isEmpty {
                openList = key
                result.lists[key] = []
            } else if raw.hasPrefix("[") && raw.hasSuffix("]") {
                openList = nil
                result.lists[key] = inlineItems(String(raw.dropFirst().dropLast()))
            } else {
                openList = nil
                result.values[key] = unquoted(raw)
            }
        }
        return result
    }

    /// Itens de `[a, "b, c", 'd']`, respeitando vírgula dentro de aspas.
    private static func inlineItems(_ text: String) -> [String] {
        var items: [String] = []
        var current = ""
        var quote: Character?
        var escaped = false
        for char in text {
            if escaped { current.append(char); escaped = false; continue }
            if char == "\\" && quote == "\"" { current.append(char); escaped = true; continue }
            if let open = quote {
                if char == open { quote = nil }
                current.append(char)
            } else if char == "\"" || char == "'" {
                quote = char
                current.append(char)
            } else if char == "," {
                items.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        items.append(current)
        return items.map { unquoted($0.trimmingCharacters(in: .whitespaces)) }.filter { !$0.isEmpty }
    }

    private static func unquoted(_ raw: String) -> String {
        let text = raw.trimmingCharacters(in: .whitespaces)
        guard text.count >= 2, let first = text.first, first == text.last, first == "\"" || first == "'" else { return text }
        let inner = String(text.dropFirst().dropLast())
        if first == "'" { return inner.replacingOccurrences(of: "''", with: "'") }
        var result = ""
        var escaped = false
        for char in inner {
            if escaped {
                result.append(char == "n" ? "\n" : char)
                escaped = false
            } else if char == "\\" {
                escaped = true
            } else {
                result.append(char)
            }
        }
        return result
    }

    /// Texto entre aspas duplas quando precisa; palavra simples fica como está.
    public static func quoted(_ text: String) -> String {
        let safe = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_./")
        if !text.isEmpty, text.allSatisfy(safe.contains) { return text }
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        return "\"" + escaped + "\""
    }
}

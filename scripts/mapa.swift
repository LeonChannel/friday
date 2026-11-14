// Resumo: Gera o docs/MAPA.md a partir dos cabeçalhos dos arquivos e confere resumo, tags e mapa atualizado.
// Tags: testes
//
// Uso: swift scripts/mapa.swift [--check]

import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let checkOnly = CommandLine.arguments.contains("--check")
let summaryLimit = 200
let scanned = ["Friday", "Packages/FridayKit/Sources", "Packages/FridayKit/Tests", "scripts"]

struct Entry {
    let path: String
    let layer: String
    let summary: String
    let tags: [String]
}

func read(_ relative: String) -> String? {
    try? String(contentsOf: root.appendingPathComponent(relative), encoding: .utf8)
}

func vocabulary() -> Set<String> {
    let text = read("docs/VOCABULARIO.md") ?? ""
    let tags = text.split(separator: "\n").compactMap { line -> String? in
        guard line.hasPrefix("| `") else { return nil }
        return line.split(separator: "`").dropFirst().first.map(String.init)
    }
    return Set(tags)
}

func layer(of path: String) -> String {
    if path.hasPrefix("Friday/") { return "App" }
    if path.hasPrefix("scripts/") { return "Script" }
    if path.contains("/Tests/") { return "Teste" }
    for name in ["Domain", "Infrastructure", "Features"] where path.contains("/Friday\(name)/") { return name }
    return "?"
}

var problems: [String] = []
var entries: [Entry] = []
let known = vocabulary()
if known.isEmpty { problems.append("docs/VOCABULARIO.md: nenhuma tag encontrada na tabela") }

for directory in scanned {
    let base = root.appendingPathComponent(directory)
    guard let walker = FileManager.default.enumerator(at: base, includingPropertiesForKeys: nil) else { continue }
    for case let url as URL in walker where url.pathExtension == "swift" && !url.path.contains("/.build/") {
        let path = String(url.path.dropFirst(root.path.count + 1))
        let lines = (read(path) ?? "").split(separator: "\n", omittingEmptySubsequences: false).prefix(2).map(String.init)
        guard lines.count == 2, lines[0].hasPrefix("// Resumo: "), lines[1].hasPrefix("// Tags: ") else {
            problems.append("\(path): falta o cabeçalho '// Resumo:' e '// Tags:' nas duas primeiras linhas")
            continue
        }
        let summary = String(lines[0].dropFirst("// Resumo: ".count)).trimmingCharacters(in: .whitespaces)
        let tags = lines[1].dropFirst("// Tags: ".count).split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if summary.isEmpty { problems.append("\(path): resumo vazio") }
        if summary.count > summaryLimit { problems.append("\(path): resumo com \(summary.count) caracteres (máximo \(summaryLimit))") }
        if tags.isEmpty { problems.append("\(path): nenhuma tag") }
        for tag in tags where !known.contains(tag) { problems.append("\(path): tag '\(tag)' fora do docs/VOCABULARIO.md") }
        entries.append(Entry(path: path, layer: layer(of: path), summary: summary, tags: tags))
    }
}

var output = """
# Mapa do código

Gerado por `swift scripts/mapa.swift` a partir do cabeçalho de cada arquivo. Não edite à mão: mude o cabeçalho e rode o script. Tags e significados em [VOCABULARIO.md](VOCABULARIO.md).

"""
for tag in known.sorted() {
    let tagged = entries.filter { $0.tags.contains(tag) }.sorted { $0.path < $1.path }
    guard !tagged.isEmpty else { continue }
    output += "\n## \(tag)\n\n| Arquivo | Camada | Resumo |\n|---|---|---|\n"
    for entry in tagged {
        output += "| [`\((entry.path as NSString).lastPathComponent)`](../\(entry.path)) | \(entry.layer) | \(entry.summary.replacingOccurrences(of: "|", with: "\\|")) |\n"
    }
}

let mapPath = root.appendingPathComponent("docs/MAPA.md")
if checkOnly, problems.isEmpty, read("docs/MAPA.md") != output {
    problems.append("docs/MAPA.md desatualizado: rode `swift scripts/mapa.swift`")
}
if !problems.isEmpty {
    FileHandle.standardError.write(Data((problems.joined(separator: "\n") + "\n").utf8))
    exit(1)
}
if !checkOnly {
    try output.write(to: mapPath, atomically: true, encoding: .utf8)
    print("docs/MAPA.md: \(entries.count) arquivos, \(Set(entries.flatMap(\.tags)).count) tags")
} else {
    print("mapa ok: \(entries.count) arquivos")
}

// Resumo: Uma nota do vault: camada, tipo, título, resumo que chega ao Claude, âncoras no código e o corpo, com leitura e escrita em markdown.
// Tags: memoria

import Foundation

/// Uma nota da memória. O `summary` é o que entra no contexto; o `body` é derivação, lida só sob demanda.
public struct MemoryNote: Equatable, Sendable, Identifiable {
    /// Caminho relativo à raiz do vault (`Projetos/friday/Regras/X.md`). É também a identidade da nota.
    public var path: String
    public var layer: MemoryLayer
    public var kind: MemoryNoteKind
    public var title: String
    public var summary: String
    /// Caminhos relativos à pasta do projeto; pasta termina em `/`.
    public var anchors: [String]
    /// Entra inteira no começo da sessão.
    public var always: Bool
    /// Data (`AAAA-MM-DD`) em que alguém conferiu no código.
    public var verifiedAt: String?
    /// Markdown abaixo do cabeçalho, com o `# Título`.
    public var body: String

    public var id: String { path }

    /// Cria uma nota validando tipo, título, resumo e âncoras.
    public init(
        path: String, layer: MemoryLayer, kind: MemoryNoteKind, title: String, summary: String,
        anchors: [String] = [], always: Bool? = nil, verifiedAt: String? = nil, body: String
    ) throws {
        guard kind.layer == layer else { throw MemoryNoteError.unknownKind(kind.rawValue, layer: layer) }
        let title = try MemoryNoteError.checked(title, field: "Título", limit: MemoryLimits.title)
        guard !title.isEmpty else { throw MemoryNoteError.emptyTitle }
        let summary = try MemoryNoteError.checked(summary, field: "Resumo", limit: MemoryLimits.summary)
        guard !summary.isEmpty else { throw MemoryNoteError.missingSummary }
        let anchors = anchors.map(Self.normalizedAnchor).filter { !$0.isEmpty }
        guard anchors.isEmpty || layer == .project else { throw MemoryNoteError.anchorsOutsideProject }
        self.path = path
        self.layer = layer
        self.kind = kind
        self.title = title
        self.summary = summary
        self.anchors = anchors
        self.always = always ?? layer.alwaysByDefault
        self.verifiedAt = verifiedAt
        // Quebra de linha no fim é do arquivo, não do conteúdo: sem isso a nota não volta igual do disco.
        var body = body
        while body.hasSuffix("\n") { body.removeLast() }
        self.body = body
    }

    /// Lê uma nota do markdown gravado. `layer` vem da pasta onde o arquivo está.
    public static func parse(markdown: String, path: String, layer: MemoryLayer) throws -> MemoryNote {
        let (header, body) = MemoryFrontmatter.split(markdown)
        guard let rawKind = header.values["tipo"], !rawKind.isEmpty else { throw MemoryNoteError.missingKind }
        guard let kind = MemoryNoteKind(rawValue: rawKind), kind.layer == layer else {
            throw MemoryNoteError.unknownKind(rawKind, layer: layer)
        }
        let always = header.values["sempre"].map { ["true", "sim", "yes"].contains($0.lowercased()) }
        return try MemoryNote(
            path: path, layer: layer, kind: kind, title: title(fromBody: body, path: path),
            summary: header.values["resumo"] ?? "", anchors: header.lists["ancoras"] ?? [],
            always: always, verifiedAt: header.values["verificado_em"], body: body
        )
    }

    /// Markdown completo, com o cabeçalho que o Friday entende.
    public var markdown: String {
        var lines = ["---", "tipo: \(kind.rawValue)", "resumo: \(MemoryFrontmatter.quoted(summary))"]
        if !anchors.isEmpty { lines.append("ancoras: [" + anchors.map(MemoryFrontmatter.quoted).joined(separator: ", ") + "]") }
        if always != layer.alwaysByDefault { lines.append("sempre: \(always)") }
        if let verifiedAt { lines.append("verificado_em: \(verifiedAt)") }
        lines.append("---")
        return lines.joined(separator: "\n") + "\n\n" + body + "\n"
    }

    /// Corpo sem a primeira linha `# Título` (que já aparece como título).
    public var bodyWithoutTitle: String {
        var lines = body.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        if let first = lines.firstIndex(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }), lines[first].hasPrefix("# ") {
            lines.remove(at: first)
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Diz se a nota está ancorada no arquivo (caminho relativo à pasta do projeto).
    public func isAnchored(to relativePath: String) -> Bool {
        let file = Self.normalizedAnchor(relativePath)
        return anchors.contains { anchor in
            anchor.hasSuffix("/") ? file.hasPrefix(anchor) : file == anchor
        }
    }

    private static func title(fromBody body: String, path: String) -> String {
        for line in body.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            if trimmed.hasPrefix("# ") { return String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces) }
            break
        }
        let file = path.split(separator: "/").last.map(String.init) ?? path
        return file.hasSuffix(".md") ? String(file.dropLast(3)) : file
    }

    private static func normalizedAnchor(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespaces)
        while text.hasPrefix("./") { text.removeFirst(2) }
        while text.hasPrefix("/") { text.removeFirst() }
        return text
    }
}

/// Uma nota que não pôde ser lida, com o motivo. Aparece na tela de Memória em vez de sumir em silêncio.
public struct MemoryIssue: Equatable, Sendable, Identifiable {
    public var path: String
    public var message: String
    public var id: String { path }

    public init(path: String, message: String) {
        self.path = path
        self.message = message
    }
}

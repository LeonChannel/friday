// Resumo: Monta o que o Claude recebe da memória: o contexto do início da sessão, com ordem e teto, e as notas ancoradas no arquivo que ele abriu.
// Tags: memoria

import Foundation

/// O que a memória tem para uma sessão, já lido do vault.
public struct MemorySnapshot: Equatable, Sendable {
    public var vaultPath: String
    public var abstraction: [MemoryNote]
    public var process: [MemoryNote]
    public var project: [MemoryNote]
    /// Nome do projeto da sessão; `nil` quando a pasta não é de nenhum projeto do Friday.
    public var projectName: String?

    public init(vaultPath: String, abstraction: [MemoryNote] = [], process: [MemoryNote] = [], project: [MemoryNote] = [], projectName: String? = nil) {
        self.vaultPath = vaultPath
        self.abstraction = abstraction
        self.process = process
        self.project = project
        self.projectName = projectName
    }

    /// Hub do projeto, se existir.
    public var projectHub: MemoryNote? { project.first { $0.kind == .projectHub } }
}

/// Texto pronto para o agente, com a contagem de onde saiu (a tela mostra o custo).
public struct MemoryBriefing: Equatable, Sendable {
    public var text: String
    /// Notas que entraram (inteiras ou no índice).
    public var included: Int
    /// Notas que ficaram fora do teto.
    public var omitted: Int

    public var characters: Int { text.count }
    /// Estimativa grosseira (4 caracteres por token), só para a tela dar a ordem de grandeza.
    public var estimatedTokens: Int { (characters + 3) / 4 }

    /// Contexto do início da sessão. Ordem: abstração, área de trabalho, processual `sempre`, hub do projeto, índice do resto.
    public static func sessionStart(_ snapshot: MemorySnapshot, workArea: String? = nil, limit: Int = MemoryLimits.sessionStart) -> MemoryBriefing {
        var builder = Builder(limit: limit)
        builder.add(block: [
            "# Memória do Friday",
            "Vault: `\(snapshot.vaultPath)`. É o mapa, não a verdade: nota lida é hipótese até conferir no código desta sessão. Divergiu? Corrija a nota (`friday memoria nota`) em vez de seguir com as duas versões.",
        ].joined(separator: "\n"), notes: 0)

        if !snapshot.abstraction.isEmpty {
            builder.add(block: "## Abstração: como falar e se portar", notes: 0)
            for note in snapshot.abstraction where note.always { builder.addInline(note) }
        }
        if let workArea { builder.add(block: workArea, notes: 0) }

        let processAlways = snapshot.process.filter(\.always)
        if !processAlways.isEmpty {
            builder.add(block: "## Processual: como o trabalho anda", notes: 0)
            for note in processAlways { builder.addInline(note) }
        }
        if let name = snapshot.projectName {
            builder.add(block: "## Projeto: \(name)", notes: 0)
            if let hub = snapshot.projectHub { builder.addInline(hub, heading: false) }
            for note in snapshot.project where note.kind != .projectHub && note.always { builder.addInline(note) }
        }

        let indexed = snapshot.abstraction.filter { !$0.always }
            + snapshot.process.filter { !$0.always }
            + snapshot.project.filter { $0.kind != .projectHub && !$0.always }
        if !indexed.isEmpty {
            builder.add(block: "## Índice (resumo; a nota inteira: `friday memoria ler \"<caminho>\"`)", notes: 0)
            for note in indexed { builder.addLine("- [\(note.kind.rawValue)] \(note.title) — \(note.summary) (\(note.path))", notes: 1) }
            builder.add(block: "Nota ancorada num arquivo chega sozinha quando você abre o arquivo.", notes: 0)
        }
        return builder.finish()
    }

    /// Notas do projeto ancoradas no arquivo, na ordem do vault, até o teto por arquivo.
    public static func anchored(_ notes: [MemoryNote], toFile relativePath: String) -> [MemoryNote] {
        Array(notes.filter { $0.isAnchored(to: relativePath) }.prefix(MemoryLimits.anchoredPerFile))
    }

    /// Texto entregue ao abrir um arquivo: o resumo de cada nota ancorada e o lembrete de conferir no código.
    public static func fileDelivery(_ notes: [MemoryNote], file relativePath: String) -> String? {
        guard !notes.isEmpty else { return nil }
        var lines = ["O vault tem nota(s) ancorada(s) em `\(relativePath)`:"]
        for note in notes {
            let verified = note.verifiedAt.map { " · conferida em \($0)" } ?? ""
            lines.append("- [\(note.kind.rawValue)] \(note.title)\(verified) — \(note.summary) (\(note.path))")
        }
        lines.append("É mapa, não verdade: a verdade é o código que você está abrindo. Divergiu? Corrija a nota com `friday memoria nota`.")
        return lines.joined(separator: "\n")
    }

    /// Junta blocos respeitando o teto; o que não cabe vira contagem.
    private struct Builder {
        let limit: Int
        var parts: [String] = []
        var size = 0
        var included = 0
        var omitted = 0
        /// Reserva para a linha final de "fora do teto".
        let reserve = 80

        init(limit: Int) { self.limit = limit }

        mutating func add(block: String, notes: Int) {
            let cost = block.count + 2
            guard size + cost <= limit - reserve else { omitted += notes; return }
            parts.append(block)
            size += cost
            included += notes
        }

        mutating func addInline(_ note: MemoryNote, heading: Bool = true) {
            // Título de dentro da nota desce dois níveis, para não competir com as seções do contexto.
            var body = note.bodyWithoutTitle
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map { $0.hasPrefix("#") ? "##" + $0 : String($0) }
                .joined(separator: "\n")
            if body.isEmpty { body = note.summary }
            if body.count > MemoryLimits.inlineNote {
                body = String(body.prefix(MemoryLimits.inlineNote)) + "\n[cortado: `friday memoria ler \"\(note.path)\"`]"
            }
            add(block: heading ? "### \(note.title)\n\(body)" : body, notes: 1)
        }

        /// Linha colada ao bloco anterior (sem linha em branco), para o índice não pagar separador.
        mutating func addLine(_ line: String, notes: Int) {
            let cost = line.count + 1
            guard !parts.isEmpty, size + cost <= limit - reserve else { omitted += notes; return }
            parts[parts.count - 1] += "\n" + line
            size += cost
            included += notes
        }

        func finish() -> MemoryBriefing {
            var text = parts.joined(separator: "\n\n")
            if omitted > 0 { text += "\n\n+\(omitted) nota(s) fora do teto: `friday memoria listar`." }
            return MemoryBriefing(text: text, included: included, omitted: omitted)
        }
    }
}

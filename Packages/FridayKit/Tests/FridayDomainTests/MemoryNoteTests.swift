// Resumo: Prova a leitura e a escrita das notas do vault: cabeçalho, tipos por camada, tetos, âncoras, nomes em ASCII e caminhos seguros.
// Tags: memoria, testes

import FridayDomain
import Testing

struct MemoryNoteTests {
    private let rule = """
        ---
        tipo: regra
        resumo: "A view nunca grava no banco: \\"tudo\\" passa pelo repositório."
        ancoras: [Sources/Infra/, "Friday/App/FridayApp.swift"]
        verificado_em: 2026-11-14
        ---

        # Escrita só pelo repositório

        Derivação longa.
        """

    @Test func parsesQuotedSummaryAndInlineAnchors() throws {
        let note = try MemoryNote.parse(markdown: rule, path: "Projetos/f/Regras/Escrita.md", layer: .project)
        #expect(note.kind == .rule)
        #expect(note.title == "Escrita só pelo repositório")
        #expect(note.summary == "A view nunca grava no banco: \"tudo\" passa pelo repositório.")
        #expect(note.anchors == ["Sources/Infra/", "Friday/App/FridayApp.swift"])
        #expect(note.verifiedAt == "2026-11-14")
        #expect(!note.always)
        #expect(note.bodyWithoutTitle == "Derivação longa.")
    }

    @Test func parsesBlockListAndAlwaysFlag() throws {
        let text = "---\ntipo: fluxo\nresumo: Antes, durante, depois.\nsempre: true\nancoras:\n  - a.swift\n---\nCorpo sem título."
        #expect(throws: MemoryNoteError.anchorsOutsideProject) { try MemoryNote.parse(markdown: text, path: "Processual/Fluxo.md", layer: .process) }
        let withoutAnchors = text.replacingOccurrences(of: "ancoras:\n  - a.swift\n", with: "")
        let note = try MemoryNote.parse(markdown: withoutAnchors, path: "Processual/Fluxo.md", layer: .process)
        #expect(note.always)
        #expect(note.title == "Fluxo")
    }

    @Test func abstractionIsAlwaysByDefault() throws {
        let note = try MemoryNote.parse(markdown: "---\ntipo: conduta\nresumo: Pare só em três casos.\n---\n# Conduta", path: "Abstracao/Conduta.md", layer: .abstraction)
        #expect(note.always)
        #expect(!note.markdown.contains("sempre:"))
    }

    @Test func rejectsKindFromAnotherLayerMissingSummaryAndLongSummary() {
        #expect(throws: MemoryNoteError.unknownKind("regra", layer: .abstraction)) {
            try MemoryNote.parse(markdown: "---\ntipo: regra\nresumo: x\n---\n", path: "Abstracao/x.md", layer: .abstraction)
        }
        #expect(throws: MemoryNoteError.missingKind) { try MemoryNote.parse(markdown: "# Sem cabeçalho", path: "Abstracao/x.md", layer: .abstraction) }
        #expect(throws: MemoryNoteError.missingSummary) {
            try MemoryNote.parse(markdown: "---\ntipo: conduta\n---\n", path: "Abstracao/x.md", layer: .abstraction)
        }
        let long = String(repeating: "a", count: MemoryLimits.summary + 1)
        #expect(throws: MemoryNoteError.tooLong(field: "Resumo", limit: MemoryLimits.summary, actual: MemoryLimits.summary + 1)) {
            try MemoryNote.parse(markdown: "---\ntipo: conduta\nresumo: \(long)\n---\n", path: "Abstracao/x.md", layer: .abstraction)
        }
    }

    @Test func markdownRoundTrips() throws {
        let note = try MemoryNote(
            path: "Projetos/f/Armadilhas/X.md", layer: .project, kind: .pitfall, title: "Trava, com vírgula",
            summary: "Linha com \"aspas\", vírgula: e dois-pontos.", anchors: ["a b/c.swift", "pasta/"], verifiedAt: "2026-11-14",
            body: "# Trava, com vírgula\n\nCorpo."
        )
        let parsed = try MemoryNote.parse(markdown: note.markdown, path: note.path, layer: .project)
        #expect(parsed == note)
    }

    @Test func anchorsMatchFileOrFolderPrefix() throws {
        let note = try MemoryNote(path: "p.md", layer: .project, kind: .rule, title: "T", summary: "S", anchors: ["./Sources/Infra/", "App.swift"], body: "")
        #expect(note.isAnchored(to: "Sources/Infra/Banco.swift"))
        #expect(note.isAnchored(to: "/App.swift"))
        #expect(!note.isAnchored(to: "Sources/InfraOutra/Banco.swift"))
        #expect(!note.isAnchored(to: "Outro/App.swift"))
    }

    @Test(arguments: [
        ("Lousa de Refinamento", "Lousa de Refinamento"),
        ("Ação/API", "Acao-API"),
        ("  --Café: com leite?--  ", "Cafe- com leite"),
        ("ééé", "eee"),
        ("///", "sem-nome"),
    ])
    func slugIsAsciiAndStable(input: String, expected: String) {
        #expect(VaultPaths.slug(input) == expected)
    }

    @Test func pathsForEachLayerAndSafety() {
        #expect(VaultPaths.newNote(title: "Escrita", kind: .rule, projectName: "Friday App") == "Projetos/Friday App/Regras/Escrita.md")
        #expect(VaultPaths.newNote(title: "Tom", kind: .communication, projectName: nil) == "Abstracao/Tom.md")
        #expect(VaultPaths.projectHub("Ação") == "Projetos/Acao/00 - Acao.md")
        #expect(VaultPaths.workAreaState(projectName: "f", subject: 3) == "Projetos/f/Trabalho/assunto-3/estado.md")
        #expect(VaultPaths.isSafeNotePath("Projetos/f/Regras/X.md"))
        #expect(!VaultPaths.isSafeNotePath("../fora.md"))
        #expect(!VaultPaths.isSafeNotePath("/etc/x.md"))
        #expect(!VaultPaths.isSafeNotePath("Projetos/f/x.txt"))
    }
}

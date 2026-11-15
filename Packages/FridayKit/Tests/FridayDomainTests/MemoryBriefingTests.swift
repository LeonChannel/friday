// Resumo: Prova o que a memória entrega ao Claude: ordem e teto do contexto de início, corte de nota longa, entrega por âncora, área de trabalho e promoção de decisão.
// Tags: memoria, testes

import FridayDomain
import Foundation
import Testing

struct MemoryBriefingTests {
    private func note(_ path: String, _ layer: MemoryLayer, _ kind: MemoryNoteKind, title: String, summary: String = "resumo",
                      body: String = "corpo", anchors: [String] = [], always: Bool? = nil) throws -> MemoryNote {
        try MemoryNote(path: path, layer: layer, kind: kind, title: title, summary: summary, anchors: anchors, always: always, body: "# \(title)\n\n\(body)")
    }

    private func snapshot() throws -> MemorySnapshot {
        MemorySnapshot(
            vaultPath: "/v",
            abstraction: [try note("Abstracao/Tom.md", .abstraction, .communication, title: "Tom", body: "Fale direto.")],
            process: [
                try note("Processual/Fluxo.md", .process, .flow, title: "Fluxo", body: "Antes e depois.", always: true),
                try note("Processual/Registro.md", .process, .flow, title: "Registro", summary: "o que vira nota"),
            ],
            project: [
                try note("Projetos/f/00 - f.md", .project, .projectHub, title: "f", body: "Swift e GRDB."),
                try note("Projetos/f/Regras/Banco.md", .project, .rule, title: "Banco", summary: "view não grava", anchors: ["Sources/"]),
            ],
            projectName: "f"
        )
    }

    @Test func orderIsAbstractionWorkAreaProcessProjectThenIndex() throws {
        let briefing = MemoryBriefing.sessionStart(try snapshot(), workArea: "## Área de trabalho: assunto 2")
        let text = briefing.text
        let marks = ["Fale direto.", "## Área de trabalho", "Antes e depois.", "## Projeto: f", "Swift e GRDB.", "## Índice",
                     "- [fluxo] Registro — o que vira nota (Processual/Registro.md)", "- [regra] Banco — view não grava (Projetos/f/Regras/Banco.md)"]
        let positions = try marks.map { try #require(text.range(of: $0)?.lowerBound, "falta \($0)") }
        #expect(positions == positions.sorted())
        #expect(briefing.included == 5 && briefing.omitted == 0)
        #expect(!text.contains("view não grava\n\n- ["), "o índice não paga linha em branco entre itens")
    }

    @Test func respectsLimitAndCountsWhatWasLeftOut() throws {
        var snap = try snapshot()
        snap.project += try (1...200).map { try note("Projetos/f/Regras/R\($0).md", .project, .rule, title: "Regra \($0)", summary: String(repeating: "x", count: 200)) }
        let briefing = MemoryBriefing.sessionStart(snap)
        #expect(briefing.characters <= MemoryLimits.sessionStart)
        #expect(briefing.omitted > 0)
        #expect(briefing.text.hasSuffix("+\(briefing.omitted) nota(s) fora do teto: `friday memoria listar`."))
        #expect(briefing.included + briefing.omitted == 205)
    }

    @Test func inlineHeadingsAreDemotedBelowContextSections() throws {
        let conduct = try note("Abstracao/Conduta.md", .abstraction, .conduct, title: "Conduta", body: "## Quando parar\n\n1. dúvida")
        let text = MemoryBriefing.sessionStart(MemorySnapshot(vaultPath: "/v", abstraction: [conduct])).text
        #expect(text.contains("### Conduta\n#### Quando parar"))
    }

    @Test func longInlineNoteIsCutWithPointer() throws {
        let long = try note("Abstracao/Longa.md", .abstraction, .conduct, title: "Longa", body: String(repeating: "y", count: 5_000))
        let briefing = MemoryBriefing.sessionStart(MemorySnapshot(vaultPath: "/v", abstraction: [long]))
        #expect(briefing.text.contains("[cortado: `friday memoria ler \"Abstracao/Longa.md\"`]"))
        #expect(!briefing.text.contains(String(repeating: "y", count: MemoryLimits.inlineNote + 1)))
    }

    @Test func fileDeliveryListsAnchoredSummariesUpToCap() throws {
        let notes = try (1...7).map { try note("Projetos/f/Regras/R\($0).md", .project, .rule, title: "R\($0)", summary: "s\($0)", anchors: ["Sources/"]) }
            + [try note("Projetos/f/Regras/Outra.md", .project, .rule, title: "Outra", anchors: ["Docs/"])]
        let anchored = MemoryBriefing.anchored(notes, toFile: "Sources/A.swift")
        #expect(anchored.map(\.title) == ["R1", "R2", "R3", "R4", "R5"])
        let text = try #require(MemoryBriefing.fileDelivery(anchored, file: "Sources/A.swift"))
        #expect(text.hasPrefix("O vault tem nota(s) ancorada(s) em `Sources/A.swift`:"))
        #expect(text.contains("- [regra] R1 — s1 (Projetos/f/Regras/R1.md)"))
        #expect(MemoryBriefing.fileDelivery([], file: "x") == nil)
    }

    @Test func workAreaRoundTripsAndFlagsChangedCode() throws {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let state = try WorkAreaState(subjectID: 4, text: "Fase: medir. Próximo: p95.", updatedAt: date, head: "a1b2c3d4e5")
        let parsed = try #require(WorkAreaState.parse(markdown: state.markdown, subjectID: 4))
        #expect(parsed == state)
        #expect(!state.codeChanged(currentHead: nil))
        #expect(!state.codeChanged(currentHead: "a1b2c3d4e5"))
        #expect(state.codeChanged(currentHead: "ffff000000"))
        #expect(state.resumeText(subject: nil, currentHead: "ffff000000").contains("viraram pista"))
        #expect(!state.resumeText(subject: nil, currentHead: "a1b2c3d4e5").contains("pista"))
        #expect(throws: MemoryNoteError.self) {
            try WorkAreaState(subjectID: 1, text: String(repeating: "z", count: MemoryLimits.workAreaState + 1), updatedAt: date, head: nil)
        }
    }

    @Test func promotedDecisionCarriesWhyAndOrigin() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var subject = try Subject(id: 9, title: "Fila de imagens", createdAt: now)
        try subject.recordDecision(text: "Redimensionar no cliente.", reason: "corta 48% do custo.", changeIf: "o app ficar lento", at: now)
        let note = try MemoryNote.promoting(subject.decisions[0], of: subject, projectName: "f", today: "2026-11-14")
        #expect(note.path == "Projetos/f/Decisoes/Redimensionar no cliente.md")
        #expect(note.kind == .decision && note.layer == .project)
        #expect(note.summary == "Redimensionar no cliente. Porque corta 48% do custo.")
        #expect(note.body.contains("- **Mudaria se:** o app ficar lento"))
        #expect(note.body.contains("- **Origem:** assunto 9 · Fila de imagens"))
    }
}

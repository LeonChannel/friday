// Resumo: Prova a jornada e o assunto com etapas: limpeza da configuração, briefing do Claude, avanço das etapas e a vez que elas dão.
// Tags: jornadas, assuntos, testes

import Foundation
import Testing
@testable import FridayDomain

struct JourneyTests {
    private let now = Date(timeIntervalSince1970: 1_000)

    @Test func emptyJourneyIsEmptyAndCleansBlanksAndDuplicates() {
        #expect(Journey(kind: .error).isEmpty)
        let journey = Journey(kind: .task, prompt: "  ", skills: ["a", " a ", "", "b"], stages: ["Planejar", " ", "Planejar", String(repeating: "x", count: 60)])
        #expect(!journey.isEmpty)
        #expect(journey.cleanSkills == ["a", "b"])
        #expect(journey.cleanStages == ["Planejar", String(repeating: "x", count: SubjectLimits.stageName)])
    }

    @Test func stagesAreCappedAtLimit() {
        let journey = Journey(kind: .milestone, stages: (1...12).map { "e\($0)" })
        #expect(journey.cleanStages.count == Journey.stageLimit)
    }

    @Test func briefingCarriesRequestPromptSkillsAndStages() throws {
        let subject = try Subject(id: 7, title: "Login cai", intent: "500 no /auth", activity: .error, stages: ["Reproduzir", "Causa"], createdAt: now)
        let text = JourneyBriefing.text(subject: subject, journey: Journey(kind: .error, prompt: "Comece pelo log.", skills: ["investigar", "plugin:fix"]))
        #expect(text == """
            Assunto 7 no Friday (Erro): Login cai

            500 no /auth

            Como conduzir:
            Comece pelo log.

            Use as skills: investigar, plugin:fix.

            Etapas (a lousa do dev mostra este trilho):
            1. Reproduzir
            2. Causa
            Marque cada etapa com `friday etapa 7 <n> --estado rodando|esperando-voce|concluida [--nota "..."]`.

            Registre o estado do assunto 7 com a skill friday-assunto (`friday assunto ler 7` primeiro).
            """)
    }

    @Test func emptyJourneyBriefingIsOnlyTheRequest() throws {
        let subject = try Subject(id: 2, title: "Por que isso?", activity: .question, createdAt: now)
        let text = JourneyBriefing.text(subject: subject, journey: Journey(kind: .question))
        #expect(text == "Assunto 2 no Friday (Dúvida): Por que isso?\n\nRegistre o estado do assunto 2 com a skill friday-assunto (`friday assunto ler 2` primeiro).")
        #expect(!text.hasPrefix("-"))
    }

    @Test func runningAStageClosesEarlierOnesAndGivesClaudeTheTurn() throws {
        var subject = try Subject(title: "t", activity: .error, stages: ["A", "B", "C"], createdAt: now)
        #expect(subject.turn.holder == .idle)
        try subject.setStage(2, state: .running, at: now)
        #expect(subject.stages.map(\.state) == [.done, .running, .pending])
        #expect(subject.turn == SubjectTurn(holder: .claude, reason: "etapa B"))
    }

    @Test func waitingStageGivesYouTheTurnWithNote() throws {
        var subject = try Subject(title: "t", activity: .task, stages: ["Plano", "Código"], createdAt: now)
        try subject.setStage(1, state: .waitingForYou, note: "Plano pronto para aprovar", at: now)
        #expect(subject.stages[0].note == "Plano pronto para aprovar")
        #expect(subject.turn == SubjectTurn(holder: .you, reason: "etapa Plano esperando você"))
    }

    @Test func unknownStageAndLongNoteAreRefused() throws {
        var subject = try Subject(title: "t", stages: ["A"], createdAt: now)
        #expect(throws: SubjectError.unknownStage(2)) { try subject.setStage(2, state: .done, at: now) }
        #expect(throws: SubjectError.unknownStage(0)) { try subject.setStage(0, state: .done, at: now) }
        #expect(throws: SubjectError.tooLong(field: "Nota da etapa", limit: SubjectLimits.stageNote, actual: 161)) {
            try subject.setStage(1, state: .done, note: String(repeating: "n", count: 161), at: now)
        }
    }
}

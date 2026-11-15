// Resumo: O assunto: título, intenção e as partes que o dev e o Claude desenvolvem juntos, com validação de teto em cada escrita.
// Tags: assuntos

import Foundation

/// Uma investigação, hipótese ou problema que o dev e o Claude desenvolvem juntos. Guarda estado, não conversa.
public struct Subject: Equatable, Sendable, Identifiable {
    public var id: Int64?
    public var title: String
    public var projectID: Int64?
    public var createdAt: Date
    public var updatedAt: Date
    public var intent: String
    /// Tipo de atividade que abriu o assunto; nil nos assuntos de antes das jornadas.
    public var activity: ActivityKind?
    public private(set) var questions: [Question]
    public private(set) var evidences: [Evidence]
    public private(set) var alternatives: [Alternative]
    public private(set) var decisions: [Decision]
    public private(set) var fronts: [Front]
    /// Trilho da jornada: etapas copiadas da configuração na criação, para mudar a jornada não mexer no que já roda.
    public private(set) var stages: [Stage]

    /// Cria o assunto validando título e intenção contra os tetos.
    public init(
        id: Int64? = nil, title: String, projectID: Int64? = nil, intent: String = "",
        activity: ActivityKind? = nil, stages: [String] = [], createdAt: Date
    ) throws {
        self.id = id
        self.activity = activity
        self.stages = try stages.map { Stage(name: try SubjectLimits.validated($0, field: "Etapa", limit: SubjectLimits.stageName)) }
        self.title = try SubjectLimits.validated(title, field: "Título", limit: SubjectLimits.title)
        self.projectID = projectID
        self.intent = try Self.validatedIntent(intent)
        self.createdAt = createdAt
        self.updatedAt = createdAt
        questions = []
        evidences = []
        alternatives = []
        decisions = []
        fronts = []
    }

    /// Remonta o assunto do que foi gravado, sem revalidar (o que está no banco já passou pela validação).
    public init(
        id: Int64?, title: String, projectID: Int64?, intent: String, createdAt: Date, updatedAt: Date,
        questions: [Question], evidences: [Evidence], alternatives: [Alternative], decisions: [Decision], fronts: [Front],
        activity: ActivityKind? = nil, stages: [Stage] = []
    ) {
        self.activity = activity
        self.stages = stages
        self.id = id
        self.title = title
        self.projectID = projectID
        self.intent = intent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.questions = questions
        self.evidences = evidences
        self.alternatives = alternatives
        self.decisions = decisions
        self.fronts = fronts
    }

    private static func validatedIntent(_ text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "" : try SubjectLimits.validated(trimmed, field: "Intenção", limit: SubjectLimits.intent)
    }

    /// Troca a intenção.
    public mutating func setIntent(_ text: String, at now: Date) throws {
        intent = try Self.validatedIntent(text)
        updatedAt = now
    }

    /// Registra um fato com fonte e grau.
    @discardableResult
    public mutating func addEvidence(fact: String, source: String, grade: EvidenceGrade, at now: Date) throws -> Evidence {
        let evidence = Evidence(
            id: (evidences.map(\.id).max() ?? 0) + 1,
            fact: try SubjectLimits.validated(fact, field: "Evidência", limit: SubjectLimits.evidence),
            source: try SubjectLimits.validated(source, field: "Fonte", limit: SubjectLimits.evidenceSource),
            grade: grade, recordedAt: now
        )
        evidences.append(evidence)
        updatedAt = now
        return evidence
    }

    /// Abre uma pergunta, com opções e consequências se houver.
    @discardableResult
    public mutating func addQuestion(text: String, options: [QuestionOption] = [], waitsForYou: Bool = false, at now: Date) throws -> Question {
        let question = Question(
            id: (questions.map(\.id).max() ?? 0) + 1,
            text: try SubjectLimits.validated(text, field: "Pergunta", limit: SubjectLimits.question),
            options: try options.map {
                QuestionOption(
                    label: try SubjectLimits.validated($0.label, field: "Opção", limit: SubjectLimits.optionLabel),
                    consequence: try SubjectLimits.validated($0.consequence, field: "Consequência", limit: SubjectLimits.optionConsequence)
                )
            },
            waitsForYou: waitsForYou, askedAt: now, answeredAt: nil
        )
        questions.append(question)
        updatedAt = now
        return question
    }

    /// Acrescenta uma alternativa comparada.
    @discardableResult
    public mutating func addAlternative(name: String, gain: String, risk: String, effort: String, reversibility: String, at now: Date) throws -> Alternative {
        let limit = SubjectLimits.alternativeDetail
        let alternative = Alternative(
            id: (alternatives.map(\.id).max() ?? 0) + 1,
            name: try SubjectLimits.validated(name, field: "Alternativa", limit: SubjectLimits.alternativeName),
            gain: try SubjectLimits.validated(gain, field: "Ganho", limit: limit),
            risk: try SubjectLimits.validated(risk, field: "Risco", limit: limit),
            effort: try SubjectLimits.validated(effort, field: "Esforço", limit: limit),
            reversibility: try SubjectLimits.validated(reversibility, field: "Reversibilidade", limit: limit)
        )
        alternatives.append(alternative)
        updatedAt = now
        return alternative
    }

    /// Registra uma decisão; se `answering` aponta uma pergunta, ela deixa de estar em aberto.
    @discardableResult
    public mutating func recordDecision(text: String, reason: String, changeIf: String? = nil, answering questionID: Int? = nil, at now: Date) throws -> Decision {
        let decision = Decision(
            id: (decisions.map(\.id).max() ?? 0) + 1,
            text: try SubjectLimits.validated(text, field: "Decisão", limit: SubjectLimits.decision),
            reason: try SubjectLimits.validated(reason, field: "Porquê", limit: SubjectLimits.decisionReason),
            changeIf: try changeIf.map { try SubjectLimits.validated($0, field: "Mudaria se", limit: SubjectLimits.decisionChangeIf) },
            decidedAt: now
        )
        if let questionID {
            guard let index = questions.firstIndex(where: { $0.id == questionID }) else { throw SubjectError.unknownQuestion(questionID) }
            questions[index].answeredAt = now
        }
        decisions.append(decision)
        updatedAt = now
        return decision
    }

    /// Cria a frente ou atualiza a que tem o mesmo nome (sem diferenciar maiúsculas). Só informa o que muda.
    @discardableResult
    public mutating func upsertFront(
        name: String, criterion: String? = nil, state: FrontState? = nil, steps: [String]? = nil, doneSteps: Int? = nil, at now: Date
    ) throws -> Front {
        let name = try SubjectLimits.validated(name, field: "Frente", limit: SubjectLimits.frontName)
        let index = fronts.firstIndex { $0.name.compare(name, options: .caseInsensitive) == .orderedSame }
        var front: Front
        if let index {
            front = fronts[index]
        } else {
            guard let criterion else { throw SubjectError.frontNeedsCriterion(name) }
            front = Front(name: name, criterion: criterion, state: .running, steps: [], updatedAt: now)
        }
        if let criterion { front.criterion = try SubjectLimits.validated(criterion, field: "Critério", limit: SubjectLimits.frontCriterion) }
        if let steps {
            front.steps = try steps.map { FrontStep(text: try SubjectLimits.validated($0, field: "Passo", limit: SubjectLimits.frontStep), isDone: false) }
        }
        if let doneSteps {
            for i in front.steps.indices { front.steps[i].isDone = i < doneSteps }
        }
        if let state { front.state = state }
        front.updatedAt = now
        if let index { fronts[index] = front } else { fronts.append(front) }
        updatedAt = now
        return front
    }

    /// Muda o estado de uma etapa (`number` começa em 1). Etapa que passa a rodar ou esperar você vira a atual:
    /// as anteriores ainda pendentes viram concluídas, porque a jornada anda em ordem.
    @discardableResult
    public mutating func setStage(_ number: Int, state: StageState, note: String? = nil, at now: Date) throws -> Stage {
        guard stages.indices.contains(number - 1) else { throw SubjectError.unknownStage(number) }
        let index = number - 1
        if let note { stages[index].note = try SubjectLimits.validated(note, field: "Nota da etapa", limit: SubjectLimits.stageNote) }
        stages[index].state = state
        stages[index].updatedAt = now
        if state != .pending {
            for earlier in stages.indices where earlier < index && stages[earlier].state != .done {
                stages[earlier].state = .done
                stages[earlier].updatedAt = now
            }
        }
        updatedAt = now
        return stages[index]
    }
}

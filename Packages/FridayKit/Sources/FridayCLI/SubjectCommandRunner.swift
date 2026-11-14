// Resumo: Executa os comandos `friday` (assunto, evidência, pergunta, decisão, frente, alternativa) contra o banco e devolve texto curto e estável.
// Tags: assuntos, persistencia

import FridayDomain
import FridayInfrastructure
import Foundation

/// Resultado de um comando: o que imprimir, o código de saída e se houve escrita (para avisar o app).
public struct CommandOutcome: Equatable, Sendable {
    public var exitCode: Int32
    public var output: String
    public var errorOutput: String
    public var wrote: Bool
}

/// Interpreta os argumentos de `friday` e grava no banco. A fronteira do processo (ler argumentos, imprimir, sair) fica no executável.
public struct SubjectCommandRunner: Sendable {
    private let repository: any SubjectRepository
    private let now: @Sendable () -> Date

    public init(repository: any SubjectRepository, now: @escaping @Sendable () -> Date = Date.init) {
        self.repository = repository
        self.now = now
    }

    static let usage = """
        Uso:
          friday assunto novo "<título>" [--intencao "..."] [--projeto <id>]
          friday assunto listar
          friday assunto ler <id>
          friday assunto intencao <id> "<texto>"
          friday evidencia <id> --grau medido|codigo|inferido --fonte "..." "<fato>"
          friday pergunta <id> "<texto>" [--opcao "rótulo|consequência"]... [--espera-voce]
          friday alternativa <id> "<nome>" --ganho "..." --risco "..." --esforco "..." --reversivel "..."
          friday decisao <id> "<decisão>" --porque "..." [--mudaria-se "..."] [--responde <n da pergunta>]
          friday frente <id> "<nome>" [--criterio "..."] [--estado rodando|esperando-voce|concluida] [--passo "..."]... [--feitos <n>]
        """

    /// Roda um comando. Erro de uso ou de validação vira saída de erro e código diferente de zero.
    public func run(_ arguments: [String]) -> CommandOutcome {
        do {
            return try dispatch(arguments)
        } catch let error as UsageError {
            return CommandOutcome(exitCode: 2, output: "", errorOutput: "\(error.message)\n", wrote: false)
        } catch {
            return CommandOutcome(exitCode: 1, output: "", errorOutput: "\(error.localizedDescription)\n", wrote: false)
        }
    }

    private func ok(_ text: String, wrote: Bool = false) -> CommandOutcome {
        CommandOutcome(exitCode: 0, output: text + "\n", errorOutput: "", wrote: wrote)
    }

    private func dispatch(_ arguments: [String]) throws -> CommandOutcome {
        guard let command = arguments.first else { throw UsageError(message: Self.usage) }
        let rest = Array(arguments.dropFirst())
        switch command {
        case "assunto": return try subjectCommand(rest)
        case "evidencia": return try evidence(rest)
        case "pergunta": return try question(rest)
        case "alternativa": return try alternative(rest)
        case "decisao": return try decision(rest)
        case "frente": return try front(rest)
        case "ajuda", "--ajuda", "-h", "--help": return ok(Self.usage)
        default: throw UsageError(message: "Comando desconhecido: \(command).\n\(Self.usage)")
        }
    }

    private func subjectID(_ text: String) throws -> Int64 {
        guard let id = Int64(text) else { throw UsageError(message: "\"\(text)\" não é um id de assunto.") }
        return id
    }

    private func subjectCommand(_ tokens: [String]) throws -> CommandOutcome {
        guard let sub = tokens.first else { throw UsageError(message: Self.usage) }
        let rest = Array(tokens.dropFirst())
        switch sub {
        case "novo":
            let args = try CommandLineArguments(rest, valueOptions: ["--intencao", "--projeto"])
            try args.requirePositionals(1, usage: "friday assunto novo \"<título>\" [--intencao \"...\"] [--projeto <id>]")
            let project = try args.value("--projeto").map { text -> Int64 in
                guard let id = Int64(text) else { throw UsageError(message: "\"\(text)\" não é um id de projeto.") }
                return id
            }
            let saved = try repository.insert(Subject(title: args.positionals[0], projectID: project, intent: args.value("--intencao") ?? "", createdAt: now()))
            return ok("assunto \(saved.id ?? 0) criado", wrote: true)
        case "listar":
            let args = try CommandLineArguments(rest)
            try args.requirePositionals(0, usage: "friday assunto listar")
            return ok(try listing())
        case "ler":
            let args = try CommandLineArguments(rest)
            try args.requirePositionals(1, usage: "friday assunto ler <id>")
            let id = try subjectID(args.positionals[0])
            guard let subject = try repository.subject(id: id) else { throw SubjectError.subjectNotFound(id) }
            return ok(SubjectMarkdown.render(subject))
        case "intencao":
            let args = try CommandLineArguments(rest)
            try args.requirePositionals(2, usage: "friday assunto intencao <id> \"<texto>\"")
            let id = try subjectID(args.positionals[0])
            let text = args.positionals[1], date = now()
            try repository.update(id: id) { try $0.setIntent(text, at: date) }
            return ok("intenção do assunto \(id) atualizada", wrote: true)
        default:
            throw UsageError(message: "Subcomando desconhecido: assunto \(sub).\n\(Self.usage)")
        }
    }

    private func listing() throws -> String {
        let subjects = try repository.all()
        if subjects.isEmpty { return "nenhum assunto" }
        return subjects.map { subject in
            let turn = subject.turn
            let holder = turn.holder == .you ? "você" : turn.holder == .claude ? "Claude" : "parado"
            return "\(subject.id ?? 0) · \(subject.title) · vez: \(holder) (\(turn.reason))"
        }.joined(separator: "\n")
    }

    private func evidence(_ tokens: [String]) throws -> CommandOutcome {
        let usage = "friday evidencia <id> --grau medido|codigo|inferido --fonte \"...\" \"<fato>\""
        let args = try CommandLineArguments(tokens, valueOptions: ["--grau", "--fonte"])
        try args.requirePositionals(2, usage: usage)
        let grade: EvidenceGrade
        switch args.value("--grau") {
        case "medido": grade = .measured
        case "codigo": grade = .inCode
        case "inferido": grade = .inferred
        default: throw UsageError(message: "--grau precisa ser medido, codigo ou inferido.\nUso: \(usage)")
        }
        guard let source = args.value("--fonte") else { throw UsageError(message: "--fonte é obrigatória.\nUso: \(usage)") }
        let id = try subjectID(args.positionals[0])
        let fact = args.positionals[1], date = now()
        let saved = try repository.update(id: id) { try $0.addEvidence(fact: fact, source: source, grade: grade, at: date) }
        return ok("evidência \(saved.evidences.last?.id ?? 0) registrada no assunto \(id) (\(grade.label))", wrote: true)
    }

    private func question(_ tokens: [String]) throws -> CommandOutcome {
        let usage = "friday pergunta <id> \"<texto>\" [--opcao \"rótulo|consequência\"]... [--espera-voce]"
        let args = try CommandLineArguments(tokens, valueOptions: ["--opcao"], switchOptions: ["--espera-voce"])
        try args.requirePositionals(2, usage: usage)
        let options = try args.values("--opcao").map { raw -> QuestionOption in
            let parts = raw.split(separator: "|", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { throw UsageError(message: "--opcao precisa ser \"rótulo|consequência\" (recebi \"\(raw)\").") }
            return QuestionOption(label: parts[0], consequence: parts[1])
        }
        let id = try subjectID(args.positionals[0])
        let text = args.positionals[1], date = now(), waits = args.switches.contains("--espera-voce")
        let saved = try repository.update(id: id) { _ = try $0.addQuestion(text: text, options: options, waitsForYou: waits, at: date) }
        return ok("pergunta \(saved.questions.last?.id ?? 0) registrada no assunto \(id)\(waits ? " (espera você)" : "")", wrote: true)
    }

    private func alternative(_ tokens: [String]) throws -> CommandOutcome {
        let usage = "friday alternativa <id> \"<nome>\" --ganho \"...\" --risco \"...\" --esforco \"...\" --reversivel \"...\""
        let args = try CommandLineArguments(tokens, valueOptions: ["--ganho", "--risco", "--esforco", "--reversivel"])
        try args.requirePositionals(2, usage: usage)
        guard let gain = args.value("--ganho"), let risk = args.value("--risco"), let effort = args.value("--esforco"), let rev = args.value("--reversivel") else {
            throw UsageError(message: "--ganho, --risco, --esforco e --reversivel são obrigatórios.\nUso: \(usage)")
        }
        let id = try subjectID(args.positionals[0])
        let name = args.positionals[1], date = now()
        let saved = try repository.update(id: id) { _ = try $0.addAlternative(name: name, gain: gain, risk: risk, effort: effort, reversibility: rev, at: date) }
        return ok("alternativa \(saved.alternatives.last?.id ?? 0) registrada no assunto \(id)", wrote: true)
    }

    private func decision(_ tokens: [String]) throws -> CommandOutcome {
        let usage = "friday decisao <id> \"<decisão>\" --porque \"...\" [--mudaria-se \"...\"] [--responde <n>]"
        let args = try CommandLineArguments(tokens, valueOptions: ["--porque", "--mudaria-se", "--responde"])
        try args.requirePositionals(2, usage: usage)
        guard let reason = args.value("--porque") else { throw UsageError(message: "--porque é obrigatório.\nUso: \(usage)") }
        let answering = try args.value("--responde").map { text -> Int in
            guard let n = Int(text) else { throw UsageError(message: "--responde espera o número da pergunta (recebi \"\(text)\").") }
            return n
        }
        let id = try subjectID(args.positionals[0])
        let text = args.positionals[1], changeIf = args.value("--mudaria-se"), date = now()
        let saved = try repository.update(id: id) { _ = try $0.recordDecision(text: text, reason: reason, changeIf: changeIf, answering: answering, at: date) }
        return ok("decisão \(saved.decisions.last?.id ?? 0) registrada no assunto \(id)", wrote: true)
    }

    private func front(_ tokens: [String]) throws -> CommandOutcome {
        let usage = "friday frente <id> \"<nome>\" [--criterio \"...\"] [--estado rodando|esperando-voce|concluida] [--passo \"...\"]... [--feitos <n>]"
        let args = try CommandLineArguments(tokens, valueOptions: ["--criterio", "--estado", "--passo", "--feitos"])
        try args.requirePositionals(2, usage: usage)
        let state = try args.value("--estado").map { text -> FrontState in
            switch text {
            case "rodando": return .running
            case "esperando-voce": return .waitingForYou
            case "concluida": return .done
            default: throw UsageError(message: "--estado precisa ser rodando, esperando-voce ou concluida.")
            }
        }
        let done = try args.value("--feitos").map { text -> Int in
            guard let n = Int(text), n >= 0 else { throw UsageError(message: "--feitos espera um número (recebi \"\(text)\").") }
            return n
        }
        let id = try subjectID(args.positionals[0])
        let name = args.positionals[1], criterion = args.value("--criterio"), steps = args.options["--passo"], date = now()
        let saved = try repository.update(id: id) { _ = try $0.upsertFront(name: name, criterion: criterion, state: state, steps: steps, doneSteps: done, at: date) }
        let front = saved.fronts.first { $0.name.compare(name.trimmingCharacters(in: .whitespaces), options: .caseInsensitive) == .orderedSame }
        return ok("frente \"\(front?.name ?? name)\" no assunto \(id): \(SubjectMarkdown.stateLabel(front?.state ?? .running))", wrote: true)
    }
}

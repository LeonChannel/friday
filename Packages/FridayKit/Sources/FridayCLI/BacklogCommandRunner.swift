// Resumo: Executa `friday bug` e `friday item` (novo, listar, ler, mover, editar, pai, externo, apagar, hook) contra o backlog do projeto da pasta atual.
// Tags: backlog, persistencia

import FridayDomain
import Foundation

/// Interpreta `friday bug` e `friday item`. O projeto é o do Friday que contém a pasta atual.
public struct BacklogCommandRunner: Sendable {
    private let repository: any BacklogRepository
    private let projects: @Sendable () throws -> [Project]
    private let currentDirectory: String
    private let environment: [String: String]
    private let now: @Sendable () -> Date

    public init(
        repository: any BacklogRepository, projects: @escaping @Sendable () throws -> [Project], currentDirectory: String,
        environment: [String: String], now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.repository = repository
        self.projects = projects
        self.currentDirectory = currentDirectory
        self.environment = environment
        self.now = now
    }

    static let usage = """
        Uso (o projeto é o da pasta atual):
          friday bug "<título>" [--onde "arquivo:linha"] [--grau medido|codigo|inferido] [--detalhe "..."] [--prioridade baixa|media|alta|critica] [--pai <código>]
          friday item novo epico|historia|task|subtask|bug "<título>" [as mesmas opções do bug]
          friday item listar [--tipo <tipo>] [--estado novo|a-fazer|fazendo|revisao|feito|descartado] [--fechados]
          friday item ler <código>
          friday item mover <código> novo|a-fazer|fazendo|revisao|feito|descartado
          friday item editar <código> [--titulo "..."] [--detalhe "..."] [--onde "..."] [--grau ...] [--prioridade ...]
          friday item pai <código> <código do pai|nenhum>
          friday item externo <código> "<card ou link no Jira/Azure>"|nenhum
          friday item apagar <código>
          friday item hook        # usado pelo SessionStart do plugin; lê o JSON do evento na entrada
        """

    private static let itemOptions: Set<String> = ["--onde", "--grau", "--detalhe", "--prioridade", "--pai", "--autor"]

    /// Roda `bug ...` ou `item ...`. Erro de uso ou de validação vira saída de erro e código diferente de zero.
    /// `input` só é lido por `item hook` (o JSON do evento chega na entrada padrão).
    public func run(_ arguments: [String], input: () -> Data = { Data() }) -> CommandOutcome {
        if arguments.starts(with: ["item", "hook"]) { return hook(input()) }
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
        case "bug":
            if rest.first.map({ ["ajuda", "--ajuda", "-h", "--help"].contains($0) }) == true { return ok(Self.usage) }
            return try create(kind: .bug, rest, deduplicate: true)
        case "item":
            guard let sub = rest.first else { throw UsageError(message: Self.usage) }
            let tokens = Array(rest.dropFirst())
            switch sub {
            case "novo":
                guard let kindName = tokens.first, let kind = BacklogKind(cliName: kindName) else {
                    throw UsageError(message: "Tipo precisa ser epico, historia, task, subtask ou bug.\n\(Self.usage)")
                }
                return try create(kind: kind, Array(tokens.dropFirst()), deduplicate: kind == .bug)
            case "listar": return try list(tokens)
            case "ler": return try read(tokens)
            case "mover": return try move(tokens)
            case "editar": return try edit(tokens)
            case "pai": return try parent(tokens)
            case "externo": return try external(tokens)
            case "apagar": return try delete(tokens)
            case "ajuda", "--ajuda", "-h", "--help": return ok(Self.usage)
            default: throw UsageError(message: "Subcomando desconhecido: item \(sub).\n\(Self.usage)")
            }
        default:
            throw UsageError(message: Self.usage)
        }
    }

    // MARK: Projeto e item

    private func project() throws -> (project: Project, id: Int64, key: String) {
        guard let project = Project.containing(currentDirectory, in: try projects()), let id = project.id else {
            throw UsageError(message: "Esta pasta não está em nenhum projeto do Friday. Rode o comando dentro de um projeto aberto no app.")
        }
        return (project, id, BacklogCode.key(forProjectName: project.name))
    }

    private func item(_ code: String, projectID: Int64) throws -> BacklogItem {
        guard let number = BacklogCode.number(from: code) else { throw UsageError(message: "\"\(code)\" não é um código de item (ex.: FRI-12).") }
        guard let item = try repository.item(projectID: projectID, number: number) else { throw BacklogError.itemNotFound(code) }
        return item
    }

    /// O Claude Code marca o próprio processo com `CLAUDECODE=1`; fora dele, quem escreve é o dev.
    private var defaultAuthor: BacklogAuthor {
        environment["CLAUDECODE"] == "1" ? .claude : .you
    }

    private func grade(_ text: String?) throws -> EvidenceGrade? {
        guard let text else { return nil }
        switch text {
        case "medido": return .measured
        case "codigo", "código": return .inCode
        case "inferido": return .inferred
        default: throw UsageError(message: "--grau precisa ser medido, codigo ou inferido.")
        }
    }

    private func priority(_ text: String?) throws -> BacklogPriority? {
        guard let text else { return nil }
        guard let priority = BacklogPriority(cliName: text) else { throw UsageError(message: "--prioridade precisa ser baixa, media, alta ou critica.") }
        return priority
    }

    // MARK: Hook

    /// Lembrete do início da sessão: como anotar bug sem parar e quantos esperam triagem. Fora de projeto ou com erro, não diz nada.
    private func hook(_ data: Data) -> CommandOutcome {
        let silent = CommandOutcome(exitCode: 0, output: "", errorOutput: "", wrote: false)
        let event = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        guard (event?["hook_event_name"] as? String) == "SessionStart" else { return silent }
        let cwd = (event?["cwd"] as? String) ?? currentDirectory
        guard let project = Project.containing(cwd, in: (try? projects()) ?? []), let projectID = project.id else { return silent }
        let key = BacklogCode.key(forProjectName: project.name)
        let pending = ((try? repository.all(projectID: projectID)) ?? []).count { $0.kind == .bug && $0.status == .new }
        var context = """
            Backlog do Friday (projeto \(project.name), códigos \(key)-n). Achou bug, falha ou risco fora da tarefa atual? \
            Não pare nem corrija sem pedido: anote e siga, sem comentar no chat. \
            `friday bug "<título>" --onde "arquivo:linha" --grau codigo|medido|inferido --detalhe "como reproduzir e o efeito"`. \
            Detalhes na skill friday-backlog.
            """
        if pending > 0 { context += " \(pending) bug(s) esperando triagem do dev." }
        let payload: [String: Any] = ["hookSpecificOutput": ["hookEventName": "SessionStart", "additionalContext": context]]
        guard let json = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]) else { return silent }
        return CommandOutcome(exitCode: 0, output: String(decoding: json, as: UTF8.self), errorOutput: "", wrote: false)
    }

    // MARK: Comandos

    private func create(kind: BacklogKind, _ tokens: [String], deduplicate: Bool) throws -> CommandOutcome {
        let args = try CommandLineArguments(tokens, valueOptions: Self.itemOptions)
        try args.requirePositionals(1, usage: kind == .bug ? "friday bug \"<título>\" [opções]" : "friday item novo \(kind.cliName) \"<título>\" [opções]")
        let (_, projectID, key) = try project()
        let title = args.positionals[0]
        if deduplicate, let existing = BacklogProjection.openDuplicate(of: title, kind: kind, in: try repository.all(projectID: projectID)) {
            return ok("\(BacklogCode.format(key: key, number: existing.number)) já está registrado com esse título (\(existing.status.label)); nada gravado")
        }
        let author: BacklogAuthor
        switch args.value("--autor") {
        case nil: author = defaultAuthor
        case "claude": author = .claude
        case "voce", "você": author = .you
        default: throw UsageError(message: "--autor precisa ser claude ou voce.")
        }
        let parentID = try args.value("--pai").map { try item($0, projectID: projectID).id }
        let saved = try repository.insert(BacklogItem(
            projectID: projectID, kind: kind, title: title, detail: args.value("--detalhe") ?? "", location: args.value("--onde"),
            grade: try grade(args.value("--grau")), priority: try priority(args.value("--prioridade")) ?? .medium,
            author: author, parentID: parentID ?? nil, createdAt: now()
        ))
        return ok("\(BacklogCode.format(key: key, number: saved.number)) criado (\(kind.label), \(saved.status.label))", wrote: true)
    }

    private func list(_ tokens: [String]) throws -> CommandOutcome {
        let args = try CommandLineArguments(tokens, valueOptions: ["--tipo", "--estado"], switchOptions: ["--fechados"])
        try args.requirePositionals(0, usage: "friday item listar [--tipo <tipo>] [--estado <estado>] [--fechados]")
        let kind = try args.value("--tipo").map { text -> BacklogKind in
            guard let kind = BacklogKind(cliName: text) else { throw UsageError(message: "--tipo precisa ser epico, historia, task, subtask ou bug.") }
            return kind
        }
        let status = try args.value("--estado").map { text -> BacklogStatus in
            guard let status = BacklogStatus(cliName: text) else { throw UsageError(message: "--estado desconhecido: \(text).") }
            return status
        }
        let (_, projectID, key) = try project()
        let items = try repository.all(projectID: projectID).filter { item in
            (kind == nil || item.kind == kind) && (status.map { item.status == $0 } ?? (args.switches.contains("--fechados") || !item.status.isClosed))
        }
        if items.isEmpty { return ok("nenhum item") }
        return ok(items.map { BacklogMarkdown.line($0, key: key) }.joined(separator: "\n"))
    }

    private func read(_ tokens: [String]) throws -> CommandOutcome {
        let args = try CommandLineArguments(tokens)
        try args.requirePositionals(1, usage: "friday item ler <código>")
        let (_, projectID, key) = try project()
        let target = try item(args.positionals[0], projectID: projectID)
        let all = try repository.all(projectID: projectID)
        let parent = target.parentID.flatMap { id in all.first { $0.id == id } }
        let children = all.filter { $0.parentID != nil && $0.parentID == target.id }
        return ok(BacklogMarkdown.render(target, key: key, parent: parent, children: children).trimmingCharacters(in: .newlines))
    }

    private func move(_ tokens: [String]) throws -> CommandOutcome {
        let args = try CommandLineArguments(tokens)
        try args.requirePositionals(2, usage: "friday item mover <código> novo|a-fazer|fazendo|revisao|feito|descartado")
        guard let status = BacklogStatus(cliName: args.positionals[1]) else {
            throw UsageError(message: "Estado precisa ser novo, a-fazer, fazendo, revisao, feito ou descartado.")
        }
        let (_, projectID, key) = try project()
        let target = try item(args.positionals[0], projectID: projectID)
        let date = now()
        try repository.update(id: target.id ?? 0) { $0.move(to: status, at: date) }
        return ok("\(BacklogCode.format(key: key, number: target.number)) → \(status.label)", wrote: true)
    }

    private func edit(_ tokens: [String]) throws -> CommandOutcome {
        let args = try CommandLineArguments(tokens, valueOptions: ["--titulo", "--detalhe", "--onde", "--grau", "--prioridade"])
        try args.requirePositionals(1, usage: "friday item editar <código> [--titulo \"...\"] [--detalhe \"...\"] [--onde \"...\"] [--grau ...] [--prioridade ...]")
        guard !args.options.isEmpty else { throw UsageError(message: "Diga o que mudar: --titulo, --detalhe, --onde, --grau ou --prioridade.") }
        let (_, projectID, key) = try project()
        let target = try item(args.positionals[0], projectID: projectID)
        let title = args.value("--titulo"), detail = args.value("--detalhe"), location = args.value("--onde")
        let grade = try grade(args.value("--grau")), priority = try priority(args.value("--prioridade")), date = now()
        try repository.update(id: target.id ?? 0) { item in
            if let title { try item.setTitle(title, at: date) }
            if let detail { try item.setDetail(detail, at: date) }
            if let location { try item.setLocation(location, at: date) }
            if let grade { item.grade = grade }
            if let priority { item.priority = priority }
            item.updatedAt = date
        }
        return ok("\(BacklogCode.format(key: key, number: target.number)) atualizado", wrote: true)
    }

    private func parent(_ tokens: [String]) throws -> CommandOutcome {
        let args = try CommandLineArguments(tokens)
        try args.requirePositionals(2, usage: "friday item pai <código> <código do pai|nenhum>")
        let (_, projectID, key) = try project()
        let target = try item(args.positionals[0], projectID: projectID)
        let parent = args.positionals[1] == "nenhum" ? nil : try item(args.positionals[1], projectID: projectID)
        let date = now()
        try repository.update(id: target.id ?? 0) { try $0.setParent(parent, at: date) }
        let code = BacklogCode.format(key: key, number: target.number)
        return ok(parent.map { "\(code) agora está dentro de \(BacklogCode.format(key: key, number: $0.number))" } ?? "\(code) agora está na raiz", wrote: true)
    }

    private func external(_ tokens: [String]) throws -> CommandOutcome {
        let args = try CommandLineArguments(tokens)
        try args.requirePositionals(2, usage: "friday item externo <código> \"<card ou link>\"|nenhum")
        let (_, projectID, key) = try project()
        let target = try item(args.positionals[0], projectID: projectID)
        let reference = args.positionals[1] == "nenhum" ? nil : args.positionals[1]
        let date = now()
        try repository.update(id: target.id ?? 0) { try $0.setExternalRef(reference, at: date) }
        let code = BacklogCode.format(key: key, number: target.number)
        return ok(reference.map { "\(code) levado para \($0)" } ?? "\(code) sem referência externa", wrote: true)
    }

    private func delete(_ tokens: [String]) throws -> CommandOutcome {
        let args = try CommandLineArguments(tokens)
        try args.requirePositionals(1, usage: "friday item apagar <código>")
        let (_, projectID, key) = try project()
        let target = try item(args.positionals[0], projectID: projectID)
        do {
            try repository.delete(id: target.id ?? 0)
        } catch BacklogError.hasChildren(_, let count) {
            throw BacklogError.hasChildren(BacklogCode.format(key: key, number: target.number), count: count)
        }
        return ok("\(BacklogCode.format(key: key, number: target.number)) apagado", wrote: true)
    }
}

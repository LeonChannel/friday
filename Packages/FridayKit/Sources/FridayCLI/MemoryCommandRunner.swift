// Resumo: Executa `friday memoria` (hook, contexto, listar, ler, nota, área, promover) contra o vault, e responde aos hooks do Claude com o contexto da memória.
// Tags: memoria, agentes

import FridayDomain
import FridayInfrastructure
import Foundation

/// Comandos da memória. O hook nunca falha: qualquer erro vira silêncio e código 0, para não atrapalhar o agente.
public struct MemoryCommandRunner: Sendable {
    private let vault: (any MemoryVaultStoring)?
    private let projects: @Sendable () throws -> [Project]
    private let subjects: any SubjectRepository
    private let environment: [String: String]
    private let currentDirectory: String
    private let ledgerDirectory: URL
    private let head: @Sendable (String) -> String?
    private let now: @Sendable () -> Date

    /// `vault` nil quando o dev ainda não escolheu a pasta; `ledgerDirectory` guarda o que já foi entregue em cada sessão.
    public init(
        vault: (any MemoryVaultStoring)?,
        projects: @escaping @Sendable () throws -> [Project],
        subjects: any SubjectRepository,
        environment: [String: String],
        currentDirectory: String,
        ledgerDirectory: URL,
        head: @escaping @Sendable (String) -> String? = GitHeadReader.head(ofRepositoryAt:),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.vault = vault
        self.projects = projects
        self.subjects = subjects
        self.environment = environment
        self.currentDirectory = currentDirectory
        self.ledgerDirectory = ledgerDirectory
        self.head = head
        self.now = now
    }

    static let usage = """
        Uso:
          friday memoria contexto [--assunto <id>]
          friday memoria listar [--camada abstracao|processual|projeto]
          friday memoria ler "<caminho relativo ao vault>"
          friday memoria nota "<título>" --camada <camada> --tipo <tipo> --resumo "..." [--ancora <caminho>]... [--corpo "..."] [--sempre]
          friday memoria area <assunto> [--estado "..."] [--fechar]
          friday memoria promover <assunto> --decisao <n>
          friday memoria hook   (usado pelos hooks; lê o evento na entrada)
        """

    /// Roda um subcomando de `friday memoria`. `input` só é lido pelo `hook`.
    public func run(_ arguments: [String], input: () -> Data = { Data() }) -> CommandOutcome {
        if arguments.first == "hook" { return hook(input()) }
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
        case "contexto": return try context(rest)
        case "listar": return try list(rest)
        case "ler": return try read(rest)
        case "nota": return try note(rest)
        case "area": return try workArea(rest)
        case "promover": return try promote(rest)
        case "ajuda", "--ajuda", "-h", "--help": return ok(Self.usage)
        default: throw UsageError(message: "Comando desconhecido: memoria \(command).\n\(Self.usage)")
        }
    }

    private func requireVault() throws -> any MemoryVaultStoring {
        guard let vault else { throw UsageError(message: "Nenhum vault escolhido. Escolha a pasta em Friday → Ajustes → Memória.") }
        return vault
    }

    /// Projeto do Friday que contém o caminho; o mais específico ganha.
    private func project(containing path: String) -> Project? {
        Project.containing(path, in: (try? projects()) ?? [])
    }

    private func subjectID(_ text: String) throws -> Int64 {
        guard let id = Int64(text) else { throw UsageError(message: "\"\(text)\" não é um id de assunto.") }
        return id
    }

    private func today() -> String {
        now().formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day())
    }

    // MARK: Contexto

    /// Contexto de início para o projeto da pasta e, se houver, a área de trabalho do assunto.
    private func briefing(vault: any MemoryVaultStoring, directory: String, subject subjectID: Int64?) throws -> MemoryBriefing {
        let project = project(containing: directory)
        let (snapshot, _) = try vault.snapshot(projectName: project?.name)
        var workAreaText: String?
        if let subjectID, let subject = try subjects.subject(id: subjectID) {
            let projectName = try subject.projectID.flatMap { id in try projects().first { $0.id == id } }?.name ?? project?.name
            let projectPath = try subject.projectID.flatMap { id in try projects().first { $0.id == id } }?.path ?? project?.path
            if let projectName, let state = try vault.workArea(projectName: projectName, subject: subjectID) {
                workAreaText = state.resumeText(subject: subject, currentHead: projectPath.flatMap(head))
            }
        }
        return MemoryBriefing.sessionStart(snapshot, workArea: workAreaText)
    }

    private func context(_ tokens: [String]) throws -> CommandOutcome {
        let args = try CommandLineArguments(tokens, valueOptions: ["--assunto"])
        try args.requirePositionals(0, usage: "friday memoria contexto [--assunto <id>]")
        let subject = try args.value("--assunto").map(subjectID) ?? environment["FRIDAY_ASSUNTO"].flatMap { Int64($0) }
        let result = try briefing(vault: try requireVault(), directory: currentDirectory, subject: subject)
        let omitted = result.omitted > 0 ? ", \(result.omitted) fora do teto" : ""
        return ok(result.text + "\n\n— \(result.included) nota(s), \(result.characters) caracteres (~\(result.estimatedTokens) tokens)\(omitted)")
    }

    // MARK: Leitura

    private func list(_ tokens: [String]) throws -> CommandOutcome {
        let args = try CommandLineArguments(tokens, valueOptions: ["--camada"])
        try args.requirePositionals(0, usage: "friday memoria listar [--camada abstracao|processual|projeto]")
        let vault = try requireVault()
        let layers = try args.value("--camada").map { [try layer($0)] } ?? MemoryLayer.allCases
        let projectName = project(containing: currentDirectory)?.name
        var lines: [String] = []
        var issues: [MemoryIssue] = []
        for layer in layers {
            let load = try vault.load(layer, projectName: projectName)
            issues += load.issues
            lines += load.notes.map { "\(layer.rawValue) · \($0.kind.rawValue) · \($0.title) — \($0.path)" }
        }
        lines += issues.map { "com problema · \($0.path): \($0.message)" }
        return ok(lines.isEmpty ? "nenhuma nota" : lines.joined(separator: "\n"))
    }

    private func read(_ tokens: [String]) throws -> CommandOutcome {
        let args = try CommandLineArguments(tokens)
        try args.requirePositionals(1, usage: "friday memoria ler \"<caminho relativo ao vault>\"")
        guard let text = try requireVault().read(args.positionals[0]) else {
            throw UsageError(message: "Nota não encontrada: \(args.positionals[0]). Veja `friday memoria listar`.")
        }
        return ok(text.trimmingCharacters(in: .newlines))
    }

    private func layer(_ text: String) throws -> MemoryLayer {
        guard let layer = MemoryLayer(rawValue: text) else { throw UsageError(message: "--camada precisa ser abstracao, processual ou projeto.") }
        return layer
    }

    // MARK: Escrita

    private func note(_ tokens: [String]) throws -> CommandOutcome {
        let usage = "friday memoria nota \"<título>\" --camada <camada> --tipo <tipo> --resumo \"...\" [--ancora <caminho>]... [--corpo \"...\"] [--sempre]"
        let args = try CommandLineArguments(tokens, valueOptions: ["--camada", "--tipo", "--resumo", "--ancora", "--corpo"], switchOptions: ["--sempre"])
        try args.requirePositionals(1, usage: usage)
        guard let layerText = args.value("--camada"), let kindText = args.value("--tipo"), let summary = args.value("--resumo") else {
            throw UsageError(message: "--camada, --tipo e --resumo são obrigatórios.\nUso: \(usage)")
        }
        let layer = try layer(layerText)
        guard let kind = MemoryNoteKind(rawValue: kindText), kind.layer == layer else {
            throw MemoryNoteError.unknownKind(kindText, layer: layer)
        }
        let vault = try requireVault()
        var projectName: String?
        if layer == .project {
            guard let project = project(containing: currentDirectory) else {
                throw UsageError(message: "Esta pasta não é de nenhum projeto do Friday; nota de projeto precisa de um.")
            }
            projectName = project.name
        }
        let title = args.positionals[0]
        let path = kind == .projectHub ? VaultPaths.projectHub(projectName ?? "") : VaultPaths.newNote(title: title, kind: kind, projectName: projectName)
        let existing = try vault.read(path).flatMap { try? MemoryNote.parse(markdown: $0, path: path, layer: layer) }
        let anchors = args.values("--ancora")
        let body = args.value("--corpo").map { "# \(title)\n\n\($0)" } ?? existing?.body ?? "# \(title)\n"
        let note = try MemoryNote(
            path: path, layer: layer, kind: kind, title: title, summary: summary,
            anchors: anchors.isEmpty ? existing?.anchors ?? [] : anchors,
            always: args.switches.contains("--sempre") ? true : existing?.always,
            verifiedAt: anchors.isEmpty ? existing?.verifiedAt : today(), body: body
        )
        try vault.save(note)
        return ok("nota \(existing == nil ? "criada" : "atualizada"): \(path)", wrote: true)
    }

    /// Projeto do assunto: o ligado a ele ou, sem ligação, o da pasta atual.
    private func projectOf(_ subject: Subject) throws -> Project {
        if let id = subject.projectID, let project = try projects().first(where: { $0.id == id }) { return project }
        if let project = project(containing: currentDirectory) { return project }
        throw UsageError(message: "O assunto \(subject.id ?? 0) não está ligado a um projeto e esta pasta não é de nenhum projeto do Friday.")
    }

    private func loadSubject(_ text: String) throws -> Subject {
        let id = try subjectID(text)
        guard let subject = try subjects.subject(id: id) else { throw SubjectError.subjectNotFound(id) }
        return subject
    }

    private func workArea(_ tokens: [String]) throws -> CommandOutcome {
        let usage = "friday memoria area <assunto> [--estado \"...\"] [--fechar]"
        let args = try CommandLineArguments(tokens, valueOptions: ["--estado"], switchOptions: ["--fechar"])
        try args.requirePositionals(1, usage: usage)
        let vault = try requireVault()
        let subject = try loadSubject(args.positionals[0])
        let id = subject.id ?? 0
        let project = try projectOf(subject)
        if args.switches.contains("--fechar") {
            try vault.closeWorkArea(projectName: project.name, subject: id)
            return ok("área de trabalho do assunto \(id) fechada", wrote: true)
        }
        if let text = args.value("--estado") {
            let state = try WorkAreaState(subjectID: id, text: text, updatedAt: now(), head: head(project.path))
            try vault.saveWorkArea(state, projectName: project.name)
            return ok("estado do assunto \(id) gravado", wrote: true)
        }
        guard let state = try vault.workArea(projectName: project.name, subject: id) else {
            return ok("assunto \(id) sem área de trabalho")
        }
        return ok(state.resumeText(subject: subject, currentHead: head(project.path)))
    }

    private func promote(_ tokens: [String]) throws -> CommandOutcome {
        let args = try CommandLineArguments(tokens, valueOptions: ["--decisao"])
        try args.requirePositionals(1, usage: "friday memoria promover <assunto> --decisao <n>")
        let vault = try requireVault()
        let subject = try loadSubject(args.positionals[0])
        guard let raw = args.value("--decisao"), let number = Int(raw) else { throw UsageError(message: "--decisao espera o número da decisão.") }
        guard let decision = subject.decisions.first(where: { $0.id == number }) else {
            throw UsageError(message: "O assunto \(subject.id ?? 0) não tem a decisão \(number).")
        }
        let project = try projectOf(subject)
        let note = try MemoryNote.promoting(decision, of: subject, projectName: project.name, today: today())
        try vault.save(note)
        return ok("decisão \(number) promovida: \(note.path)", wrote: true)
    }

    // MARK: Hook

    /// Responde a um evento de hook do Claude. Sem vault, sem projeto ou com erro, não diz nada.
    private func hook(_ data: Data) -> CommandOutcome {
        let silent = CommandOutcome(exitCode: 0, output: "", errorOutput: "", wrote: false)
        guard let vault,
              let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = event["hook_event_name"] as? String else { return silent }
        let session = (event["session_id"] as? String).map(Self.safeFileName) ?? "sem-sessao"
        let cwd = (event["cwd"] as? String) ?? currentDirectory
        let context: String?
        switch name {
        case "SessionStart":
            resetLedger(session: session)
            let subject = environment["FRIDAY_ASSUNTO"].flatMap { Int64($0) }
            context = try? briefing(vault: vault, directory: cwd, subject: subject).text
        case "PreToolUse":
            let input = event["tool_input"] as? [String: Any]
            guard let file = (input?["file_path"] as? String) ?? (input?["notebook_path"] as? String) else { return silent }
            context = anchoredDelivery(vault: vault, file: file, cwd: cwd, session: session)
        default:
            return silent
        }
        guard let context, !context.isEmpty else { return silent }
        let payload: [String: Any] = ["hookSpecificOutput": ["hookEventName": name, "additionalContext": context]]
        guard let json = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]) else { return silent }
        return CommandOutcome(exitCode: 0, output: String(decoding: json, as: UTF8.self), errorOutput: "", wrote: false)
    }

    private func anchoredDelivery(vault: any MemoryVaultStoring, file: String, cwd: String, session: String) -> String? {
        let absolute = file.hasPrefix("/") ? file : URL(fileURLWithPath: cwd).appendingPathComponent(file).path
        let path = URL(fileURLWithPath: absolute).standardizedFileURL.path
        guard let project = project(containing: path), path != project.path,
              let notes = try? vault.load(.project, projectName: project.name).notes else { return nil }
        let relative = String(path.dropFirst(project.path.count + (project.path.hasSuffix("/") ? 0 : 1)))
        var delivered = ledger(session: session)
        let fresh = MemoryBriefing.anchored(notes.filter { !delivered.contains($0.path) }, toFile: relative)
        guard !fresh.isEmpty else { return nil }
        delivered.formUnion(fresh.map(\.path))
        saveLedger(delivered, session: session)
        return MemoryBriefing.fileDelivery(fresh, file: relative)
    }

    // MARK: Registro do que já foi entregue

    private static func safeFileName(_ text: String) -> String {
        String(text.map { $0.isLetter || $0.isNumber || $0 == "-" ? $0 : "_" }.prefix(80))
    }

    private func ledgerURL(_ session: String) -> URL {
        ledgerDirectory.appendingPathComponent("\(session).json")
    }

    private func ledger(session: String) -> Set<String> {
        guard let data = try? Data(contentsOf: ledgerURL(session)),
              let paths = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return Set(paths)
    }

    private func saveLedger(_ paths: Set<String>, session: String) {
        try? FileManager.default.createDirectory(at: ledgerDirectory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        if let data = try? JSONEncoder().encode(paths.sorted()) { try? data.write(to: ledgerURL(session), options: .atomic) }
    }

    private func resetLedger(session: String) {
        try? FileManager.default.removeItem(at: ledgerURL(session))
    }
}

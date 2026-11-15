// Resumo: Item do backlog do projeto (épico, história, task, subtask ou bug) com estado, prioridade, autor e a regra de quem pode ser pai de quem.
// Tags: backlog

import Foundation

/// Tipo do item, na hierarquia épico → história → task → subtask; bug fica ao lado de história e task.
public enum BacklogKind: String, Codable, Sendable, CaseIterable {
    case epic
    case story
    case task
    case subtask
    case bug

    /// Nome mostrado ao usuário.
    public var label: String {
        switch self {
        case .epic: "Épico"
        case .story: "História"
        case .task: "Task"
        case .subtask: "Subtask"
        case .bug: "Bug"
        }
    }

    /// Palavra usada na CLI (`friday item novo historia ...`).
    public var cliName: String {
        switch self {
        case .epic: "epico"
        case .story: "historia"
        case .task: "task"
        case .subtask: "subtask"
        case .bug: "bug"
        }
    }

    /// Lê a palavra da CLI, aceitando com ou sem acento.
    public init?(cliName: String) {
        let folded = cliName.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        guard let kind = Self.allCases.first(where: { $0.cliName == folded }) else { return nil }
        self = kind
    }

    /// Tipos que podem ser pai deste. Vazio: o item fica sempre na raiz.
    public var allowedParents: Set<BacklogKind> {
        switch self {
        case .epic: []
        case .story: [.epic]
        case .task, .bug: [.epic, .story]
        case .subtask: [.story, .task, .bug]
        }
    }

    /// Subtask só existe dentro de outro item.
    public var requiresParent: Bool { self == .subtask }
}

/// Em que ponto do fluxo o item está. A ordem dos casos é a ordem das colunas do quadro.
public enum BacklogStatus: String, Codable, Sendable, CaseIterable {
    /// Acabou de chegar (o Claude registrou) e ainda não foi olhado pelo dev.
    case new
    case todo
    case doing
    case review
    case done
    /// Não é bug, é duplicado ou não vale o esforço. Sai do quadro sem ser apagado.
    case discarded

    /// Nome mostrado ao usuário.
    public var label: String {
        switch self {
        case .new: "Novo"
        case .todo: "A fazer"
        case .doing: "Fazendo"
        case .review: "Revisão"
        case .done: "Feito"
        case .discarded: "Descartado"
        }
    }

    /// Palavra usada na CLI (`friday item mover FRI-3 fazendo`).
    public var cliName: String {
        switch self {
        case .new: "novo"
        case .todo: "a-fazer"
        case .doing: "fazendo"
        case .review: "revisao"
        case .done: "feito"
        case .discarded: "descartado"
        }
    }

    /// Lê a palavra da CLI, aceitando com ou sem acento.
    public init?(cliName: String) {
        let folded = cliName.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        guard let status = Self.allCases.first(where: { $0.cliName == folded }) else { return nil }
        self = status
    }

    /// Item fechado: feito ou descartado.
    public var isClosed: Bool { self == .done || self == .discarded }
}

/// Urgência do item, da menor para a maior.
public enum BacklogPriority: String, Codable, Sendable, CaseIterable, Comparable {
    case low
    case medium
    case high
    case critical

    /// Nome mostrado ao usuário e usado na CLI.
    public var label: String {
        switch self {
        case .low: "baixa"
        case .medium: "média"
        case .high: "alta"
        case .critical: "crítica"
        }
    }

    /// Lê a palavra da CLI, aceitando com ou sem acento.
    public init?(cliName: String) {
        let folded = cliName.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        guard let priority = Self.allCases.first(where: { $0.label.folding(options: .diacriticInsensitive, locale: nil) == folded }) else { return nil }
        self = priority
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}

/// Quem registrou o item.
public enum BacklogAuthor: String, Codable, Sendable {
    case you
    case claude
}

/// Um item do backlog de um projeto. O código (`FRI-12`) é estável e serve para citar o item fora do Friday.
public struct BacklogItem: Equatable, Sendable, Identifiable {
    public var id: Int64?
    public var projectID: Int64
    /// Número sequencial dentro do projeto; 0 até ser gravado.
    public var number: Int
    public var kind: BacklogKind
    public private(set) var title: String
    public private(set) var detail: String
    /// Onde o problema mora (`arquivo:linha`, tela, comando), quando há.
    public private(set) var location: String?
    /// Quão certo é o que o item afirma, quando é um achado (bug).
    public var grade: EvidenceGrade?
    public var priority: BacklogPriority
    public var status: BacklogStatus
    public var author: BacklogAuthor
    public var parentID: Int64?
    /// Onde o item foi parar fora do Friday (card no Jira, item do Azure DevOps): código ou link.
    public private(set) var externalRef: String?
    public var createdAt: Date
    public var updatedAt: Date

    /// Cria o item validando os textos contra os tetos.
    public init(
        id: Int64? = nil, projectID: Int64, number: Int = 0, kind: BacklogKind, title: String, detail: String = "",
        location: String? = nil, grade: EvidenceGrade? = nil, priority: BacklogPriority = .medium, status: BacklogStatus? = nil,
        author: BacklogAuthor = .you, parentID: Int64? = nil, externalRef: String? = nil, createdAt: Date
    ) throws {
        self.id = id
        self.projectID = projectID
        self.number = number
        self.kind = kind
        self.title = try BacklogLimits.validated(title, field: "Título", limit: BacklogLimits.title)
        self.detail = try BacklogLimits.optional(detail, field: "Detalhe", limit: BacklogLimits.detail) ?? ""
        self.location = try BacklogLimits.optional(location, field: "Onde", limit: BacklogLimits.location)
        self.grade = grade
        self.priority = priority
        // O que o Claude acha cai em "Novo" para o dev triar; o que o dev cria já está decidido.
        self.status = status ?? (author == .claude ? .new : .todo)
        self.author = author
        self.parentID = parentID
        self.externalRef = try BacklogLimits.optional(externalRef, field: "Referência externa", limit: BacklogLimits.externalRef)
        self.createdAt = createdAt
        updatedAt = createdAt
    }

    /// Remonta o item do que foi gravado, sem revalidar.
    public init(
        id: Int64?, projectID: Int64, number: Int, kind: BacklogKind, title: String, detail: String, location: String?,
        grade: EvidenceGrade?, priority: BacklogPriority, status: BacklogStatus, author: BacklogAuthor, parentID: Int64?,
        externalRef: String?, createdAt: Date, updatedAt: Date
    ) {
        self.id = id
        self.projectID = projectID
        self.number = number
        self.kind = kind
        self.title = title
        self.detail = detail
        self.location = location
        self.grade = grade
        self.priority = priority
        self.status = status
        self.author = author
        self.parentID = parentID
        self.externalRef = externalRef
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Troca o título.
    public mutating func setTitle(_ text: String, at now: Date) throws {
        title = try BacklogLimits.validated(text, field: "Título", limit: BacklogLimits.title)
        updatedAt = now
    }

    /// Troca o detalhe; texto vazio apaga.
    public mutating func setDetail(_ text: String, at now: Date) throws {
        detail = try BacklogLimits.optional(text, field: "Detalhe", limit: BacklogLimits.detail) ?? ""
        updatedAt = now
    }

    /// Troca onde o problema mora; `nil` ou vazio apaga.
    public mutating func setLocation(_ text: String?, at now: Date) throws {
        location = try BacklogLimits.optional(text, field: "Onde", limit: BacklogLimits.location)
        updatedAt = now
    }

    /// Move o item no fluxo.
    public mutating func move(to status: BacklogStatus, at now: Date) {
        self.status = status
        updatedAt = now
    }

    /// Registra para onde o item foi levado fora do Friday; `nil` ou vazio desfaz.
    public mutating func setExternalRef(_ text: String?, at now: Date) throws {
        externalRef = try BacklogLimits.optional(text, field: "Referência externa", limit: BacklogLimits.externalRef)
        updatedAt = now
    }

    /// Troca o pai, conferindo a hierarquia. `parent` nil tira o item de dentro de outro.
    public mutating func setParent(_ parent: BacklogItem?, at now: Date) throws {
        try Self.checkParent(parent, forChild: self)
        parentID = parent?.id
        updatedAt = now
    }

    /// Recusa pai de outro projeto, de tipo errado, o próprio item, ou subtask sem pai.
    public static func checkParent(_ parent: BacklogItem?, forChild child: BacklogItem) throws {
        guard let parent else {
            if child.kind.requiresParent { throw BacklogError.needsParent(child.kind) }
            return
        }
        guard parent.projectID == child.projectID else { throw BacklogError.parentInOtherProject }
        guard parent.id == nil || parent.id != child.id else { throw BacklogError.invalidParent(child: child.kind, parent: parent.kind) }
        guard child.kind.allowedParents.contains(parent.kind) else { throw BacklogError.invalidParent(child: child.kind, parent: parent.kind) }
    }
}

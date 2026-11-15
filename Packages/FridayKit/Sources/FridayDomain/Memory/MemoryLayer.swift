// Resumo: As três camadas da memória (abstração, processual, projeto) e a lista fechada de tipos de nota de cada uma.
// Tags: memoria

/// Camada da memória: de quem é a regra e quando ela chega ao agente.
public enum MemoryLayer: String, CaseIterable, Sendable {
    /// Como o Claude fala e se porta, em qualquer projeto.
    case abstraction = "abstracao"
    /// Como o trabalho se organiza no Friday, em qualquer projeto.
    case process = "processual"
    /// Regras, padrões e mapa de um projeto.
    case project = "projeto"

    /// Pasta da camada na raiz do vault.
    public var folder: String {
        switch self {
        case .abstraction: "Abstracao"
        case .process: "Processual"
        case .project: "Projetos"
        }
    }

    /// Nome da camada na interface.
    public var displayName: String {
        switch self {
        case .abstraction: "Abstração"
        case .process: "Processual"
        case .project: "Projeto"
        }
    }

    /// Tipos permitidos nesta camada.
    public var kinds: [MemoryNoteKind] { MemoryNoteKind.allCases.filter { $0.layer == self } }

    /// Sem `sempre` no cabeçalho, a abstração entra inteira; as outras entram como índice.
    public var alwaysByDefault: Bool { self == .abstraction }
}

/// Tipo de uma nota. A lista é fechada: valor fora dela é erro de leitura.
public enum MemoryNoteKind: String, CaseIterable, Sendable {
    case communication = "comunicacao"
    case conduct = "conduta"
    case flow = "fluxo"
    case tool = "ferramenta"
    case projectHub = "projeto"
    case rule = "regra"
    case pattern = "padrao"
    case pitfall = "armadilha"
    case decision = "decisao"
    case technology = "tecnologia"
    case repository = "repo"
    case map = "mapa"

    /// Camada a que o tipo pertence.
    public var layer: MemoryLayer {
        switch self {
        case .communication, .conduct: .abstraction
        case .flow, .tool: .process
        case .projectHub, .rule, .pattern, .pitfall, .decision, .technology, .repository, .map: .project
        }
    }

    /// Subpasta onde uma nota nova desse tipo é gravada; `nil` grava na raiz da camada (ou do projeto).
    public var defaultFolder: String? {
        switch self {
        case .rule: "Regras"
        case .pattern: "Padroes"
        case .pitfall: "Armadilhas"
        case .decision: "Decisoes"
        case .technology: "Tecnologias"
        case .repository: "Repos"
        case .communication, .conduct, .flow, .tool, .projectHub, .map: nil
        }
    }
}

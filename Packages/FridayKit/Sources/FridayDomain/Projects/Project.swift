// Resumo: O que é um projeto no Friday (pasta ou repositório git) e as regras de caminho e nome que valem em todo lugar.
// Tags: projetos

import Foundation

/// Tipo de projeto: repositório git ou pasta comum.
public enum ProjectKind: String, Codable, Sendable {
    case git
    case folder
}

/// Uma pasta que o Friday acompanha, com nome, caminho e tipo.
public struct Project: Identifiable, Hashable, Sendable {
    public var id: Int64?
    public var name: String
    public var path: String
    public var kind: ProjectKind
    public var addedAt: Date
    /// Última vez que o projeto foi aberto no Friday; ordena a seleção de projetos.
    public var lastOpenedAt: Date?

    public init(id: Int64? = nil, name: String, path: String, kind: ProjectKind, addedAt: Date, lastOpenedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.path = path
        self.kind = kind
        self.addedAt = addedAt
        self.lastOpenedAt = lastOpenedAt
    }

    /// Normaliza o caminho do mesmo jeito em todo lugar, para pegar duplicata com barra final ou `..`.
    public static func normalizedPath(_ rawPath: String) -> String {
        URL(fileURLWithPath: rawPath).standardizedFileURL.path
    }

    /// Projeto que contém o caminho; o mais específico ganha (repositório cadastrado dentro de uma pasta-projeto).
    public static func containing(_ path: String, in projects: [Project]) -> Project? {
        let path = normalizedPath(path)
        return projects
            .filter { path == $0.path || path.hasPrefix($0.path.hasSuffix("/") ? $0.path : $0.path + "/") }
            .max { $0.path.count < $1.path.count }
    }

    /// Nome inicial do projeto: o nome da última pasta do caminho.
    public static func defaultName(forPath path: String) -> String {
        (path as NSString).lastPathComponent
    }
}

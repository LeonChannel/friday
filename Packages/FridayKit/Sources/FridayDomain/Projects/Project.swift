import Foundation

public enum ProjectKind: String, Codable, Sendable {
    case git
    case folder
}

public struct Project: Identifiable, Hashable, Sendable {
    public var id: Int64?
    public var name: String
    public var path: String
    public var kind: ProjectKind
    public var addedAt: Date

    public init(id: Int64? = nil, name: String, path: String, kind: ProjectKind, addedAt: Date) {
        self.id = id
        self.name = name
        self.path = path
        self.kind = kind
        self.addedAt = addedAt
    }

    /// Normalizes a path the same way everywhere, so duplicates are caught regardless of trailing slashes or `..`.
    public static func normalizedPath(_ rawPath: String) -> String {
        URL(fileURLWithPath: rawPath).standardizedFileURL.path
    }

    public static func defaultName(forPath path: String) -> String {
        (path as NSString).lastPathComponent
    }
}

public protocol ProjectRepository: Sendable {
    /// Emits the full sorted list now and after every change.
    func observeAll() -> AsyncThrowingStream<[Project], any Error>
    func contains(path: String) throws -> Bool
    @discardableResult func insert(_ project: Project) throws -> Project
    func delete(id: Int64) throws
}

public protocol FolderInspecting: Sendable {
    /// Returns the folder kind, or `nil` when the path is not an existing directory.
    func kind(ofFolderAt path: String) -> ProjectKind?
}

// Resumo: Contratos de quem lê pastas, quem lê o status do git e quem vigia mudanças, para features e testes não dependerem do disco.
// Tags: pastas, git

/// Lê o conteúdo de uma pasta, um nível por vez.
public protocol FolderReading: Sendable {
    /// Filhos diretos: pastas primeiro, ordem alfabética, sem o que o Friday esconde.
    func children(ofFolderAt path: String) async throws -> [FileNode]
}

/// Lê o status do git de um projeto.
public protocol GitStatusReading: Sendable {
    /// `nil` quando a pasta não é um repositório git (não é erro).
    func status(forFolderAt path: String) async throws -> GitStatus?
}

/// Vigia uma pasta e entrega lotes de mudanças.
public protocol ChangeWatching: Sendable {
    /// Cada lote junta uma rajada de eventos. O fluxo termina quando o consumidor para de ouvir.
    func changes(inFolderAt path: String) async -> AsyncStream<[FileChange]>
}

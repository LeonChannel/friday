// Resumo: Repositórios git de um projeto, com a branch e o número de arquivos alterados de cada um, para a lateral.
// Tags: projetos, git, interface

import FridayDomain
import Observation

/// Um repositório do projeto com o resumo do git.
public struct RepositorySummary: Identifiable, Equatable, Sendable {
    public var repository: CodeRepository
    public var branch: String?
    public var changedFiles: Int
    public var id: String { repository.id }
}

/// Lista dos repositórios do projeto aberto. Descobre ao abrir e atualiza o git sob demanda.
@MainActor
@Observable
public final class ProjectRepositoriesModel {
    public private(set) var summaries: [RepositorySummary] = []
    public private(set) var isLoading = false

    public let projectPath: String
    private let discoverer: any RepositoryDiscovering
    private let gitReader: any GitStatusReading

    public init(projectPath: String, discoverer: any RepositoryDiscovering, gitReader: any GitStatusReading) {
        self.projectPath = projectPath
        self.discoverer = discoverer
        self.gitReader = gitReader
    }

    /// Descobre os repositórios e lê o git de cada um, um por vez.
    public func refresh() async {
        isLoading = true
        defer { isLoading = false }
        let path = projectPath
        let discoverer = discoverer
        let repositories = await Task.detached { discoverer.repositories(inProjectAt: path) }.value
        var result = repositories.map { RepositorySummary(repository: $0, branch: nil, changedFiles: 0) }
        summaries = result
        for index in result.indices {
            if let status = try? await gitReader.status(forFolderAt: result[index].repository.path) {
                result[index].branch = status.branch
                result[index].changedFiles = status.changes.count
                summaries = result
            }
        }
    }
}

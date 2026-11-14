// Resumo: Erros de cadastro de projeto, com a mensagem em português que o usuário vê.
// Tags: projetos

import Foundation

/// Motivos para recusar o cadastro de um projeto.
public enum ProjectError: LocalizedError, Equatable, Sendable {
    case notADirectory(String)
    case alreadyAdded(String)
    case alreadyExists(String)
    case invalidName(String)
    case invalidURL(String)
    case commandFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notADirectory(let path): "\(path) não é uma pasta."
        case .alreadyAdded(let path): "\(path) já está na lista."
        case .alreadyExists(let path): "Já existe algo em \(path)."
        case .invalidName(let name): "\"\(name)\" não serve como nome de pasta."
        case .invalidURL(let url): "\"\(url)\" não parece um endereço de repositório git."
        case .commandFailed(let message): message
        }
    }
}

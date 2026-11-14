// Resumo: Erros de cadastro de projeto, com a mensagem em português que o usuário vê.
// Tags: projetos

import Foundation

/// Motivos para recusar o cadastro de um projeto.
public enum ProjectError: LocalizedError, Equatable, Sendable {
    case notADirectory(String)
    case alreadyAdded(String)

    public var errorDescription: String? {
        switch self {
        case .notADirectory(let path): "\(path) não é uma pasta."
        case .alreadyAdded(let path): "\(path) já está na lista."
        }
    }
}

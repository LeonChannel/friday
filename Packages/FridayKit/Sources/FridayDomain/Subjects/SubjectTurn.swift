// Resumo: Calcula de quem é a vez no assunto (você, Claude ou parado) e o motivo em texto curto, só do estado gravado.
// Tags: assuntos

import Foundation

/// De quem é a vez.
public enum TurnHolder: String, Codable, Sendable {
    case you
    case claude
    case idle
}

/// A vez com o motivo curto que a interface mostra ("1 decisão esperando").
public struct SubjectTurn: Equatable, Sendable {
    public var holder: TurnHolder
    public var reason: String
}

extension Subject {
    /// Vez do assunto: você se algo espera o dev, Claude se há frente rodando, senão parado.
    public var turn: SubjectTurn {
        let waitingQuestions = questions.filter { $0.isOpen && $0.waitsForYou }.count
        let waitingFronts = fronts.filter { $0.state == .waitingForYou }.count
        if waitingQuestions + waitingFronts > 0 {
            var parts: [String] = []
            if waitingQuestions > 0 { parts.append(waitingQuestions == 1 ? "1 decisão esperando" : "\(waitingQuestions) decisões esperando") }
            if waitingFronts > 0 { parts.append(waitingFronts == 1 ? "1 frente esperando você" : "\(waitingFronts) frentes esperando você") }
            return SubjectTurn(holder: .you, reason: parts.joined(separator: " · "))
        }
        let running = fronts.filter { $0.state == .running }.count
        if running > 0 {
            return SubjectTurn(holder: .claude, reason: running == 1 ? "1 frente rodando" : "\(running) frentes rodando")
        }
        return SubjectTurn(holder: .idle, reason: "nada em andamento")
    }
}

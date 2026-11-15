// Resumo: Os tipos de atividade que abrem um assunto (erro, teste, tarefa, marco, dúvida), cada um com a sua jornada configurável.
// Tags: jornadas, assuntos

/// Tipo de atividade escolhido ao abrir um assunto. Cada tipo tem uma jornada que o dev configura nos Ajustes.
public enum ActivityKind: String, Codable, Sendable, CaseIterable, Identifiable {
    case error = "erro"
    case test = "teste"
    case task = "tarefa"
    case milestone = "marco"
    case question = "duvida"

    public var id: String { rawValue }

    /// Nome que aparece na interface.
    public var displayName: String {
        switch self {
        case .error: "Erro"
        case .test: "Teste"
        case .task: "Tarefa"
        case .milestone: "Marco"
        case .question: "Dúvida"
        }
    }

    /// Para que serve o tipo, em uma linha.
    public var summary: String {
        switch self {
        case .error: "Algo quebrou e precisa de causa e correção."
        case .test: "Escrever, rodar ou consertar testes."
        case .task: "Feature ou tarefa de sprint."
        case .milestone: "Resolver ou fazer o discovery de um épico."
        case .question: "Entender um trecho de código."
        }
    }

    /// O que a caixa da Mesa pergunta quando o tipo está escolhido.
    public var prompt: String {
        switch self {
        case .error: "O que quebrou?"
        case .test: "O que precisa ser testado?"
        case .task: "Qual é a tarefa?"
        case .milestone: "Qual é o épico?"
        case .question: "Qual é a dúvida?"
        }
    }
}

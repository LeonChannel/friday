// Resumo: Código legível do item (`FRI-12`): a sigla tirada do nome do projeto mais o número, e a leitura de volta de um código digitado.
// Tags: backlog

import Foundation

/// O código que o dev cita para achar ou levar um item (`FRI-12`). A sigla vem do nome do projeto; o número é o que identifica.
public enum BacklogCode {
    /// Até 4 letras do nome do projeto, em maiúsculas e sem acento; `ITEM` se não houver letra.
    public static func key(forProjectName name: String) -> String {
        let folded = name.folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US_POSIX"))
        let words = folded.split { !($0.isASCII && $0.isLetter) && !($0.isASCII && $0.isNumber) }.map(String.init)
        let letters: String
        if words.count >= 2 {
            // Várias palavras: iniciais ("Lousa de Refinamento" → LDR).
            letters = String(words.compactMap { $0.first(where: \.isLetter) }.prefix(4))
        } else {
            letters = String((words.first ?? "").filter(\.isLetter).prefix(3))
        }
        return letters.isEmpty ? "ITEM" : letters.uppercased()
    }

    /// `FRI-12`.
    public static func format(key: String, number: Int) -> String {
        "\(key)-\(number)"
    }

    /// Número de um código digitado: `FRI-12`, `fri-12`, `#12` ou `12`. A sigla não é conferida, porque o projeto vem da pasta.
    public static func number(from text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let digits = trimmed.split(separator: "-").last.map(String.init) ?? trimmed
        let clean = digits.hasPrefix("#") ? String(digits.dropFirst()) : digits
        guard let number = Int(clean), number > 0 else { return nil }
        return number
    }
}

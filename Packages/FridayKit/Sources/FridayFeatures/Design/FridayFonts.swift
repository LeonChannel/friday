// Resumo: Registra as fontes Geist e Geist Mono embarcadas no app e avisa se alguma falhar, caindo na fonte do sistema.
// Tags: visual, interface

import CoreText
import Foundation
import OSLog

/// Registro das fontes embarcadas (licença SIL OFL, em `Resources/Fonts`).
public enum FridayFonts {
    /// Resultado de um registro: quantos arquivos ficaram disponíveis e quais falharam.
    public struct Report: Sendable, Equatable {
        public let registered: Int
        public let failed: [String]
        public var isComplete: Bool { failed.isEmpty && registered > 0 }
    }

    /// Nomes PostScript usados pela tipografia.
    public enum Name {
        public static let regular = "Geist-Regular"
        public static let semibold = "Geist-SemiBold"
        public static let monoRegular = "GeistMono-Regular"
        public static let monoSemibold = "GeistMono-SemiBold"
    }

    private static let registration = performRegistration()

    /// Registra as fontes no processo, uma única vez. Seguro chamar de qualquer lugar; falha vira fonte do sistema.
    @discardableResult
    public static func register() -> Report { registration }

    private static func performRegistration() -> Report {
        let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? []
        var registered = 0
        var failed: [String] = []
        for url in urls {
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                registered += 1
            } else if let cfError = error?.takeRetainedValue(), CFErrorGetCode(cfError) == CTFontManagerError.alreadyRegistered.rawValue {
                registered += 1
            } else {
                failed.append(url.lastPathComponent)
            }
        }
        if urls.isEmpty { failed.append("Fonts") }
        if !failed.isEmpty {
            Logger(subsystem: "com.leonchannel.friday", category: "visual")
                .error("Fontes não registradas: \(failed.joined(separator: ", "), privacy: .public); usando a fonte do sistema")
        }
        return Report(registered: registered, failed: failed)
    }
}

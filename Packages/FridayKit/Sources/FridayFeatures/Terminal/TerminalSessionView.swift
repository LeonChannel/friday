// Resumo: Mostra na tela o terminal de verdade (SwiftTerm) de uma sessão e encerra processos com SIGTERM e, se preciso, SIGKILL.
// Tags: terminal, interface

import AppKit
import FridayDomain
import SwiftTerm
import SwiftUI

/// Mostra o terminal de uma sessão. A view vem do registro do model, então sair da tela não encerra o processo.
struct TerminalSessionView: NSViewRepresentable {
    let session: TerminalSession
    let model: TerminalSessionsModel
    @Environment(\.colorScheme) private var colorScheme

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let view = model.terminalView(for: session)
        // A mesma view pode ter estado em outra tela; ela só pode ter um pai.
        view.removeFromSuperview()
        applyTheme(to: view)
        return view
    }

    func updateNSView(_ view: LocalProcessTerminalView, context: Context) {
        applyTheme(to: view)
    }

    /// O SwiftTerm guarda cor fixa, então a troca de aparência é reaplicada a cada atualização.
    private func applyTheme(to view: LocalProcessTerminalView) {
        let appearance: ThemeAppearance = colorScheme == .dark ? .dark : .light
        view.nativeBackgroundColor = NSColor(hex: ThemeToken.fundo.hex(appearance))
        view.nativeForegroundColor = NSColor(hex: ThemeToken.texto.hex(appearance))
        view.caretColor = NSColor(hex: ThemeToken.voce.hex(appearance))
        view.caretTextColor = NSColor(hex: ThemeToken.textoSobreVoce.hex(appearance))
    }
}

/// Encerra o processo com SIGTERM e, se ele ignorar, com SIGKILL.
enum TerminalProcessKiller {
    static func terminate(_ process: LocalProcess?, escalateAfter delay: TimeInterval = 2) {
        guard let process, process.running else { return }
        let pid = process.shellPid
        process.terminate()
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            // Só escala se o mesmo pid ainda existe; kill(pid, 0) testa sem enviar sinal.
            if kill(pid, 0) == 0 { kill(pid, SIGKILL) }
        }
    }
}

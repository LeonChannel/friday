// Resumo: Mostra um terminal de verdade (SwiftTerm) rodando a receita de uma sessão e avisa quando o processo termina.
// Tags: terminal, interface

import AppKit
import FridayDomain
import SwiftTerm
import SwiftUI

/// Terminal embutido de uma sessão. Sair da tela encerra o processo, então só feche a aba (e não esconda a view) para matar.
struct TerminalSessionView: NSViewRepresentable {
    let session: TerminalSession
    let onExit: @MainActor (Int32?) -> Void
    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> Coordinator { Coordinator(onExit: onExit) }

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let view = LocalProcessTerminalView(frame: .zero)
        view.font = Typography.terminalFont()
        applyTheme(to: view)
        view.processDelegate = context.coordinator
        let plan = session.plan
        view.startProcess(
            executable: plan.executable,
            args: plan.arguments,
            environment: plan.environment.map { "\($0.key)=\($0.value)" },
            currentDirectory: plan.workingDirectory
        )
        return view
    }

    func updateNSView(_ view: LocalProcessTerminalView, context: Context) {
        context.coordinator.onExit = onExit
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

    static func dismantleNSView(_ view: LocalProcessTerminalView, coordinator: Coordinator) {
        coordinator.onExit = { _ in }
        TerminalProcessKiller.terminate(view.process)
    }

    @MainActor
    final class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var onExit: @MainActor (Int32?) -> Void

        init(onExit: @escaping @MainActor (Int32?) -> Void) { self.onExit = onExit }

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
        func processTerminated(source: TerminalView, exitCode: Int32?) { onExit(exitCode) }
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

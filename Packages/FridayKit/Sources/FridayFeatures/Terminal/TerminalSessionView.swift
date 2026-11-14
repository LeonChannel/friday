// Resumo: Mostra um terminal de verdade (SwiftTerm) rodando a receita de uma sessão e avisa quando o processo termina.
// Tags: terminal, interface

import AppKit
import FridayDomain
import SwiftTerm
import SwiftUI

/// Terminal embutido de uma sessão. Sair da tela encerra o processo, então só feche a aba (e não esconda a view) para matar.
struct TerminalSessionView: NSViewRepresentable {
    let session: TerminalSession
    let onTitle: @MainActor (String) -> Void
    let onExit: @MainActor (Int32?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onTitle: onTitle, onExit: onExit) }

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let view = LocalProcessTerminalView(frame: .zero)
        view.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
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
        context.coordinator.onTitle = onTitle
        context.coordinator.onExit = onExit
    }

    static func dismantleNSView(_ view: LocalProcessTerminalView, coordinator: Coordinator) {
        coordinator.onTitle = { _ in }
        coordinator.onExit = { _ in }
        TerminalProcessKiller.terminate(view.process)
    }

    @MainActor
    final class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var onTitle: @MainActor (String) -> Void
        var onExit: @MainActor (Int32?) -> Void

        init(onTitle: @escaping @MainActor (String) -> Void, onExit: @escaping @MainActor (Int32?) -> Void) {
            self.onTitle = onTitle
            self.onExit = onExit
        }

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
        func setTerminalTitle(source: LocalProcessTerminalView, title: String) { onTitle(title) }
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

// Resumo: Guarda a view de terminal de cada sessão viva, para o processo sobreviver quando a tela troca; só fechar a sessão encerra o processo.
// Tags: terminal

import AppKit
import FridayDomain
import SwiftTerm

/// Uma view SwiftTerm por sessão, criada e iniciada uma vez só. A tela pede a view aqui em vez de criar.
@MainActor
final class TerminalViewRegistry {
    private var entries: [AgentSessionID: (view: LocalProcessTerminalView, delegate: TerminalProcessDelegate)] = [:]

    /// View da sessão; na primeira chamada cria e inicia o processo da receita.
    func view(for session: TerminalSession, onTitle: @escaping @MainActor (String) -> Void, onExit: @escaping @MainActor (Int32?) -> Void) -> LocalProcessTerminalView {
        if let entry = entries[session.id] { return entry.view }
        let view = LocalProcessTerminalView(frame: .zero)
        view.font = Typography.terminalFont()
        let delegate = TerminalProcessDelegate(onTitle: onTitle, onExit: onExit)
        view.processDelegate = delegate
        let plan = session.plan
        view.startProcess(
            executable: plan.executable,
            args: plan.arguments,
            environment: plan.environment.map { "\($0.key)=\($0.value)" },
            currentDirectory: plan.workingDirectory
        )
        entries[session.id] = (view, delegate)
        return view
    }

    /// Encerra o processo da sessão e esquece a view.
    func close(_ id: AgentSessionID) {
        guard let entry = entries.removeValue(forKey: id) else { return }
        entry.delegate.onTitle = { _ in }
        entry.delegate.onExit = { _ in }
        TerminalProcessKiller.terminate(entry.view.process)
        entry.view.removeFromSuperview()
    }
}

/// Repassa título e fim do processo do SwiftTerm para o model.
@MainActor
final class TerminalProcessDelegate: NSObject, LocalProcessTerminalViewDelegate {
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

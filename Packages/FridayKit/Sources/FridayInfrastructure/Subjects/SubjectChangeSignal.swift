// Resumo: Aviso entre processos de que a CLI gravou no banco (assunto ou backlog), para o app aberto atualizar.
// Tags: assuntos, backlog, persistencia

import Darwin
import notify
import Foundation

/// Notificação do sistema (Darwin) que a CLI dispara depois de escrever e o app escuta. O banco compartilhado não avisa sozinho mudança de outro processo.
public enum SubjectChangeSignal {
    static let name = "com.leonchannel.friday.subjects-changed"

    /// Avisa todos os processos que escutam.
    public static func post() {
        notify_post(name)
    }

    /// Um valor a cada aviso recebido, até quem consome cancelar.
    public static func changes() -> AsyncStream<Void> {
        AsyncStream { continuation in
            var token: Int32 = 0
            let status = notify_register_dispatch(name, &token, DispatchQueue(label: "friday.subject-signal")) { _ in
                continuation.yield()
            }
            guard status == NOTIFY_STATUS_OK else {
                continuation.finish()
                return
            }
            let registered = token
            continuation.onTermination = { _ in notify_cancel(registered) }
        }
    }
}

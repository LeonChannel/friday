// Resumo: Script de shell que o agente chama a cada hook: repassa o JSON ao socket do Friday e nunca atrasa nem derruba o agente.
// Tags: sensor, agentes

import Foundation

/// O script de hook que o Friday grava em disco. Sempre sai com 0 e em cerca de 1 s no máximo, mesmo com o Friday fechado.
public enum HookScript {
    public static let fileName = "friday-hook.sh"

    /// Texto do script. Argumento 1 = agente (`claude`); usa `FRIDAY_SESSION_ID` e `FRIDAY_SOCKET` do ambiente.
    public static let contents = """
    #!/bin/sh
    # Friday: repassa o evento de hook ao app. Nunca falha e nunca bloqueia o agente.
    PATH=/usr/bin:/bin
    agent="${1:-claude}"
    if [ -z "$FRIDAY_SESSION_ID" ] || [ -z "$FRIDAY_SOCKET" ] || [ ! -S "$FRIDAY_SOCKET" ]; then
      cat >/dev/null 2>&1
      exit 0
    fi
    { printf '%s %s\\n' "$agent" "$FRIDAY_SESSION_ID"; cat; } | nc -U -w 1 "$FRIDAY_SOCKET" >/dev/null 2>&1
    exit 0
    """ + "\n"

    /// Grava o script em `directory` (0700, executável) e devolve o caminho. Reescreve só se o conteúdo mudou.
    @discardableResult
    public static func install(in directory: URL, fileManager: FileManager = .default) throws -> URL {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let url = directory.appendingPathComponent(fileName)
        if (try? String(contentsOf: url, encoding: .utf8)) != contents {
            try Data(contents.utf8).write(to: url, options: .atomic)
        }
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
        return url
    }
}

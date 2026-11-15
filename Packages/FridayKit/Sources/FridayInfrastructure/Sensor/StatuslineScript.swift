// Resumo: Script da statusline das sessões do Claude abertas pelo Friday: manda a cota ao app e devolve a statusline que o usuário já tinha, sem atrasar o terminal.
// Tags: sensor, cota

import Foundation

/// A statusline de sessão do Friday. O Claude Code entrega o JSON da sessão a cada atualização; o script repassa ao socket
/// (só quando há `rate_limits`, no máximo a cada 10 s) e roda a statusline do usuário (`FRIDAY_STATUSLINE_NEXT`) com o mesmo JSON.
public enum StatuslineScript {
    public static let fileName = "friday-statusline.sh"

    public static let contents = """
    #!/bin/sh
    # Friday: cota para o app e a statusline do usuário de volta. Nunca falha.
    user_path="$PATH"
    PATH=/usr/bin:/bin
    payload=$(cat)
    if [ -n "$FRIDAY_SESSION_ID" ] && [ -n "$FRIDAY_HOOK_SOCKET" ] && [ -S "$FRIDAY_HOOK_SOCKET" ]; then
      case "$payload" in
        *'"rate_limits"'*)
          stamp="${TMPDIR:-/tmp}/friday-statusline-$FRIDAY_SESSION_ID"
          now=$(date +%s)
          last=$(cat "$stamp" 2>/dev/null)
          case "$last" in ''|*[!0-9]*) last=0 ;; esac
          if [ $((now - last)) -ge 10 ]; then
            printf '%s' "$now" > "$stamp" 2>/dev/null
            { printf 'statusline %s\\n' "$FRIDAY_SESSION_ID"; printf '%s' "$payload"; } | nc -U -w 1 "$FRIDAY_HOOK_SOCKET" >/dev/null 2>&1 &
          fi
          ;;
      esac
    fi
    if [ -n "$FRIDAY_STATUSLINE_NEXT" ]; then
      printf '%s' "$payload" | PATH="$user_path" /bin/sh -c "$FRIDAY_STATUSLINE_NEXT"
    fi
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

    /// Comando da statusline que o usuário configurou em `~/.claude/settings.json`, só lido. `nil` sem statusline de comando.
    public static func userCommand(home: String) -> String? {
        let file = URL(fileURLWithPath: home).appendingPathComponent(".claude/settings.json")
        guard let data = try? Data(contentsOf: file),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let statusLine = object["statusLine"] as? [String: Any],
              statusLine["type"] as? String == "command",
              let command = statusLine["command"] as? String, !command.isEmpty else { return nil }
        return command
    }
}

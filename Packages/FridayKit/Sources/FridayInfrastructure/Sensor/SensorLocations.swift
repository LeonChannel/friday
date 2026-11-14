// Resumo: Define onde ficam o socket dos hooks, o script de hook e os arquivos de settings por sessão, respeitando o limite de tamanho do caminho do socket.
// Tags: sensor

import Foundation

/// Pastas e arquivos que o sensor usa. Tudo dentro de diretórios do Friday com permissão só do usuário (0700).
public struct SensorLocations: Equatable, Sendable {
    /// Limite do `sun_path` do macOS é 104 bytes contando o terminador; sobra margem.
    static let maxSocketPathBytes = 100

    /// Diretório do socket (0700).
    public var runDirectory: URL
    public var socketPath: String
    /// Onde o script de hook é gravado.
    public var hooksDirectory: URL
    /// Onde ficam os settings gerados por sessão.
    public var sessionsDirectory: URL

    public init(runDirectory: URL, socketName: String = "hooks.sock", hooksDirectory: URL, sessionsDirectory: URL) {
        self.runDirectory = runDirectory
        self.socketPath = runDirectory.appendingPathComponent(socketName).path
        self.hooksDirectory = hooksDirectory
        self.sessionsDirectory = sessionsDirectory
    }

    /// Tudo sob uma pasta única (usado em teste, com uma pasta curta).
    public init(root: URL) {
        self.init(
            runDirectory: root.appendingPathComponent("run", isDirectory: true),
            hooksDirectory: root.appendingPathComponent("hooks", isDirectory: true),
            sessionsDirectory: root.appendingPathComponent("sessions", isDirectory: true)
        )
    }

    /// Locais de produção. O socket vai em `~/Library/Application Support/Friday/run/` quando o caminho cabe no
    /// limite; senão cai em `/tmp/friday-<uid>/`, que é curto e protegido por dono e permissão 0700.
    public static func live(fileManager: FileManager = .default) throws -> SensorLocations {
        let support = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Friday", isDirectory: true)
        var locations = SensorLocations(root: support)
        if locations.socketPath.utf8.count > maxSocketPathBytes {
            locations.runDirectory = URL(fileURLWithPath: "/tmp/friday-\(getuid())", isDirectory: true)
            locations.socketPath = locations.runDirectory.appendingPathComponent("hooks.sock").path
        }
        return locations
    }
}

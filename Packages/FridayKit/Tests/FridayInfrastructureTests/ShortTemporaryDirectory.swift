// Resumo: Pasta temporária de caminho curto, necessária porque o caminho de um Unix socket tem limite de 104 bytes.
// Tags: testes, sensor

import Foundation

/// Pasta em `/tmp/fk-<8 hex>`, apagada por `remove()`. O `TMPDIR` do macOS é longo demais para sockets.
struct ShortTemporaryDirectory {
    let url: URL

    init() throws {
        let suffix = UUID().uuidString.prefix(8).lowercased()
        url = URL(fileURLWithPath: "/tmp/fk-\(suffix)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}

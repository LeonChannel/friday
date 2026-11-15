// Resumo: Cota de uso do Claude (janela de 5 horas e de 7 dias, quanto foi usado e quando renova) lida do JSON da statusline, sem pedir nada ao modelo.
// Tags: cota

import Foundation

/// Uma janela de limite: quanto já foi usado e quando zera.
public struct QuotaWindow: Equatable, Sendable {
    /// Porcentagem usada, de 0 a 100.
    public var usedPercentage: Double
    public var resetsAt: Date

    public init(usedPercentage: Double, resetsAt: Date) {
        self.usedPercentage = min(max(usedPercentage, 0), 100)
        self.resetsAt = resetsAt
    }

    /// Fração usada, de 0 a 1, para a barra.
    public var fraction: Double { usedPercentage / 100 }

    /// Tempo até renovar em texto curto ("2 h 13 min", "3 d 4 h", "agora").
    public func timeToReset(from now: Date) -> String {
        let seconds = Int(resetsAt.timeIntervalSince(now))
        guard seconds > 59 else { return "agora" }
        let minutes = seconds / 60, hours = minutes / 60, days = hours / 24
        if days > 0 { return hours % 24 > 0 ? "\(days) d \(hours % 24) h" : "\(days) d" }
        if hours > 0 { return minutes % 60 > 0 ? "\(hours) h \(minutes % 60) min" : "\(hours) h" }
        return "\(minutes) min"
    }
}

/// O último retrato da cota da conta, com a hora em que foi lido.
public struct UsageQuota: Equatable, Sendable {
    public var fiveHour: QuotaWindow?
    public var sevenDay: QuotaWindow?
    public var capturedAt: Date

    public init(fiveHour: QuotaWindow?, sevenDay: QuotaWindow?, capturedAt: Date) {
        self.fiveHour = fiveHour
        self.sevenDay = sevenDay
        self.capturedAt = capturedAt
    }

    /// Lê `rate_limits` do JSON que o Claude Code entrega à statusline. `nil` quando não há cota (antes da primeira resposta, ou conta sem limite).
    public static func decode(statusline json: Data, capturedAt: Date) -> UsageQuota? {
        guard let object = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              let limits = object["rate_limits"] as? [String: Any] else { return nil }
        let quota = UsageQuota(fiveHour: window(limits["five_hour"]), sevenDay: window(limits["seven_day"]), capturedAt: capturedAt)
        return quota.fiveHour == nil && quota.sevenDay == nil ? nil : quota
    }

    private static func window(_ raw: Any?) -> QuotaWindow? {
        guard let raw = raw as? [String: Any],
              let used = (raw["used_percentage"] as? NSNumber)?.doubleValue,
              let resets = (raw["resets_at"] as? NSNumber)?.doubleValue else { return nil }
        return QuotaWindow(usedPercentage: used, resetsAt: Date(timeIntervalSince1970: resets))
    }

    /// Janela que já renovou desde a leitura não vale mais: o uso dela voltou a zero e o retrato está velho.
    public func current(at now: Date) -> UsageQuota {
        var copy = self
        if let window = fiveHour, window.resetsAt <= now { copy.fiveHour = nil }
        if let window = sevenDay, window.resetsAt <= now { copy.sevenDay = nil }
        return copy
    }
}

/// Onde o último retrato da cota fica guardado. A cota é da conta, então só o mais recente importa.
public protocol UsageQuotaRepository: Sendable {
    func save(_ quota: UsageQuota) throws
    /// O retrato mais recente agora e a cada mudança; `nil` antes do primeiro.
    func observeLatest() -> AsyncThrowingStream<UsageQuota?, any Error>
}

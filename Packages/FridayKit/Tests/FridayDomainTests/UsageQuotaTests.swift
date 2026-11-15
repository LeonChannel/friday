// Resumo: Prova a leitura da cota do JSON real da statusline, o texto de quanto falta para renovar e o descarte de janela que já renovou.
// Tags: cota, testes

import FridayDomain
import Foundation
import Testing

struct UsageQuotaTests {
    private let captured = Date(timeIntervalSince1970: 1_794_690_000)

    @Test func decodesRateLimitsFromRealStatuslinePayload() throws {
        let tests = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let json = try Data(contentsOf: tests.appendingPathComponent("Fixtures/claude/statusline.json"))
        let quota = try #require(UsageQuota.decode(statusline: json, capturedAt: captured))
        #expect(quota.fiveHour == QuotaWindow(usedPercentage: 26, resetsAt: Date(timeIntervalSince1970: 1_794_699_600)))
        #expect(quota.sevenDay?.usedPercentage == 39)
        #expect(quota.capturedAt == captured)
    }

    @Test func noRateLimitsMeansNoQuota() {
        #expect(UsageQuota.decode(statusline: Data(#"{"session_id":"x","cost":{}}"#.utf8), capturedAt: captured) == nil)
        #expect(UsageQuota.decode(statusline: Data(#"{"rate_limits":{}}"#.utf8), capturedAt: captured) == nil)
        #expect(UsageQuota.decode(statusline: Data("lixo".utf8), capturedAt: captured) == nil)
        let partial = UsageQuota.decode(statusline: Data(#"{"rate_limits":{"seven_day":{"used_percentage":12.5,"resets_at":1794790800}}}"#.utf8), capturedAt: captured)
        #expect(partial?.fiveHour == nil && partial?.sevenDay?.usedPercentage == 12.5)
    }

    @Test(arguments: [(30.0, "agora"), (600, "10 min"), (7_980, "2 h 13 min"), (7_200, "2 h"), (97_200, "1 d 3 h"), (172_800, "2 d")])
    func timeToResetIsShort(seconds: Double, expected: String) {
        let window = QuotaWindow(usedPercentage: 10, resetsAt: captured.addingTimeInterval(seconds))
        #expect(window.timeToReset(from: captured) == expected)
    }

    @Test func clampsPercentageAndDropsRenewedWindow() {
        #expect(QuotaWindow(usedPercentage: 140, resetsAt: captured).fraction == 1)
        let quota = UsageQuota(
            fiveHour: QuotaWindow(usedPercentage: 90, resetsAt: captured.addingTimeInterval(60)),
            sevenDay: QuotaWindow(usedPercentage: 40, resetsAt: captured.addingTimeInterval(86_400)),
            capturedAt: captured
        )
        let later = quota.current(at: captured.addingTimeInterval(120))
        #expect(later.fiveHour == nil && later.sevenDay != nil)
    }
}

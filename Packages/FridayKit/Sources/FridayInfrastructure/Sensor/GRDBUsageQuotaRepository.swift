// Resumo: Guarda no banco o último retrato da cota do Claude (uma linha só) e avisa a tela a cada mudança.
// Tags: cota, persistencia

import FridayDomain
import Foundation
import GRDB

/// Cota no SQLite: a linha 1 é sempre o retrato mais recente.
public struct GRDBUsageQuotaRepository: UsageQuotaRepository {
    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func save(_ quota: UsageQuota) throws {
        try database.writer.write { db in
            try db.execute(
                sql: """
                    INSERT OR REPLACE INTO usageQuota (id, capturedAt, fiveHourUsed, fiveHourResetsAt, sevenDayUsed, sevenDayResetsAt)
                    VALUES (1, ?, ?, ?, ?, ?)
                    """,
                arguments: [quota.capturedAt, quota.fiveHour?.usedPercentage, quota.fiveHour?.resetsAt, quota.sevenDay?.usedPercentage, quota.sevenDay?.resetsAt]
            )
        }
    }

    public func observeLatest() -> AsyncThrowingStream<UsageQuota?, any Error> {
        let values = ValueObservation
            .tracking { db in try Row.fetchOne(db, sql: "SELECT * FROM usageQuota WHERE id = 1").map(Self.quota) }
            .removeDuplicates()
            .values(in: database.writer)
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await quota in values { continuation.yield(quota) }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func quota(_ row: Row) -> UsageQuota {
        func window(_ used: String, _ resets: String) -> QuotaWindow? {
            guard let percentage: Double = row[used], let date: Date = row[resets] else { return nil }
            return QuotaWindow(usedPercentage: percentage, resetsAt: date)
        }
        return UsageQuota(fiveHour: window("fiveHourUsed", "fiveHourResetsAt"), sevenDay: window("sevenDayUsed", "sevenDayResetsAt"), capturedAt: row["capturedAt"])
    }
}

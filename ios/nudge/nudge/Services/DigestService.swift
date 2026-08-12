//
//  DigestService.swift
//  nudge
//
//  Builds a friendly DailyDigest from the current items.
//

import Foundation

/// Generates a `DailyDigest` summary message from forgotten/urgent items.
enum DigestService {

    /// Produces a digest highlighting the most urgent forgotten items.
    static func makeDigest(from items: [InboxItem], now: Date = .now) -> DailyDigest {
        let forgotten = ItemRanker.forgottenItems(from: items, now: now)
        let message = summaryMessage(forgottenCount: forgotten.count)
        return DailyDigest(generatedAt: now, items: Array(forgotten.prefix(5)), message: message)
    }

    /// The friendly one-liner shown on the Forgotten tab and in the digest.
    static func summaryMessage(forgottenCount count: Int) -> String {
        switch count {
        case 0:
            return "You're all caught up. Nothing has been forgotten."
        case 1:
            return "You saved 1 thing recently that you haven't acted on."
        default:
            return "You saved \(count) things recently that you haven't acted on."
        }
    }
}

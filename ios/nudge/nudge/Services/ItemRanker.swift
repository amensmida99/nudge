//
//  ItemRanker.swift
//  nudge
//
//  Pure ranking logic for the Today and Forgotten lists. Kept free of SwiftUI
//  and SwiftData so it's easy to reason about and unit test.
//

import Foundation

/// Scores and orders items using due/reminder dates, priority, pin status, and age.
enum ItemRanker {

    /// Computes the "Today" list: active items that deserve attention now, ranked.
    static func todayItems(from items: [InboxItem], now: Date = .now) -> [InboxItem] {
        let candidates = items.filter { item in
            guard item.status.isActive else { return false }
            // Include if pinned, high priority, due/remind today or overdue, or aging.
            if item.isPinned { return true }
            if item.priority == .high { return true }
            if let date = item.effectiveDate, date <= endOfToday(now) { return true }
            if item.ageInDays >= AppConstants.forgottenThresholdDays { return true }
            return false
        }
        return candidates.sorted { todayScore($0, now: now) > todayScore($1, now: now) }
    }

    /// Computes the "Forgotten" list: active items older than the threshold, ranked
    /// with the most urgent first (due soon, high priority, oldest).
    static func forgottenItems(from items: [InboxItem], now: Date = .now) -> [InboxItem] {
        items
            .filter { $0.status.isActive && $0.ageInDays >= AppConstants.forgottenThresholdDays }
            .sorted { forgottenScore($0, now: now) > forgottenScore($1, now: now) }
    }

    // MARK: Scoring

    /// Higher score == should appear earlier in the Today list.
    static func todayScore(_ item: InboxItem, now: Date = .now) -> Double {
        var score = 0.0

        if item.isPinned { score += 1000 }
        score += Double(item.priority.weight) * 100

        // Reward proximity of due/reminder date (overdue scores highest).
        if let date = item.effectiveDate {
            let hoursUntil = date.timeIntervalSince(now) / 3600
            if hoursUntil <= 0 {
                score += 500 // overdue
            } else {
                score += max(0, 300 - hoursUntil) // sooner == higher
            }
        }

        // Gentle nudge for older items so they don't rot.
        score += Double(min(item.ageInDays, 30)) * 2

        return score
    }

    /// Higher score == more urgent in the Forgotten list.
    static func forgottenScore(_ item: InboxItem, now: Date = .now) -> Double {
        var score = 0.0

        if let date = item.effectiveDate {
            let hoursUntil = date.timeIntervalSince(now) / 3600
            score += hoursUntil <= 0 ? 600 : max(0, 400 - hoursUntil)
        }

        score += Double(item.priority.weight) * 150
        score += Double(item.ageInDays) * 5 // older weighs more here

        return score
    }

    private static func endOfToday(_ now: Date) -> Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
    }
}

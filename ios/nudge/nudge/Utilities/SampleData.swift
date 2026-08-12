//
//  SampleData.swift
//  nudge
//
//  Realistic seed data for SwiftUI previews and first-run demos.
//

import Foundation
import SwiftData

/// Provides sample `InboxItem`s and a ready-to-use in-memory preview container.
enum SampleData {

    /// A spread of items across types, statuses, ages, and priorities.
    static func items() -> [InboxItem] {
        let now = Date.now
        func daysAgo(_ n: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: -n, to: now) ?? now
        }
        func daysFromNow(_ n: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: n, to: now) ?? now
        }

        return [
            InboxItem(
                title: "Standing desk I keep eyeing",
                sourceURL: URL(string: "https://www.fully.com/standing-desks"),
                notes: "Wait for the autumn sale before pulling the trigger.",
                type: .buy,
                status: .inbox,
                createdAt: daysAgo(2),
                priority: .normal,
                isPinned: true
            ),
            InboxItem(
                title: "Renew passport before the trip",
                notes: "Processing takes ~4 weeks.",
                type: .task,
                status: .planned,
                createdAt: daysAgo(1),
                dueDate: daysFromNow(3),
                reminderDate: daysFromNow(1),
                priority: .high
            ),
            InboxItem(
                title: "Dune: Part Two",
                sourceURL: URL(string: "https://www.youtube.com/watch?v=Way9Dexny3w"),
                notes: "Watch in IMAX if possible.",
                type: .watch,
                status: .inbox,
                createdAt: daysAgo(9),
                priority: .low
            ),
            InboxItem(
                title: "The case for calm software",
                sourceURL: URL(string: "https://calmtech.com/"),
                type: .read,
                status: .inbox,
                createdAt: daysAgo(12),
                priority: .normal
            ),
            InboxItem(
                title: "Tartine Bakery",
                notes: "That sourdough everyone talks about.",
                type: .place,
                status: .inbox,
                createdAt: daysAgo(20),
                locationName: "San Francisco, CA",
                priority: .low
            ),
            InboxItem(
                title: "App idea: quiet weekly review ritual",
                type: .idea,
                status: .inbox,
                createdAt: daysAgo(4),
                priority: .normal
            ),
            InboxItem(
                title: "Reply to Sam's email",
                type: .task,
                status: .completed,
                createdAt: daysAgo(3),
                priority: .normal
            ),
            InboxItem(
                title: "Old newsletter I never read",
                sourceURL: URL(string: "https://example.com/newsletter"),
                type: .read,
                status: .inbox,
                createdAt: daysAgo(18),
                priority: .low
            )
        ]
    }

    /// An in-memory `ModelContainer` seeded with sample data, for previews.
    @MainActor
    static var previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: InboxItem.self, DailyDigest.self,
            configurations: config
        )
        for item in items() {
            container.mainContext.insert(item)
        }
        return container
    }()
}

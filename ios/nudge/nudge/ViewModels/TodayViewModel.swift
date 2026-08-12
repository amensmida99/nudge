//
//  TodayViewModel.swift
//  nudge
//
//  Prepares the ranked "Today" list and handles swipe actions.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class TodayViewModel {

    /// Ranks the active items into what deserves attention now.
    func todayItems(from items: [InboxItem]) -> [InboxItem] {
        ItemRanker.todayItems(from: items)
    }

    /// Friendly one-line lead-in shown under the title.
    func subtitle(for count: Int) -> String {
        switch count {
        case 0: return "Nothing needs you right now."
        case 1: return "One thing worth a moment."
        default: return "\(count) things worth a moment."
        }
    }

    // MARK: Swipe actions (delegated to the shared mutator)

    func complete(_ item: InboxItem, context: ModelContext) {
        ItemMutator.complete(item, context: context)
    }

    func snooze(_ item: InboxItem, context: ModelContext) {
        ItemMutator.snooze(item, days: 1, context: context)
    }

    func archive(_ item: InboxItem, context: ModelContext) {
        ItemMutator.archive(item, context: context)
    }
}

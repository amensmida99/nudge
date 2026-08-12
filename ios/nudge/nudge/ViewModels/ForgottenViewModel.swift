//
//  ForgottenViewModel.swift
//  nudge
//
//  Surfaces items saved more than 7 days ago that still need action.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class ForgottenViewModel {

    /// Urgent-first ranked list of forgotten items.
    func forgottenItems(from items: [InboxItem]) -> [InboxItem] {
        ItemRanker.forgottenItems(from: items)
    }

    /// Friendly summary line shown at the top.
    func summary(for items: [InboxItem]) -> String {
        DigestService.summaryMessage(forgottenCount: forgottenItems(from: items).count)
    }

    // MARK: Bulk actions

    /// Snoozes every forgotten item by one day.
    func snoozeAll(_ items: [InboxItem], context: ModelContext) {
        for item in forgottenItems(from: items) {
            ItemMutator.snooze(item, days: 1, context: context)
        }
    }

    /// "Review later": moves forgotten items to `planned` and nudges them a few
    /// days out so they leave the Forgotten list until the user is ready.
    func reviewLater(_ items: [InboxItem], context: ModelContext) {
        for item in forgottenItems(from: items) {
            ItemMutator.snooze(item, days: 3, context: context)
        }
    }
}

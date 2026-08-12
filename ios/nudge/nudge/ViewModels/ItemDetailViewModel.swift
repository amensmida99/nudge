//
//  ItemDetailViewModel.swift
//  nudge
//
//  Handles actions for the Item Detail screen. Field editing binds directly to
//  the SwiftData model (autosaved); this type owns the side-effecting actions.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class ItemDetailViewModel {

    func markCompleted(_ item: InboxItem, context: ModelContext) {
        ItemMutator.complete(item, context: context)
    }

    func togglePin(_ item: InboxItem, context: ModelContext) {
        ItemMutator.togglePin(item, context: context)
    }

    func delete(_ item: InboxItem, context: ModelContext) {
        ItemMutator.delete(item, context: context)
    }

    /// Re-schedules or cancels the local reminder to match the item's state.
    func syncReminder(for item: InboxItem) {
        let service = NotificationService.shared
        service.cancelReminder(for: item.id)
        if item.reminderDate != nil {
            Task { await service.scheduleReminder(for: item) }
        }
    }
}

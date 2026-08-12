//
//  ItemMutator.swift
//  nudge
//
//  Centralized item state changes shared by Today, Inbox, and Forgotten so the
//  behavior (and notification side effects) stays consistent everywhere.
//

import Foundation
import SwiftData

/// Applies common lifecycle actions to an `InboxItem` and keeps reminders in sync.
@MainActor
enum ItemMutator {

    static func complete(_ item: InboxItem, context: ModelContext) {
        item.status = .completed
        NotificationService.shared.cancelReminder(for: item.id)
        save(context)
    }

    static func archive(_ item: InboxItem, context: ModelContext) {
        item.status = .archived
        NotificationService.shared.cancelReminder(for: item.id)
        save(context)
    }

    /// Pushes an item's reminder (and effective attention) out by `days`.
    static func snooze(_ item: InboxItem, days: Int = 1, context: ModelContext) {
        let base = max(item.reminderDate ?? .now, .now)
        let newDate = Calendar.current.date(byAdding: .day, value: days, to: base) ?? base
        item.reminderDate = newDate
        item.status = .planned
        save(context)
        Task { await NotificationService.shared.scheduleReminder(for: item) }
    }

    static func togglePin(_ item: InboxItem, context: ModelContext) {
        item.isPinned.toggle()
        save(context)
    }

    static func delete(_ item: InboxItem, context: ModelContext) {
        NotificationService.shared.cancelReminder(for: item.id)
        context.delete(item)
        save(context)
    }

    private static func save(_ context: ModelContext) {
        try? context.save()
    }
}

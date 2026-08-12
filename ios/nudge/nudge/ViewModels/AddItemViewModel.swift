//
//  AddItemViewModel.swift
//  nudge
//
//  Backs the Add Item form: holds draft state, requests a category suggestion,
//  and persists the new item.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class AddItemViewModel {

    // MARK: Draft fields
    var title = ""
    var urlString = ""
    var notes = ""
    var type: ItemType = .other
    var priority: Priority = .normal
    var reminderEnabled = false
    var reminderDate = Date.now.addingTimeInterval(3600)
    var imageData: Data?

    /// True once the classifier has proposed a type the user hasn't overridden.
    var didAutoSuggest = false

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// A parsed URL from the text field, if valid.
    var url: URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }

    // MARK: Classification

    /// Asks the classifier for a suggested category based on the current draft.
    /// Only applies the suggestion if the user hasn't manually chosen a type.
    func suggestCategory(using classifier: ClassificationService) async {
        guard isValid, !didAutoSuggest else { return }
        let suggestion = await classifier.classify(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            url: url
        )
        // Respect a manual choice made while we were classifying.
        if type == .other {
            type = suggestion
            didAutoSuggest = true
        }
    }

    // MARK: Persistence

    /// Creates and inserts the item. Schedules a reminder if enabled.
    func save(context: ModelContext) {
        let item = InboxItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            sourceURL: url,
            notes: notes.isEmpty ? nil : notes,
            type: type,
            status: .inbox,
            reminderDate: reminderEnabled ? reminderDate : nil,
            imageData: imageData,
            priority: priority
        )
        context.insert(item)
        try? context.save()

        if reminderEnabled {
            Task { await NotificationService.shared.scheduleReminder(for: item) }
        }
    }
}

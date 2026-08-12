//
//  InboxItem.swift
//  nudge
//
//  The core captured item persisted with SwiftData.
//

import Foundation
import SwiftData

/// A single thing the user saved to deal with later.
///
/// Stored locally with SwiftData for offline-first behavior. Enums are stored
/// via their raw `String` values so the schema stays stable and portable to a
/// future backend.
@Model
final class InboxItem {
    /// Stable identity, also used to de-duplicate items imported from the Share Extension.
    @Attribute(.unique) var id: UUID

    var title: String
    var sourceURL: URL?
    var notes: String?

    /// Backing raw value for `ItemType`. Access through the `type` computed property.
    var typeRaw: String
    /// Backing raw value for `ItemStatus`. Access through the `status` computed property.
    var statusRaw: String
    /// Backing raw value for `Priority`. Access through the `priority` computed property.
    var priorityRaw: String

    var createdAt: Date
    var dueDate: Date?
    var reminderDate: Date?

    /// Optional attached image (screenshot/photo). Stored externally to keep the store light.
    @Attribute(.externalStorage) var imageData: Data?

    var locationName: String?

    /// Placeholder for a future AI-generated summary (populated by `APIClient`).
    var aiSummary: String?

    var isPinned: Bool

    // MARK: Type-safe accessors

    var type: ItemType {
        get { ItemType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    var status: ItemStatus {
        get { ItemStatus(rawValue: statusRaw) ?? .inbox }
        set { statusRaw = newValue.rawValue }
    }

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .normal }
        set { priorityRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        sourceURL: URL? = nil,
        notes: String? = nil,
        type: ItemType = .other,
        status: ItemStatus = .inbox,
        createdAt: Date = .now,
        dueDate: Date? = nil,
        reminderDate: Date? = nil,
        imageData: Data? = nil,
        locationName: String? = nil,
        priority: Priority = .normal,
        aiSummary: String? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.sourceURL = sourceURL
        self.notes = notes
        self.typeRaw = type.rawValue
        self.statusRaw = status.rawValue
        self.priorityRaw = priority.rawValue
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.reminderDate = reminderDate
        self.imageData = imageData
        self.locationName = locationName
        self.aiSummary = aiSummary
        self.isPinned = isPinned
    }
}

// MARK: - Derived helpers

extension InboxItem {

    /// Number of whole days since the item was created.
    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: .now).day ?? 0
    }

    /// An item is "forgotten" when it is old and still needs action.
    var isForgotten: Bool {
        status.isActive && ageInDays >= AppConstants.forgottenThresholdDays
    }

    /// The soonest actionable date associated with the item, if any.
    var effectiveDate: Date? {
        [dueDate, reminderDate].compactMap { $0 }.min()
    }

    /// A short, human-friendly host for showing link provenance on cards.
    var sourceHost: String? {
        guard let host = sourceURL?.host() else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}

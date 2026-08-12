//
//  PendingSharedItem.swift
//  nudge
//
//  A lightweight, Codable transfer object written by the Share Extension and
//  imported by the main app.
//

import Foundation

/// A capture produced by the Share Extension before it becomes a full `InboxItem`.
///
/// This deliberately avoids SwiftData: extensions run in a separate process with
/// a tight memory budget, so we serialize a small Codable payload into the shared
/// App Group container and let the main app do the heavier SwiftData import.
///
/// NOTE: This exact file should be shared between the app target and the Share
/// Extension target (add it to both targets' membership in Xcode). See `SETUP.md`.
struct PendingSharedItem: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var urlString: String?
    var notes: String?
    /// Raw value of `ItemType` guessed by the extension (falls back to "other").
    var typeRaw: String
    var createdAt: Date
    /// Optional image payload (e.g. a shared screenshot) as PNG/JPEG data.
    var imageData: Data?

    init(
        id: UUID = UUID(),
        title: String,
        urlString: String? = nil,
        notes: String? = nil,
        typeRaw: String = ItemType.other.rawValue,
        createdAt: Date = .now,
        imageData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.notes = notes
        self.typeRaw = typeRaw
        self.createdAt = createdAt
        self.imageData = imageData
    }
}

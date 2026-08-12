//
//  DailyDigest.swift
//  nudge
//
//  A generated summary of items that deserve attention today.
//

import Foundation
import SwiftData

/// A snapshot summary the app produces (and can notify about) to resurface
/// items the user hasn't dealt with.
@Model
final class DailyDigest {
    @Attribute(.unique) var id: UUID
    var generatedAt: Date

    /// The items highlighted in this digest. No inverse relationship is declared
    /// because an item can appear in many transient digests without ownership.
    var items: [InboxItem]

    /// A friendly, human-readable message summarizing the digest.
    var message: String

    init(
        id: UUID = UUID(),
        generatedAt: Date = .now,
        items: [InboxItem] = [],
        message: String = ""
    ) {
        self.id = id
        self.generatedAt = generatedAt
        self.items = items
        self.message = message
    }
}

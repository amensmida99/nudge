//
//  ShareImportService.swift
//  nudge
//
//  Imports pending captures from the Share Extension into SwiftData safely.
//

import Foundation
import SwiftData

/// Drains `SharedStore` and converts pending captures into `InboxItem`s,
/// skipping any that were already imported (duplicate protection).
@MainActor
enum ShareImportService {

    /// Imports all pending shared items into the given context.
    /// - Returns: the number of new items actually inserted.
    @discardableResult
    static func importPending(into context: ModelContext) -> Int {
        let pending = SharedStore.drainPending()
        guard !pending.isEmpty else { return 0 }

        // Fetch existing IDs once so we can de-duplicate in memory.
        let existing = (try? context.fetch(FetchDescriptor<InboxItem>())) ?? []
        var existingIDs = Set(existing.map(\.id))

        var inserted = 0
        for pendingItem in pending {
            // Skip duplicates by stable UUID (extension re-runs, double taps, etc.).
            guard !existingIDs.contains(pendingItem.id) else { continue }

            let item = InboxItem(
                id: pendingItem.id,
                title: pendingItem.title,
                sourceURL: pendingItem.urlString.flatMap(URL.init(string:)),
                notes: pendingItem.notes,
                type: ItemType(rawValue: pendingItem.typeRaw) ?? .other,
                status: .inbox,
                createdAt: pendingItem.createdAt,
                imageData: pendingItem.imageData
            )
            context.insert(item)
            existingIDs.insert(item.id)
            inserted += 1
        }

        if inserted > 0 {
            try? context.save()
        }
        return inserted
    }
}

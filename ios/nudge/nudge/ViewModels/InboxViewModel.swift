//
//  InboxViewModel.swift
//  nudge
//
//  Holds the Inbox filter/search/sort state and derives the visible list.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class InboxViewModel {

    var searchText = ""
    /// `nil` means "all categories".
    var typeFilter: ItemType?
    /// `nil` means "all active statuses".
    var statusFilter: ItemStatus?
    var sort: InboxSort = .newest

    /// Applies search, filters, and sort to produce the visible items.
    func visibleItems(from items: [InboxItem]) -> [InboxItem] {
        var result = items.filter { item in
            // Inbox shows active items by default; a status filter can override.
            if let statusFilter {
                guard item.status == statusFilter else { return false }
            } else {
                guard item.status.isActive else { return false }
            }
            if let typeFilter, item.type != typeFilter { return false }
            return true
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { item in
                item.title.lowercased().contains(query)
                    || (item.notes?.lowercased().contains(query) ?? false)
                    || (item.sourceURL?.absoluteString.lowercased().contains(query) ?? false)
            }
        }

        return result.sorted(by: sortComparator)
    }

    private func sortComparator(_ a: InboxItem, _ b: InboxItem) -> Bool {
        switch sort {
        case .newest:
            return a.createdAt > b.createdAt
        case .dueDate:
            // Items with a date come first, soonest first; undated fall to the end.
            switch (a.effectiveDate, b.effectiveDate) {
            case let (x?, y?): return x < y
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return a.createdAt > b.createdAt
            }
        case .priority:
            if a.priority.weight != b.priority.weight {
                return a.priority.weight > b.priority.weight
            }
            return a.createdAt > b.createdAt
        }
    }

    var isFiltering: Bool {
        typeFilter != nil || statusFilter != nil || !searchText.isEmpty
    }

    /// Simulates a backend refresh (pull-to-refresh). No-op with the mock client.
    func refresh(using client: APIClient) async {
        _ = try? await client.fetchItems()
    }
}

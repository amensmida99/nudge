//
//  ClassificationService.swift
//  nudge
//
//  Suggests a category for captured content. Protocol-based so an on-device or
//  remote model can replace the keyword heuristic later.
//

import Foundation

/// Suggests an `ItemType` for a title/notes/URL combination.
protocol ClassificationService: Sendable {
    /// Returns the best-guess category for the provided content.
    func classify(title: String, notes: String?, url: URL?) async -> ItemType
}

/// A simple, fully local keyword classifier.
///
/// Deterministic and dependency-free — good enough to demo the "suggest a
/// category" flow. A future `FoundationModels`-based classifier can adopt the
/// same protocol without touching the Add Item screen.
struct MockClassificationService: ClassificationService {

    /// Keyword → type rules, checked in order. First match wins.
    private static let rules: [(keywords: [String], type: ItemType)] = [
        (["buy", "shop", "purchase", "order", "cart", "amazon", "price", "$"], .buy),
        (["watch", "movie", "episode", "netflix", "youtube", "video", "trailer", "film"], .watch),
        (["read", "article", "blog", "book", "paper", "medium", "newsletter"], .read),
        (["restaurant", "cafe", "visit", "trip", "hotel", "place", "map", "address", "park"], .place),
        (["idea", "maybe", "someday", "concept", "brainstorm", "thought"], .idea),
        (["todo", "task", "call", "email", "finish", "submit", "deadline", "pay", "fix"], .task)
    ]

    func classify(title: String, notes: String?, url: URL?) async -> ItemType {
        let haystack = [title, notes ?? "", url?.absoluteString ?? ""]
            .joined(separator: " ")
            .lowercased()

        for rule in Self.rules {
            if rule.keywords.contains(where: { haystack.contains($0) }) {
                return rule.type
            }
        }

        // URLs with no other signal are most often things to read/watch.
        if url != nil { return .read }
        return .other
    }
}

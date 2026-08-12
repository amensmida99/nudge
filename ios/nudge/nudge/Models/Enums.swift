//
//  Enums.swift
//  nudge
//
//  Shared enumerations used by the data models and UI.
//

import SwiftUI

/// The kind of thing a captured item represents.
enum ItemType: String, Codable, CaseIterable, Identifiable {
    case buy
    case task
    case watch
    case read
    case place
    case idea
    case other

    var id: String { rawValue }

    /// Human-readable label for menus and accessibility.
    var label: String {
        switch self {
        case .buy: return "Buy"
        case .task: return "Task"
        case .watch: return "Watch"
        case .read: return "Read"
        case .place: return "Place"
        case .idea: return "Idea"
        case .other: return "Other"
        }
    }

    /// SF Symbol representing the type.
    var symbol: String {
        switch self {
        case .buy: return "cart"
        case .task: return "checkmark.circle"
        case .watch: return "play.rectangle"
        case .read: return "book"
        case .place: return "mappin.and.ellipse"
        case .idea: return "lightbulb"
        case .other: return "tray"
        }
    }

    /// Subtle accent color used for the type icon.
    var tint: Color {
        switch self {
        case .buy: return .green
        case .task: return .blue
        case .watch: return .pink
        case .read: return .orange
        case .place: return .teal
        case .idea: return .yellow
        case .other: return .gray
        }
    }
}

/// Lifecycle status of an item as the user works through their inbox.
enum ItemStatus: String, Codable, CaseIterable, Identifiable {
    case inbox
    case planned
    case completed
    case archived

    var id: String { rawValue }

    var label: String {
        switch self {
        case .inbox: return "Inbox"
        case .planned: return "Planned"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }

    /// Whether an item in this status is still "active" (needs attention).
    var isActive: Bool {
        self == .inbox || self == .planned
    }
}

/// Relative importance of an item, used to rank the Today and Forgotten lists.
enum Priority: String, Codable, CaseIterable, Identifiable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var label: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        }
    }

    /// Numeric weight used by the ranking algorithms (higher == more urgent).
    var weight: Int {
        switch self {
        case .low: return 0
        case .normal: return 1
        case .high: return 2
        }
    }

    var symbol: String {
        switch self {
        case .low: return "arrow.down"
        case .normal: return "minus"
        case .high: return "exclamationmark"
        }
    }

    var tint: Color {
        switch self {
        case .low: return .secondary
        case .normal: return .blue
        case .high: return .red
        }
    }
}

/// Ways the Inbox list can be sorted.
enum InboxSort: String, CaseIterable, Identifiable {
    case newest
    case dueDate
    case priority

    var id: String { rawValue }

    var label: String {
        switch self {
        case .newest: return "Newest"
        case .dueDate: return "Due Date"
        case .priority: return "Priority"
        }
    }
}

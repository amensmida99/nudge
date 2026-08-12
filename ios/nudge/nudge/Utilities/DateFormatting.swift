//
//  DateFormatting.swift
//  nudge
//
//  Small date helpers used throughout the UI.
//

import Foundation

enum DateFormatting {

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    /// A short relative description like "in 2 days", "3 hr ago", "now".
    static func relative(_ date: Date, from reference: Date = .now) -> String {
        if abs(date.timeIntervalSince(reference)) < 60 { return "now" }
        return relativeFormatter.localizedString(for: date, relativeTo: reference)
    }

    /// A medium absolute description like "Aug 12, 2026 at 9:41 AM".
    static func absolute(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}

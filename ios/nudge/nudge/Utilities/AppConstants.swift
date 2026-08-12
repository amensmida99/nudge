//
//  AppConstants.swift
//  nudge
//
//  App-wide constants and configuration values.
//

import Foundation

/// Central place for identifiers and tunable constants.
///
/// IMPORTANT — App Group configuration:
/// The `appGroupID` below MUST match the App Group you create in Xcode for BOTH
/// the main app target and the Share Extension target. See `SETUP.md` for the
/// full walkthrough. If the App Group is missing or misspelled, the shared
/// container falls back to standard `UserDefaults` and items saved from the
/// Share Sheet will not appear in the app.
enum AppConstants {

    /// The shared App Group identifier. Change this to match your team/bundle.
    /// Format is typically: group.<your-reverse-dns>.shared
    static let appGroupID = "group.nudge.shared"

    /// Number of days after which an unhandled item is considered "forgotten".
    static let forgottenThresholdDays = 7

    /// Identifier for the repeating daily digest notification.
    static let dailyDigestNotificationID = "com.nudge.dailyDigest"

    /// UserDefaults key marking whether onboarding has been completed.
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    /// UserDefaults key for the user's preferred daily digest hour (0-23).
    static let digestHourKey = "digestHour"

    /// UserDefaults key for the user's preferred daily digest minute (0-59).
    static let digestMinuteKey = "digestMinute"

    /// UserDefaults key toggling whether the daily digest is enabled.
    static let digestEnabledKey = "digestEnabled"

    /// UserDefaults key for the default category applied to new items.
    static let defaultCategoryKey = "defaultCategory"
}

//
//  NotificationService.swift
//  nudge
//
//  All local-notification scheduling lives here so the rest of the app never
//  touches UNUserNotificationCenter directly.
//

import Foundation
import UserNotifications

/// Isolates reminder + daily-digest scheduling behind a small async surface.
final class NotificationService: Sendable {

    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    // MARK: Authorization

    /// Requests alert/sound/badge permission. Returns whether it was granted.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Current authorization status, for the Settings screen.
    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: Per-item reminders

    /// Schedules (or reschedules) a one-off reminder for an item.
    /// Uses the item's UUID as the request identifier so it can be cancelled/updated.
    func scheduleReminder(for item: InboxItem) async {
        guard let date = item.reminderDate, date > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Nudge"
        content.body = item.title
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: item.id.uuidString,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    /// Cancels a previously-scheduled item reminder.
    func cancelReminder(for id: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }

    // MARK: Daily digest

    /// Schedules a repeating daily notification at the given hour/minute.
    /// `forgottenCount` seeds the message; the app refreshes it on each launch.
    func scheduleDailyDigest(hour: Int, minute: Int, forgottenCount: Int) async {
        cancelDailyDigest()

        let content = UNMutableNotificationContent()
        content.title = "Your Nudge digest"
        content.body = forgottenCount > 0
            ? "You have \(forgottenCount) thing\(forgottenCount == 1 ? "" : "s") waiting. Take a look?"
            : "A calm moment to review what you saved."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: AppConstants.dailyDigestNotificationID,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    /// Removes the repeating daily digest notification.
    func cancelDailyDigest() {
        center.removePendingNotificationRequests(
            withIdentifiers: [AppConstants.dailyDigestNotificationID]
        )
    }
}

//
//  SettingsViewModel.swift
//  nudge
//
//  Notification/digest scheduling and status for the Settings screen.
//

import Foundation
import UserNotifications

@MainActor
@Observable
final class SettingsViewModel {

    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    func refreshStatus() async {
        authorizationStatus = await NotificationService.shared.authorizationStatus()
    }

    func requestAuthorization() async {
        await NotificationService.shared.requestAuthorization()
        await refreshStatus()
    }

    /// Applies the current digest preferences to the scheduled notification.
    func applyDigestSchedule(enabled: Bool, hour: Int, minute: Int, forgottenCount: Int) async {
        if enabled {
            await NotificationService.shared.scheduleDailyDigest(
                hour: hour,
                minute: minute,
                forgottenCount: forgottenCount
            )
        } else {
            NotificationService.shared.cancelDailyDigest()
        }
    }
}

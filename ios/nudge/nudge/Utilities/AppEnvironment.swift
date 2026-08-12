//
//  AppEnvironment.swift
//  nudge
//
//  Dependency container injected through the SwiftUI environment so views/view
//  models depend on protocols, not concrete services. Swapping in a real AWS
//  APIClient later means changing one line here.
//

import SwiftUI

/// Holds the app's service dependencies behind their protocols.
@MainActor
@Observable
final class AppEnvironment {
    let apiClient: APIClient
    let classifier: ClassificationService
    let notifications: NotificationService

    init(
        apiClient: APIClient = MockAPIClient(),
        classifier: ClassificationService = MockClassificationService(),
        notifications: NotificationService = .shared
    ) {
        self.apiClient = apiClient
        self.classifier = classifier
        self.notifications = notifications
    }
}

extension EnvironmentValues {
    /// Access the app environment via `@Environment(\.appEnvironment)`.
    @Entry var appEnvironment: AppEnvironment = AppEnvironment()
}

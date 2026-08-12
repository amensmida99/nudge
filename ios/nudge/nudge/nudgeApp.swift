//
//  nudgeApp.swift
//  nudge
//
//  App entry point: sets up the SwiftData container and the dependency
//  environment, and imports Share-Extension captures when the app activates.
//

import SwiftUI
import SwiftData

@main
struct nudgeApp: App {

    /// The single SwiftData container for the app's local, offline-first store.
    let modelContainer: ModelContainer

    /// Shared service dependencies (mock implementations for now).
    @State private var environment = AppEnvironment()

    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            modelContainer = try ModelContainer(
                for: InboxItem.self, DailyDigest.self
            )
        } catch {
            fatalError("Failed to create the SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appEnvironment, environment)
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            // When the app becomes active, pull in anything shared via the
            // Share Extension while we were backgrounded.
            if newPhase == .active {
                ShareImportService.importPending(into: modelContainer.mainContext)
            }
        }
    }
}

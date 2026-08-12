//
//  MainTabView.swift
//  nudge
//
//  The primary tab bar: Today, Inbox, Forgotten, Settings.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "sun.max") {
                TodayView()
            }

            Tab("Inbox", systemImage: "tray.full") {
                InboxView()
            }

            Tab("Forgotten", systemImage: "clock.arrow.circlepath") {
                ForgottenView()
            }

            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(SampleData.previewContainer)
}

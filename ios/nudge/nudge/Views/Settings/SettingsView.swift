//
//  SettingsView.swift
//  nudge
//
//  Notification preferences, daily digest time, category defaults, privacy, and
//  data export placeholders.
//

import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Environment(\.openURL) private var openURL

    @Query private var allItems: [InboxItem]

    @AppStorage(AppConstants.digestEnabledKey) private var digestEnabled = true
    @AppStorage(AppConstants.digestHourKey) private var digestHour = 9
    @AppStorage(AppConstants.digestMinuteKey) private var digestMinute = 0
    @AppStorage(AppConstants.defaultCategoryKey) private var defaultCategoryRaw = ItemType.other.rawValue

    @State private var viewModel = SettingsViewModel()

    /// Convenience binding to edit the digest time as a single `Date`.
    private var digestTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: digestHour, minute: digestMinute, second: 0, of: .now
                ) ?? .now
            },
            set: { newValue in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                digestHour = comps.hour ?? 9
                digestMinute = comps.minute ?? 0
            }
        )
    }

    private var forgottenCount: Int {
        ItemRanker.forgottenItems(from: allItems).count
    }

    var body: some View {
        NavigationStack {
            Form {
                notificationsSection
                digestSection
                defaultsSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .task { await viewModel.refreshStatus() }
            .onChange(of: digestEnabled) { _, _ in applyDigest() }
            .onChange(of: digestHour) { _, _ in applyDigest() }
            .onChange(of: digestMinute) { _, _ in applyDigest() }
        }
    }

    // MARK: Sections

    private var notificationsSection: some View {
        Section {
            HStack {
                Label("Notifications", systemImage: "bell")
                Spacer()
                Text(statusText)
                    .foregroundStyle(.secondary)
            }

            if !viewModel.isAuthorized {
                if viewModel.authorizationStatus == .denied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                } else {
                    Button("Enable Notifications") {
                        Task { await viewModel.requestAuthorization() }
                    }
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Nudge uses notifications for reminders and your daily digest.")
        }
    }

    private var digestSection: some View {
        Section {
            Toggle("Daily digest", isOn: $digestEnabled)
            if digestEnabled {
                DatePicker(
                    "Time",
                    selection: digestTime,
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text("Daily Digest")
        } footer: {
            Text("A gentle once-a-day summary of things you may have forgotten.")
        }
    }

    private var defaultsSection: some View {
        Section("Category Defaults") {
            Picker("Default category", selection: $defaultCategoryRaw) {
                ForEach(ItemType.allCases) { type in
                    Label(type.label, systemImage: type.symbol).tag(type.rawValue)
                }
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            // Placeholder — a future build will export items to a file.
            Button {
                // Intentionally left as a placeholder for data export.
            } label: {
                Label("Export data", systemImage: "square.and.arrow.up")
            }
            .disabled(true)
        }
    }

    private var aboutSection: some View {
        Section {
            NavigationLink {
                privacyPlaceholder
            } label: {
                Label("Privacy", systemImage: "hand.raised")
            }
            LabeledContent("Version", value: "1.0")
        } header: {
            Text("About")
        }
    }

    private var privacyPlaceholder: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your privacy")
                    .font(.title2.weight(.bold))
                Text("Nudge stores everything you save locally on your device using SwiftData. Nothing is uploaded to a server in this version.\n\nThis is placeholder copy. A full privacy policy will appear here in a future release.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Helpers

    private var statusText: String {
        switch viewModel.authorizationStatus {
        case .authorized, .provisional: return "On"
        case .denied: return "Off"
        case .notDetermined: return "Not set"
        case .ephemeral: return "Limited"
        @unknown default: return "Unknown"
        }
    }

    private func applyDigest() {
        Task {
            await viewModel.applyDigestSchedule(
                enabled: digestEnabled,
                hour: digestHour,
                minute: digestMinute,
                forgottenCount: forgottenCount
            )
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(SampleData.previewContainer)
}

//
//  OnboardingView.swift
//  nudge
//
//  First-run flow: value proposition, notification permission, and Share Sheet tip.
//

import SwiftUI

struct OnboardingView: View {
    /// Called when the user finishes onboarding.
    let onFinished: () -> Void

    @Environment(\.appEnvironment) private var env
    @State private var page = 0

    var body: some View {
        VStack {
            TabView(selection: $page) {
                welcomePage.tag(0)
                notificationsPage.tag(1)
                shareSheetPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: page)

            controls
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: Pages

    private var welcomePage: some View {
        OnboardingPage(
            symbol: "tray.and.arrow.down.fill",
            title: "Save anything.\nDeal with it when it matters.",
            message: "Links, notes, screenshots, ideas — capture them now and let Nudge resurface them at the right time."
        )
    }

    private var notificationsPage: some View {
        OnboardingPage(
            symbol: "bell.badge.fill",
            title: "Gentle, timely nudges",
            message: "Allow notifications so Nudge can quietly remind you about reminders and your daily digest.",
            actionTitle: "Enable Notifications"
        ) {
            await env.notifications.requestAuthorization()
            page = 2
        }
    }

    private var shareSheetPage: some View {
        OnboardingPage(
            symbol: "square.and.arrow.up",
            title: "Save from anywhere",
            message: "In Safari, Photos, or any app, tap the Share button and choose Nudge. If you don't see it, tap “More”, then turn on Nudge and drag it to the top."
        )
    }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 12) {
            if page < 2 {
                Button {
                    withAnimation { page += 1 }
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Skip", action: onFinished)
                    .font(.subheadline)
            } else {
                Button(action: onFinished) {
                    Text("Get Started")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}

/// A single reusable onboarding panel.
private struct OnboardingPage: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() async -> Void)? = nil

    @State private var isWorking = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: symbol)
                .font(.system(size: 72))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text(title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                Button {
                    Task {
                        isWorking = true
                        await action()
                        isWorking = false
                    }
                } label: {
                    if isWorking {
                        ProgressView()
                    } else {
                        Text(actionTitle)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(isWorking)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    OnboardingView(onFinished: {})
}

//
//  RootView.swift
//  nudge
//
//  Chooses between onboarding and the main tab interface.
//

import SwiftUI
import SwiftData

/// Top-level view that gates the app behind first-run onboarding.
struct RootView: View {
    @AppStorage(AppConstants.hasCompletedOnboardingKey) private var hasOnboarded = false

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView {
                    withAnimation { hasOnboarded = true }
                }
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(SampleData.previewContainer)
}

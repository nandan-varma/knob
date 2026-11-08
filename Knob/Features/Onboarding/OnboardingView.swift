import AppKit
import SwiftUI

struct OnboardingView: View {
    @Binding var onboardingComplete: Bool
    @State private var isActivating = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("Welcome to Knob")
                .font(.title)
                .bold()

            Text("Knob blocks distracting apps during focus sessions.")
                .foregroundStyle(.secondary)

            if FeatureFlags.websiteBlockingEnabled {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                }

                Button {
                    activate()
                } label: {
                    if isActivating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Enable Website Blocking")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isActivating)

                Button("Skip for now (app blocking only)") {
                    onboardingComplete = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            } else {
                Button("Get Started") {
                    onboardingComplete = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func activate() {
        isActivating = true
        errorMessage = nil
        Task {
            do {
                try await WebFilterController.shared.setUp()
                onboardingComplete = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isActivating = false
        }
    }
}

struct OnboardingMenuPrompt: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Knob needs setup")
                .font(.headline)
            Text("Open Knob to finish onboarding.")
                .foregroundStyle(.secondary)
            Button("Open Knob") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main")
            }
        }
        .padding()
    }
}

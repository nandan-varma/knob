import AppKit
import SwiftUI
import SwiftData

struct MenuBarContentView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @Query(sort: \BlockProfile.name) private var profiles: [BlockProfile]
    @Environment(\.openWindow) private var openWindow

    @State private var selectedProfileID: UUID?
    @State private var strictMode = false

    private let durations: [(String, TimeInterval)] = [
        ("25 min", 25 * 60),
        ("50 min", 50 * 60),
        ("90 min", 90 * 60),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if sessionManager.activeQuickSession != nil {
                activeSessionView
            } else if !sessionManager.activeScheduleIDs.isEmpty {
                scheduleActiveView
            } else {
                startSessionView
            }

            Divider()

            HStack {
                Button("Open Knob") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "main")
                }
                Spacer()
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding(16)
        .frame(width: 280)
        .onAppear {
            if selectedProfileID == nil {
                selectedProfileID = profiles.first?.id
            }
        }
    }

    private var startSessionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Start a focus session")
                .font(.headline)

            if profiles.isEmpty {
                Text("Create a block profile in Knob first.")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Profile", selection: $selectedProfileID) {
                    ForEach(profiles) { profile in
                        Text(profile.name).tag(Optional(profile.id))
                    }
                }
                .labelsHidden()

                Toggle("Strict mode", isOn: $strictMode)

                ForEach(durations, id: \.0) { label, duration in
                    Button(label) {
                        start(duration: duration)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var activeSessionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Focus session active")
                .font(.headline)
            Text(remainingText)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .monospacedDigit()

            if sessionManager.isStrictModeActive {
                StrictUnlockButton {
                    sessionManager.endQuickSession(early: true)
                }
            } else {
                Button("End Session") {
                    sessionManager.endQuickSession(early: true)
                }
            }
        }
    }

    private var scheduleActiveView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Scheduled block active")
                .font(.headline)
            Text("Managed by a recurring schedule.")
                .foregroundStyle(.secondary)
        }
    }

    private var remainingText: String {
        let remaining = Int(sessionManager.quickSessionRemaining)
        return String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    private func start(duration: TimeInterval) {
        guard let id = selectedProfileID, let profile = profiles.first(where: { $0.id == id }) else { return }
        sessionManager.startQuickSession(profile: profile, duration: duration, strictMode: strictMode)
    }
}

struct StrictUnlockButton: View {
    let action: () -> Void
    @State private var isHolding = false

    var body: some View {
        Button {
            // no-op; unlock happens via the long-press gesture below
        } label: {
            Text(isHolding ? "Hold to end…" : "Hold to End Session")
                .frame(maxWidth: .infinity)
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 1.5)
                .onChanged { _ in isHolding = true }
                .onEnded { _ in
                    isHolding = false
                    action()
                }
        )
    }
}

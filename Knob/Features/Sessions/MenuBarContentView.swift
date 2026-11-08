import AppKit
import SwiftUI
import SwiftData

struct MenuBarContentView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @Query(sort: \BlockProfile.name) private var profiles: [BlockProfile]
    @Environment(\.openWindow) private var openWindow

    @State private var selectedProfileID: UUID?
    @State private var strictMode = false

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
        .frame(width: 260)
        .onAppear {
            if selectedProfileID == nil {
                selectedProfileID = profiles.first?.id
            }
        }
    }

    private var startSessionView: some View {
        VStack(alignment: .leading, spacing: 10) {
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

                Button("Start Focus") {
                    start()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var activeSessionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Focused for")
                .foregroundStyle(.secondary)
            Text(elapsedText)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .monospacedDigit()

            if sessionManager.isStrictModeActive {
                StrictUnlockButton {
                    sessionManager.endQuickSession()
                }
            } else {
                Button("End Session") {
                    sessionManager.endQuickSession()
                }
                .frame(maxWidth: .infinity)
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

    private var elapsedText: String {
        let elapsed = Int(sessionManager.quickSessionElapsed)
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        let seconds = elapsed % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%d:%02d", minutes, seconds)
    }

    private func start() {
        guard let id = selectedProfileID, let profile = profiles.first(where: { $0.id == id }) else { return }
        sessionManager.startQuickSession(profile: profile, strictMode: strictMode)
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

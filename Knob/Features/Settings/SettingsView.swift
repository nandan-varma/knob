import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var notificationsEnabled = NotificationManager.enabled
    @State private var filterStatusMessage: String?

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch Knob at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin, toggleLaunchAtLogin)

                Toggle("Session notifications", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        NotificationManager.enabled = newValue
                        if newValue {
                            NotificationManager.requestAuthorization()
                        }
                    }
            }

            Section("Website Filter") {
                Button("Re-check Website Filter Setup") {
                    Task {
                        do {
                            try await WebFilterController.shared.setUp()
                            filterStatusMessage = "Website filter is enabled."
                        } catch {
                            filterStatusMessage = error.localizedDescription
                        }
                    }
                }
                if let filterStatusMessage {
                    Text(filterStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func toggleLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

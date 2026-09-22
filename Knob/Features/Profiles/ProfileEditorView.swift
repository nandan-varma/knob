import SwiftUI

struct ProfileEditorView: View {
    @Bindable var profile: BlockProfile
    @State private var showingAppPicker = false
    @State private var selectedBundleIDs: Set<String> = []
    @State private var appNames: [String: String] = [:]

    var body: some View {
        Form {
            Section("Name") {
                TextField("Profile name", text: $profile.name)
            }

            Section("Blocked Apps") {
                if profile.blockedBundleIdentifiers.isEmpty {
                    Text("No apps blocked").foregroundStyle(.secondary)
                } else {
                    ForEach(profile.blockedBundleIdentifiers, id: \.self) { bundleID in
                        Text(appNames[bundleID] ?? bundleID)
                    }
                }
                Button("Choose Apps…") {
                    selectedBundleIDs = Set(profile.blockedBundleIdentifiers)
                    showingAppPicker = true
                }
            }

            Section("Blocked Websites") {
                DomainListEditor(domains: $profile.blockedDomains)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(minWidth: 420, minHeight: 420)
        .sheet(isPresented: $showingAppPicker, onDismiss: applyAppSelection) {
            AppPickerView(selectedBundleIDs: $selectedBundleIDs)
        }
        .task {
            let apps = InstalledAppsFinder.scan()
            appNames = Dictionary(uniqueKeysWithValues: apps.map { ($0.bundleIdentifier, $0.name) })
        }
    }

    private func applyAppSelection() {
        profile.blockedBundleIdentifiers = Array(selectedBundleIDs)
    }
}

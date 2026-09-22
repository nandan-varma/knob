import SwiftUI

struct AppPickerView: View {
    @Binding var selectedBundleIDs: Set<String>
    @Environment(\.dismiss) private var dismiss

    @State private var apps: [InstalledApp] = []
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Choose Apps to Block")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding()

            TextField("Search", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.bottom, 8)

            List(filteredApps) { app in
                Button {
                    toggle(app)
                } label: {
                    HStack {
                        Image(nsImage: app.icon)
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text(app.name)
                        Spacer()
                        if selectedBundleIDs.contains(app.bundleIdentifier) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 420, height: 480)
        .task {
            apps = InstalledAppsFinder.scan()
        }
    }

    private var filteredApps: [InstalledApp] {
        guard !searchText.isEmpty else { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func toggle(_ app: InstalledApp) {
        if selectedBundleIDs.contains(app.bundleIdentifier) {
            selectedBundleIDs.remove(app.bundleIdentifier)
        } else {
            selectedBundleIDs.insert(app.bundleIdentifier)
        }
    }
}

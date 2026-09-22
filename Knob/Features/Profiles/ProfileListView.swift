import SwiftUI
import SwiftData

struct ProfileListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BlockProfile.name) private var profiles: [BlockProfile]
    @State private var selection: BlockProfile?

    var body: some View {
        NavigationSplitView {
            List(profiles, selection: $selection) { profile in
                VStack(alignment: .leading) {
                    Text(profile.name).font(.headline)
                    Text("\(profile.blockedBundleIdentifiers.count) apps, \(profile.blockedDomains.count) sites")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(profile)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: addProfile) {
                        Label("Add Profile", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selection {
                ProfileEditorView(profile: selection)
            } else {
                Text("Select or create a profile")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func addProfile() {
        let profile = BlockProfile(name: "New Profile")
        modelContext.insert(profile)
        selection = profile
    }
}

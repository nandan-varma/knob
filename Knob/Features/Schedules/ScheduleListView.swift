import SwiftUI
import SwiftData

struct ScheduleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BlockSchedule.name) private var schedules: [BlockSchedule]
    @Query(sort: \BlockProfile.name) private var profiles: [BlockProfile]
    @State private var selection: BlockSchedule?

    var body: some View {
        NavigationSplitView {
            List(schedules, selection: $selection) { schedule in
                VStack(alignment: .leading) {
                    Text(schedule.name).font(.headline)
                    Text(summary(for: schedule))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(schedule)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: addSchedule) {
                        Label("Add Schedule", systemImage: "plus")
                    }
                    .disabled(profiles.isEmpty)
                }
            }
        } detail: {
            if let selection {
                ScheduleEditorView(schedule: selection)
            } else if profiles.isEmpty {
                Text("Create a block profile first").foregroundStyle(.secondary)
            } else {
                Text("Select or create a schedule").foregroundStyle(.secondary)
            }
        }
    }

    private func summary(for schedule: BlockSchedule) -> String {
        let time = String(format: "%02d:%02d–%02d:%02d", schedule.startHour, schedule.startMinute, schedule.endHour, schedule.endMinute)
        return schedule.isEnabled ? time : "\(time) (disabled)"
    }

    private func addSchedule() {
        guard let profile = profiles.first else { return }
        let schedule = BlockSchedule(
            name: "New Schedule",
            profileID: profile.id,
            weekdays: [2, 3, 4, 5, 6],
            startHour: 9,
            startMinute: 0,
            endHour: 17,
            endMinute: 0
        )
        modelContext.insert(schedule)
        selection = schedule
    }
}

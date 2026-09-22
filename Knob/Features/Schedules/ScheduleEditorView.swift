import SwiftUI
import SwiftData

struct ScheduleEditorView: View {
    @Bindable var schedule: BlockSchedule
    @Query(sort: \BlockProfile.name) private var profiles: [BlockProfile]
    @EnvironmentObject private var sessionManager: SessionManager

    private let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        Form {
            Section("Name") {
                TextField("Schedule name", text: $schedule.name)
                Toggle("Enabled", isOn: $schedule.isEnabled)
            }

            Section("Profile") {
                Picker("Block profile", selection: $schedule.profileID) {
                    ForEach(profiles) { profile in
                        Text(profile.name).tag(profile.id)
                    }
                }
            }

            Section("Days") {
                HStack {
                    ForEach(1...7, id: \.self) { weekday in
                        dayToggle(weekday)
                    }
                }
            }

            Section("Time Window") {
                DatePicker(
                    "Start",
                    selection: timeBinding(hour: $schedule.startHour, minute: $schedule.startMinute),
                    displayedComponents: .hourAndMinute
                )
                DatePicker(
                    "End",
                    selection: timeBinding(hour: $schedule.endHour, minute: $schedule.endMinute),
                    displayedComponents: .hourAndMinute
                )
            }

            Section("Strict Mode") {
                Toggle("No early unlock", isOn: $schedule.strictMode)
            }

            if sessionManager.isScheduleActive(schedule) {
                Section {
                    Label("Currently active", systemImage: "shield.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(minWidth: 420, minHeight: 420)
    }

    private func dayToggle(_ weekday: Int) -> some View {
        let isOn = schedule.weekdays.contains(weekday)
        return Button {
            if isOn {
                schedule.weekdays.removeAll { $0 == weekday }
            } else {
                schedule.weekdays.append(weekday)
            }
        } label: {
            Text(weekdaySymbols[weekday - 1])
                .frame(width: 36, height: 28)
                .background(isOn ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundStyle(isOn ? Color.white : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private func timeBinding(hour: Binding<Int>, minute: Binding<Int>) -> Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: hour.wrappedValue, minute: minute.wrappedValue)) ?? .now
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                hour.wrappedValue = components.hour ?? 0
                minute.wrappedValue = components.minute ?? 0
            }
        )
    }
}

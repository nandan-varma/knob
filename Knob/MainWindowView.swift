import SwiftUI

struct MainWindowView: View {
    var body: some View {
        TabView {
            Tab("Profiles", systemImage: "shield") {
                ProfileListView()
            }
            Tab("Schedules", systemImage: "calendar") {
                ScheduleListView()
            }
            Tab("Stats", systemImage: "chart.bar") {
                StatsView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var sessions: [FocusSession]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                summaryCards

                if !dailyFocusMinutes.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Focused Time (Last 14 Days)")
                            .font(.headline)
                        Chart(dailyFocusMinutes, id: \.day) { entry in
                            BarMark(
                                x: .value("Day", entry.day, unit: .day),
                                y: .value("Minutes", entry.minutes)
                            )
                        }
                        .frame(height: 200)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Sessions")
                        .font(.headline)
                    ForEach(sessions.prefix(20)) { session in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                                Text(session.kind == FocusSessionKind.scheduled.rawValue ? "Scheduled" : "Quick session")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if session.blockedAttemptCount > 0 {
                                Text("\(session.blockedAttemptCount) blocked")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        Divider()
                    }
                }
            }
            .padding()
        }
    }

    private var completedSessions: [FocusSession] {
        sessions.filter { $0.endedAt != nil }
    }

    private var summaryCards: some View {
        HStack(spacing: 16) {
            StatCard(title: "Total Focus Time", value: formattedDuration(totalFocusSeconds))
            StatCard(title: "Sessions", value: "\(sessions.count)")
            StatCard(title: "Blocked Attempts", value: "\(totalBlockedAttempts)")
        }
    }

    private var totalFocusSeconds: TimeInterval {
        completedSessions.reduce(0) { total, session in
            total + (session.endedAt ?? session.startedAt).timeIntervalSince(session.startedAt)
        }
    }

    private var totalBlockedAttempts: Int {
        sessions.reduce(0) { $0 + $1.blockedAttemptCount }
    }

    private var dailyFocusMinutes: [(day: Date, minutes: Double)] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -14, to: .now) ?? .now
        var totals: [Date: Double] = [:]

        for session in completedSessions where session.startedAt >= cutoff {
            let day = calendar.startOfDay(for: session.startedAt)
            let duration = (session.endedAt ?? session.startedAt).timeIntervalSince(session.startedAt)
            totals[day, default: 0] += duration / 60
        }

        return totals.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

private struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
    }
}

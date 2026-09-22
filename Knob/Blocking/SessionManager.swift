import AppKit
import Foundation
import SwiftData

@MainActor
final class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published private(set) var activeQuickSession: FocusSession?
    @Published private(set) var activeScheduleIDs: Set<UUID> = []
    @Published private(set) var quickSessionRemaining: TimeInterval = 0

    private var modelContext: ModelContext!
    private var quickSessionTimer: Timer?
    private var countdownTimer: Timer?
    private var scheduleTimer: Timer?

    private init() {}

    func configure(modelContext: ModelContext) {
        guard self.modelContext == nil else { return }
        self.modelContext = modelContext

        AppBlocker.shared.onBlockedAttempt = { [weak self] in
            Task { @MainActor in self?.recordBlockedAttempt() }
        }

        scheduleTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.evaluateSchedulesNow() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.evaluateSchedulesNow() }
        }
        evaluateSchedulesNow()
    }

    var isEnforcing: Bool {
        activeQuickSession != nil || !activeScheduleIDs.isEmpty
    }

    var isStrictModeActive: Bool {
        if activeQuickSession?.strictMode == true { return true }
        let schedules = allSchedules()
        return schedules.contains { activeScheduleIDs.contains($0.id) && $0.strictMode }
    }

    // MARK: - Quick sessions

    func startQuickSession(profile: BlockProfile, duration: TimeInterval, strictMode: Bool) {
        guard activeQuickSession == nil else { return }

        let session = FocusSession(
            profileID: profile.id,
            scheduleID: nil,
            kind: .quick,
            startedAt: .now,
            plannedEndAt: .now.addingTimeInterval(duration),
            strictMode: strictMode
        )
        modelContext.insert(session)
        try? modelContext.save()
        activeQuickSession = session
        quickSessionRemaining = duration
        reapplyEnforcement()
        NotificationManager.post(title: "Focus session started", body: "Blocking \(profile.name) for \(Int(duration / 60)) minutes.")

        quickSessionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.endQuickSession(early: false) }
        }
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickCountdown() }
        }
    }

    func endQuickSession(early: Bool) {
        guard let session = activeQuickSession else { return }
        session.endedAt = .now
        session.endedEarly = early
        try? modelContext.save()

        quickSessionTimer?.invalidate()
        quickSessionTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        quickSessionRemaining = 0
        activeQuickSession = nil
        reapplyEnforcement()
        NotificationManager.post(
            title: early ? "Focus session ended early" : "Focus session complete",
            body: early ? "You ended the session before time was up." : "Nice work — the session finished."
        )
    }

    private func tickCountdown() {
        guard let session = activeQuickSession else { return }
        quickSessionRemaining = max(0, session.plannedEndAt.timeIntervalSinceNow)
    }

    private func recordBlockedAttempt() {
        activeQuickSession?.blockedAttemptCount += 1
        try? modelContext.save()
    }

    // MARK: - Schedules

    private func evaluateSchedulesNow() {
        let schedules = allSchedules()
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let minutesNow = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        var newActive: Set<UUID> = []
        for schedule in schedules where schedule.isEnabled {
            guard schedule.weekdays.contains(weekday) else { continue }
            let startMinutes = schedule.startHour * 60 + schedule.startMinute
            let endMinutes = schedule.endHour * 60 + schedule.endMinute
            let inWindow = startMinutes <= endMinutes
                ? (minutesNow >= startMinutes && minutesNow < endMinutes)
                : (minutesNow >= startMinutes || minutesNow < endMinutes)
            if inWindow {
                newActive.insert(schedule.id)
            }
        }

        guard newActive != activeScheduleIDs else { return }
        activeScheduleIDs = newActive
        reapplyEnforcement()
    }

    func isScheduleActive(_ schedule: BlockSchedule) -> Bool {
        activeScheduleIDs.contains(schedule.id)
    }

    // MARK: - Enforcement

    private func reapplyEnforcement() {
        var profileIDs: Set<UUID> = []
        if let session = activeQuickSession { profileIDs.insert(session.profileID) }
        for schedule in allSchedules() where activeScheduleIDs.contains(schedule.id) {
            profileIDs.insert(schedule.profileID)
        }

        guard !profileIDs.isEmpty else {
            AppBlocker.shared.stop()
            ActiveBlockList.domains = []
            return
        }

        let activeProfiles = allProfiles().filter { profileIDs.contains($0.id) }
        let bundleIDs = Set(activeProfiles.flatMap(\.blockedBundleIdentifiers))
        let domains = Set(activeProfiles.flatMap(\.blockedDomains))

        AppBlocker.shared.start(blocking: bundleIDs)
        ActiveBlockList.domains = domains
    }

    private func allSchedules() -> [BlockSchedule] {
        (try? modelContext.fetch(FetchDescriptor<BlockSchedule>())) ?? []
    }

    private func allProfiles() -> [BlockProfile] {
        (try? modelContext.fetch(FetchDescriptor<BlockProfile>())) ?? []
    }
}

import AppKit
import Foundation

/// Blocks apps by watching for their launch and terminating them. There's no OS-level
/// app shield on macOS (unlike iOS's Family Controls), so this only works while Knob
/// itself is running — see the strict-mode UI, which discourages quitting Knob during
/// a session rather than relying on an unkillable background mechanism.
@MainActor
final class AppBlocker: NSObject {
    static let shared = AppBlocker()

    private var blockedBundleIDs: Set<String> = []
    private var isObserving = false
    var onBlockedAttempt: (() -> Void)?

    private override init() {}

    func start(blocking bundleIDs: Set<String>) {
        blockedBundleIDs = bundleIDs
        terminateAlreadyRunningBlockedApps()

        guard !isObserving else { return }
        isObserving = true
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
    }

    func stop() {
        if isObserving {
            NSWorkspace.shared.notificationCenter.removeObserver(
                self, name: NSWorkspace.didLaunchApplicationNotification, object: nil
            )
        }
        isObserving = false
        blockedBundleIDs = []
    }

    private func terminateAlreadyRunningBlockedApps() {
        for app in NSWorkspace.shared.runningApplications {
            guard let bundleID = app.bundleIdentifier, blockedBundleIDs.contains(bundleID) else { continue }
            terminate(app)
        }
    }

    @objc private func appDidLaunch(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier,
              blockedBundleIDs.contains(bundleID)
        else { return }

        terminate(app)
        onBlockedAttempt?()
    }

    private func terminate(_ app: NSRunningApplication) {
        app.terminate()
        // Some apps ignore a polite terminate request; force it if it's still around shortly after.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if !app.isTerminated {
                app.forceTerminate()
            }
        }
    }
}

import SwiftUI

struct MenuBarLabel: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        if sessionManager.isEnforcing {
            Label(countdownText, systemImage: "shield.fill")
        } else {
            Image(systemName: "shield")
        }
    }

    private var countdownText: String {
        guard sessionManager.activeQuickSession != nil else { return "Blocking" }
        let elapsed = Int(sessionManager.quickSessionElapsed)
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

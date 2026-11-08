import Foundation
import SwiftData

enum FocusSessionKind: String, Codable {
    case quick
    case scheduled
}

@Model
final class FocusSession {
    var id: UUID
    var profileID: UUID
    var scheduleID: UUID?
    var kind: String
    var startedAt: Date
    var endedAt: Date?
    var strictMode: Bool
    var blockedAttemptCount: Int

    init(
        profileID: UUID,
        scheduleID: UUID?,
        kind: FocusSessionKind,
        startedAt: Date,
        strictMode: Bool
    ) {
        self.id = UUID()
        self.profileID = profileID
        self.scheduleID = scheduleID
        self.kind = kind.rawValue
        self.startedAt = startedAt
        self.strictMode = strictMode
        self.blockedAttemptCount = 0
    }
}

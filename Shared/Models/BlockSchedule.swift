import Foundation
import SwiftData

@Model
final class BlockSchedule {
    var id: UUID
    var name: String
    var profileID: UUID
    /// Calendar.Component.weekday values: 1 = Sunday ... 7 = Saturday.
    var weekdays: [Int]
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var isEnabled: Bool
    var strictMode: Bool

    init(
        name: String,
        profileID: UUID,
        weekdays: [Int],
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        strictMode: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.profileID = profileID
        self.weekdays = weekdays
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.isEnabled = true
        self.strictMode = strictMode
    }
}

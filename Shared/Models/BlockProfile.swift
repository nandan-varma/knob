import Foundation
import SwiftData

@Model
final class BlockProfile {
    var id: UUID
    var name: String
    var createdAt: Date
    var blockedBundleIdentifiers: [String]
    var blockedDomains: [String]

    init(name: String, blockedBundleIdentifiers: [String] = [], blockedDomains: [String] = []) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
        self.blockedBundleIdentifiers = blockedBundleIdentifiers
        self.blockedDomains = blockedDomains
    }
}

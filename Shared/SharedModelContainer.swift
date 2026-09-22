import Foundation
import SwiftData

enum SharedGroup {
    static let id = "group.com.nandanvarma.knob"

    static var containerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) else {
            fatalError("App Group container unavailable \u{2014} check the com.apple.security.application-groups entitlement")
        }
        return url
    }

    static var defaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: id) else {
            fatalError("App Group UserDefaults unavailable \u{2014} check the com.apple.security.application-groups entitlement")
        }
        return defaults
    }
}

enum SharedModelContainer {
    static func make() -> ModelContainer {
        let schema = Schema([BlockProfile.self, BlockSchedule.self, FocusSession.self])
        let storeURL = SharedGroup.containerURL.appendingPathComponent("Knob.sqlite")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create shared ModelContainer: \(error)")
        }
    }
}

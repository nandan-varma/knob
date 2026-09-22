import Foundation

/// The filter-data provider runs in a very restrictive sandbox, so instead of giving it
/// access to the full SwiftData store, the main app publishes just the currently-active
/// blocked domains here. The provider re-reads this on every flow decision.
enum ActiveBlockList {
    private static let domainsKey = "activeBlockedDomains"

    static var domains: Set<String> {
        get {
            let stored = SharedGroup.defaults.array(forKey: domainsKey) as? [String] ?? []
            return Set(stored)
        }
        set {
            SharedGroup.defaults.set(Array(newValue), forKey: domainsKey)
        }
    }
}

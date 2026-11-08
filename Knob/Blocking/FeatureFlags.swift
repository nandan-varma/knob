import Foundation

/// Website blocking needs an Apple-approved NetworkExtension entitlement that's still
/// pending for this team (see CLAUDE.md). Flip this once it's approved.
enum FeatureFlags {
    static let websiteBlockingEnabled = false
}

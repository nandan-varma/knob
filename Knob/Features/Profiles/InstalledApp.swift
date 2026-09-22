import AppKit
import Foundation

struct InstalledApp: Identifiable, Hashable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    let name: String
    let url: URL

    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
}

enum InstalledAppsFinder {
    private static let searchDirectories = [
        URL(fileURLWithPath: "/Applications"),
        URL(fileURLWithPath: "/System/Applications"),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
    ]

    static func scan() -> [InstalledApp] {
        var apps: [String: InstalledApp] = [:]

        for directory in searchDirectories {
            guard let entries = try? FileManager.default.contentsOfDirectory(
                at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
            ) else { continue }

            for entry in entries where entry.pathExtension == "app" {
                guard let bundle = Bundle(url: entry), let bundleID = bundle.bundleIdentifier else { continue }
                let name = FileManager.default.displayName(atPath: entry.path)
                    .replacingOccurrences(of: ".app", with: "")
                apps[bundleID] = InstalledApp(bundleIdentifier: bundleID, name: name, url: entry)
            }
        }

        return apps.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

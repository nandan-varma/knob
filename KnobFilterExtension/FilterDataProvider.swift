import Foundation
import NetworkExtension
import OSLog

/// Blocks flows to domains currently listed in the shared App Group's active block list.
/// Runs in a very restrictive sandbox (Apple's design, to keep it from exporting user
/// network content) — it only ever reads the shared domain list, never SwiftData.
final class FilterDataProvider: NEFilterDataProvider, @unchecked Sendable {
    private let log = Logger(subsystem: "com.nandanvarma.knob.filter", category: "FilterDataProvider")

    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        let settings = NEFilterSettings(rules: [], defaultAction: .filterData)
        apply(settings) { [weak self] error in
            if let error {
                self?.log.error("Failed to apply filter settings: \(error.localizedDescription)")
            }
            completionHandler(error)
        }
    }

    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        guard let host = hostname(for: flow), isBlocked(host: host) else {
            return .allow()
        }
        return .drop()
    }

    // These are only reached if handleNewFlow ever returns a data-peeking verdict, which
    // it doesn't — implemented anyway since NEFilterDataProvider documents them as required.
    override func handleInboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: Data) -> NEFilterDataVerdict {
        .allow()
    }

    override func handleOutboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: Data) -> NEFilterDataVerdict {
        .allow()
    }

    override func handleInboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
        .allow()
    }

    override func handleOutboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
        .allow()
    }

    private func hostname(for flow: NEFilterFlow) -> String? {
        if let socketFlow = flow as? NEFilterSocketFlow, let remoteHostname = socketFlow.remoteHostname {
            return remoteHostname
        }
        return flow.url?.host
    }

    private func isBlocked(host: String) -> Bool {
        let blocked = ActiveBlockList.domains
        guard !blocked.isEmpty else { return false }
        let lowered = host.lowercased()
        return blocked.contains { domain in
            lowered == domain || lowered.hasSuffix(".\(domain)")
        }
    }
}

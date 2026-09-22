import Foundation
import NetworkExtension
import SystemExtensions
import OSLog

/// Activates the KnobFilterExtension system extension and configures NEFilterManager once.
/// After that, blocking specific domains on/off is just a matter of writing to
/// `ActiveBlockList.domains` — the running extension reads that on every flow, so no
/// reconfiguration or restart is needed per session/schedule change.
@MainActor
final class WebFilterController: NSObject {
    static let shared = WebFilterController()

    static let extensionBundleID = "com.nandanvarma.knob.filter"

    private let log = Logger(subsystem: "com.nandanvarma.knob", category: "WebFilterController")
    private var activationContinuation: CheckedContinuation<Void, Error>?

    private override init() {}

    enum ActivationError: LocalizedError {
        case requestFailed(String)
        case needsUserApproval

        var errorDescription: String? {
            switch self {
            case .requestFailed(let message):
                return message
            case .needsUserApproval:
                return "Approve the Knob network extension in System Settings > General > Login Items & Extensions, then try again."
            }
        }
    }

    /// Activates the system extension (if needed) and enables the content filter.
    /// Safe to call every launch — it's a no-op once already active and enabled.
    func setUp() async throws {
        try await activateSystemExtension()
        try await enableFilter()
    }

    private func activateSystemExtension() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.activationContinuation = continuation
            let request = OSSystemExtensionRequest.activationRequest(
                forExtensionWithIdentifier: Self.extensionBundleID,
                queue: .main
            )
            request.delegate = self
            OSSystemExtensionManager.shared.submitRequest(request)
        }
    }

    private func enableFilter() async throws {
        let manager = NEFilterManager.shared()
        try await manager.loadFromPreferences()

        let configuration = NEFilterProviderConfiguration()
        configuration.filterSockets = true
        configuration.filterDataProviderBundleIdentifier = Self.extensionBundleID

        manager.providerConfiguration = configuration
        manager.localizedDescription = "Knob"
        manager.isEnabled = true

        try await manager.saveToPreferences()
    }
}

extension WebFilterController: OSSystemExtensionRequestDelegate {
    nonisolated func request(
        _ request: OSSystemExtensionRequest,
        didFinishWithResult result: OSSystemExtensionRequest.Result
    ) {
        Task { @MainActor in
            switch result {
            case .completed:
                self.activationContinuation?.resume()
            case .willCompleteAfterReboot:
                self.activationContinuation?.resume()
            @unknown default:
                self.activationContinuation?.resume()
            }
            self.activationContinuation = nil
        }
    }

    nonisolated func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        Task { @MainActor in
            self.activationContinuation?.resume(throwing: ActivationError.requestFailed(error.localizedDescription))
            self.activationContinuation = nil
        }
    }

    nonisolated func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        self.log.notice("System extension activation is pending user approval in System Settings.")
    }

    nonisolated func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension ext: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        .replace
    }
}

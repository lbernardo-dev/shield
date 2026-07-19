import Foundation
import MetricKit

nonisolated final class ShieldMetricSubscriber: NSObject, MXMetricManagerSubscriber, @unchecked Sendable {
    static let shared = ShieldMetricSubscriber()

    func subscribe() {
        MXMetricManager.shared.add(self)
    }

    func unsubscribe() {
        MXMetricManager.shared.remove(self)
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            try? MetricPayloadStore.persist(payload.jsonRepresentation(), kind: "metrics")
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            try? MetricPayloadStore.persist(payload.jsonRepresentation(), kind: "diagnostic")
        }
    }
}

nonisolated enum MetricPayloadStore {
    static let maximumPayloads = 20

    static func persist(
        _ data: Data,
        kind: String,
        directory: URL = defaultDirectory
    ) throws {
        guard !data.isEmpty else { return }
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
        let safeKind = kind.replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "", options: .regularExpression)
        let name = "\(Date().timeIntervalSince1970)-\(UUID().uuidString)-\(safeKind).json"
        let output = directory.appendingPathComponent(name)
        try data.write(to: output, options: [.atomic, .completeFileProtection])
        try rotate(directory: directory)
    }

    static func payloadURLs(in directory: URL = defaultDirectory) -> [URL] {
        ((try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? [])
        .filter { $0.pathExtension == "json" }
        .sorted { lhs, rhs in
            let left = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let right = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return left > right
        }
    }

    private static func rotate(directory: URL) throws {
        for expired in payloadURLs(in: directory).dropFirst(maximumPayloads) {
            try FileManager.default.removeItem(at: expired)
        }
    }

    private static var defaultDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Shield/MetricKit", isDirectory: true)
    }
}

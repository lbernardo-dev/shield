import Foundation
import Testing
@testable import Shield

@Suite("MetricKit local diagnostics", .serialized)
struct MetricPayloadStoreTests {
    @Test("Diagnostics are bounded and never uploaded by the store")
    func boundedPersistence() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("shield-metrics-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        for index in 0..<(MetricPayloadStore.maximumPayloads + 5) {
            try MetricPayloadStore.persist(Data("{\"sample\":\(index)}".utf8), kind: "diagnostic", directory: directory)
        }

        let files = MetricPayloadStore.payloadURLs(in: directory)
        #expect(files.count == MetricPayloadStore.maximumPayloads)
        #expect(files.allSatisfy { $0.pathExtension == "json" })
    }
}

import Foundation
import Testing
@testable import Shield

@Suite("Legacy usage history")
struct FreeQuotaTests {
    @Test("Processed-document history remains monotonic and is not a quota gate")
    @MainActor
    func processedDocumentHistoryRemainsMonotonic() async throws {
        let pm = PremiumManager.shared
        pm.resetFreeProcessedCountForTesting(to: 0)

        // Process 9 documents
        for _ in 0..<9 {
            pm.recordDocumentProcessed()
        }
        #expect(pm.freeDocumentsProcessedCount == 9)
        pm.recordDocumentProcessed()
        #expect(pm.freeDocumentsProcessedCount == 10)

        // Clean up
        pm.resetFreeProcessedCountForTesting(to: 0)
    }

    @Test("Existing library size still raises the retained usage watermark")
    @MainActor
    func legacyUsageSyncFromExistingDocuments() async throws {
        let pm = PremiumManager.shared
        pm.resetFreeProcessedCountForTesting(to: 0)

        // If user already has 5 existing documents, quota initializes to at least 5
        pm.syncProcessedDocumentCountIfNeeded(existingCount: 5)
        #expect(pm.freeDocumentsProcessedCount == 5)

        // Deleting documents (e.g. now has 2) does not reduce the migration evidence.
        pm.syncProcessedDocumentCountIfNeeded(existingCount: 2)
        #expect(pm.freeDocumentsProcessedCount == 5)

        // Clean up
        pm.resetFreeProcessedCountForTesting(to: 0)
    }
}

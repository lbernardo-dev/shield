import Foundation
import Testing
@testable import Shield

@Suite("Free Tier Document Quota")
struct FreeQuotaTests {
    @Test("Free tier documents limit enforcement and persistence")
    @MainActor
    func freeQuotaPersistenceAndLimits() async throws {
        let pm = PremiumManager.shared
        pm.resetFreeProcessedCountForTesting(to: 0)

        #expect(pm.canAddDocument(currentCount: 0) == true)
        #expect(pm.remainingFreeDocuments == 10)

        // Process 9 documents
        for _ in 0..<9 {
            pm.recordDocumentProcessed()
        }
        #expect(pm.freeDocumentsProcessedCount == 9)
        #expect(pm.remainingFreeDocuments == 1)
        #expect(pm.canAddDocument() == true)

        // Process 10th document (reaching free limit)
        pm.recordDocumentProcessed()
        #expect(pm.freeDocumentsProcessedCount == 10)
        #expect(pm.remainingFreeDocuments == 0)
        #expect(pm.canAddDocument() == false)

        // Simulating document deletion in library:
        // Even if library document count drops to 2, cumulative processed count stays at 10 and blocks adding
        #expect(pm.canAddDocument(currentCount: 2) == false)
        #expect(pm.remainingFreeDocuments == 0)

        // Pro override unblocks regardless of count
        pm.setDebugProOverride(true)
        #expect(pm.canAddDocument() == true)
        #expect(pm.canAddDocument(currentCount: 100) == true)

        // Reset pro override
        pm.setDebugProOverride(false)
        #expect(pm.canAddDocument() == false)

        // Clean up
        pm.resetFreeProcessedCountForTesting(to: 0)
    }

    @Test("Syncing existing library documents initializes quota correctly")
    @MainActor
    func quotaSyncFromExistingDocuments() async throws {
        let pm = PremiumManager.shared
        pm.resetFreeProcessedCountForTesting(to: 0)

        // If user already has 5 existing documents, quota initializes to at least 5
        pm.syncProcessedDocumentCountIfNeeded(existingCount: 5)
        #expect(pm.freeDocumentsProcessedCount == 5)
        #expect(pm.remainingFreeDocuments == 5)

        // Deleting documents (e.g. now has 2) does not reduce the processed count
        pm.syncProcessedDocumentCountIfNeeded(existingCount: 2)
        #expect(pm.freeDocumentsProcessedCount == 5)

        // Clean up
        pm.resetFreeProcessedCountForTesting(to: 0)
    }
}

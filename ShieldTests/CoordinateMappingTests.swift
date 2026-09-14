import CoreGraphics
import Foundation
import Testing
@testable import Shield

@Suite("Coordinate Mapping and Viewport Transformations")
struct CoordinateMappingTests {
    
    @Test("Canonical to viewport and back preserves points within floating-point tolerance")
    func pointRoundTrip() {
        let canvasSizes: [CGSize] = [
            CGSize(width: 393, height: 852),  // Compact iPhone
            CGSize(width: 402, height: 874),  // Duo outer cover
            CGSize(width: 816, height: 960),  // Duo inner open workspace
            CGSize(width: 320, height: 852),  // Split View narrow
            CGSize(width: 1024, height: 1366) // iPad Pro full screen
        ]
        
        let testPoints: [CGPoint] = [
            CGPoint(x: 0.0, y: 0.0),
            CGPoint(x: 0.5, y: 0.5),
            CGPoint(x: 0.1234, y: 0.8765),
            CGPoint(x: 1.0, y: 1.0)
        ]
        
        for size in canvasSizes {
            for canonicalPoint in testPoints {
                let viewportPoint = DocumentCoordinateTransform.canonicalToViewport(point: canonicalPoint, in: size)
                let recoveredCanonical = DocumentCoordinateTransform.viewportToCanonical(point: viewportPoint, in: size)
                
                #expect(abs(recoveredCanonical.x - canonicalPoint.x) < 1e-6)
                #expect(abs(recoveredCanonical.y - canonicalPoint.y) < 1e-6)
            }
        }
    }
    
    @Test("Canonical to viewport and back preserves rectangles within floating-point tolerance")
    func rectRoundTrip() {
        let canvasSizes: [CGSize] = [
            CGSize(width: 393, height: 852),
            CGSize(width: 402, height: 874),
            CGSize(width: 816, height: 960),
            CGSize(width: 320, height: 852),
            CGSize(width: 1024, height: 1366)
        ]
        
        let testRects: [CGRect] = [
            CGRect(x: 0.1, y: 0.2, width: 0.4, height: 0.15),
            CGRect(x: 0.0, y: 0.0, width: 0.5, height: 0.5),
            CGRect(x: 0.55, y: 0.65, width: 0.4, height: 0.3)
        ]
        
        for size in canvasSizes {
            for canonicalRect in testRects {
                let viewportRect = DocumentCoordinateTransform.canonicalToViewport(rect: canonicalRect, in: size)
                let recoveredCanonical = DocumentCoordinateTransform.viewportToCanonical(rect: viewportRect, in: size)
                
                #expect(abs(recoveredCanonical.origin.x - canonicalRect.origin.x) < 1e-6)
                #expect(abs(recoveredCanonical.origin.y - canonicalRect.origin.y) < 1e-6)
                #expect(abs(recoveredCanonical.width - canonicalRect.width) < 1e-6)
                #expect(abs(recoveredCanonical.height - canonicalRect.height) < 1e-6)
            }
        }
    }
    
    @Test("Clamping bounds invalid coordinates and prevents negative or overflowing rectangles")
    func clampingIntegrity() {
        let overflowing = CGRect(x: -0.5, y: -0.2, width: 2.0, height: 3.0)
        let clamped = DocumentCoordinateTransform.clampedCanonicalRect(overflowing)
        
        #expect(clamped.minX >= 0.0)
        #expect(clamped.minY >= 0.0)
        #expect(clamped.maxX <= 1.0)
        #expect(clamped.maxY <= 1.0)
        
        let nanRect = CGRect(x: CGFloat.nan, y: CGFloat.infinity, width: -1.0, height: CGFloat.nan)
        let safeRect = DocumentCoordinateTransform.clampedCanonicalRect(nanRect)
        #expect(safeRect.minX.isFinite)
        #expect(safeRect.minY.isFinite)
        #expect(safeRect.width >= 0.02)
        #expect(safeRect.height >= 0.02)
    }
    
    @Test("Content aspect fit correctly centers portrait and landscape content without clipping")
    func contentAspectFitCalculations() {
        let container = CGSize(width: 800, height: 600)
        
        // Landscape document (4:3 aspect ratio = 1.333)
        let landscapeRect = DocumentCoordinateTransform.contentAspectFitRect(
            in: container,
            contentAspect: 4.0 / 3.0,
            horizontalPadding: 0,
            verticalPadding: 0
        )
        #expect(abs(landscapeRect.width - 800) < 1e-3)
        #expect(abs(landscapeRect.height - 600) < 1e-3)
        #expect(abs(landscapeRect.origin.x) < 1e-3)
        #expect(abs(landscapeRect.origin.y) < 1e-3)
        
        // Portrait document (3:4 aspect ratio = 0.75)
        let portraitRect = DocumentCoordinateTransform.contentAspectFitRect(
            in: container,
            contentAspect: 3.0 / 4.0,
            horizontalPadding: 0,
            verticalPadding: 0
        )
        #expect(abs(portraitRect.height - 600) < 1e-3)
        #expect(abs(portraitRect.width - 450) < 1e-3)
        #expect(abs(portraitRect.origin.x - (800 - 450) / 2) < 1e-3)
        #expect(abs(portraitRect.origin.y) < 1e-3)
    }
    
    @Test("Golden Invariant: Redaction coordinates remain identical across continuous viewport transitions")
    func goldenInvariantAcrossResizeSequence() {
        // Redaction target: sensitive ID field at 15% x, 25% y, 35% width, 8% height
        let canonicalTarget = CGRect(x: 0.15, y: 0.25, width: 0.35, height: 0.08)
        let redaction = Redaction(rect: canonicalTarget, style: .secure)
        
        // Sequence of viewport transitions:
        // 1. Compact iPhone (closed)
        // 2. Unfolded Duo inner workspace
        // 3. Partially folded pose
        // 4. Split View narrow
        // 5. Split View wide
        // 6. Return to compact
        let viewportSequence: [CGSize] = [
            CGSize(width: 393, height: 852),
            CGSize(width: 816, height: 960),
            CGSize(width: 402, height: 480),
            CGSize(width: 320, height: 852),
            CGSize(width: 600, height: 852),
            CGSize(width: 393, height: 852)
        ]
        
        var currentCanonical = redaction.rect
        
        for (step, size) in viewportSequence.enumerated() {
            // Map canonical -> viewport
            let viewportRect = DocumentCoordinateTransform.canonicalToViewport(rect: currentCanonical, in: size)
            
            // Validate viewport rect is positive and non-zero
            #expect(viewportRect.width > 0, "Step \(step) width must be positive")
            #expect(viewportRect.height > 0, "Step \(step) height must be positive")
            
            // Map viewport -> canonical
            let recoveredCanonical = DocumentCoordinateTransform.viewportToCanonical(rect: viewportRect, in: size)
            
            // Canonical coordinates must be invariant
            #expect(abs(recoveredCanonical.origin.x - canonicalTarget.origin.x) < 1e-6, "Step \(step) x drifted")
            #expect(abs(recoveredCanonical.origin.y - canonicalTarget.origin.y) < 1e-6, "Step \(step) y drifted")
            #expect(abs(recoveredCanonical.width - canonicalTarget.width) < 1e-6, "Step \(step) width drifted")
            #expect(abs(recoveredCanonical.height - canonicalTarget.height) < 1e-6, "Step \(step) height drifted")
            
            currentCanonical = recoveredCanonical
        }
        
        // Final verification: export resolution (e.g. 3000 x 2000 original document image)
        let exportPageSize = CGSize(width: 3000, height: 2000)
        let exportRedactionRect = DocumentCoordinateTransform.canonicalToViewport(rect: currentCanonical, in: exportPageSize)
        
        #expect(abs(exportRedactionRect.origin.x - (0.15 * 3000)) < 1e-4)
        #expect(abs(exportRedactionRect.origin.y - (0.25 * 2000)) < 1e-4)
        #expect(abs(exportRedactionRect.width - (0.35 * 3000)) < 1e-4)
        #expect(abs(exportRedactionRect.height - (0.08 * 2000)) < 1e-4)
    }
    
    @Test("Preserves zoom focal point during container size transitions")
    func zoomFocalPointPreservation() {
        let oldContainer = CGSize(width: 393, height: 852)
        let newContainer = CGSize(width: 816, height: 960)
        let currentPan = CGSize(width: 50, height: -30)
        let zoomScale: CGFloat = 2.0
        
        let preservedPan = DocumentCoordinateTransform.preserveFocalPoint(
            oldSize: oldContainer,
            newSize: newContainer,
            currentPan: currentPan,
            effectiveZoom: zoomScale
        )
        
        // Pan offset scaled proportionately to container ratio
        #expect(preservedPan.width > currentPan.width)
        #expect(preservedPan.height < currentPan.height) // negative pan stays negative and scales
    }
}

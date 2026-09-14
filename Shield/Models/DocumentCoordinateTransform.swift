import CoreGraphics
import Foundation

// MARK: - DocumentCoordinateTransform
/// Centralized geometry engine for canonical document coordinates and viewport transformations.
///
/// Invariant:
/// All annotations, redactions, detections, and watermarks are stored in normalized
/// canonical coordinates (0...1) relative to the original document content.
/// Viewport coordinates are strictly derived for display and interaction, and never
/// supersede canonical coordinates as the source of truth.
public enum DocumentCoordinateTransform {
    
    // MARK: - Clamping & Normalization
    
    /// Clamps a scalar value to the unit interval [0, 1].
    public static func clamp(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 0 }
        return min(1, max(0, value))
    }
    
    /// Clamps and validates a canonical normalized rectangle within [0, 1] bounds.
    public static func clampedCanonicalRect(_ rect: CGRect, minimumSize: CGFloat = 0.02) -> CGRect {
        let minimum = clamp(minimumSize)
        let rawX = rect.origin.x.isFinite ? rect.origin.x : 0
        let rawY = rect.origin.y.isFinite ? rect.origin.y : 0
        let x = min(max(0, rawX), max(0, 1 - minimum))
        let y = min(max(0, rawY), max(0, 1 - minimum))
        
        let rawW = rect.width.isFinite ? rect.width : minimum
        let rawH = rect.height.isFinite ? rect.height : minimum
        let width = min(max(minimum, rawW), 1 - x)
        let height = min(max(minimum, rawH), 1 - y)
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    // MARK: - Aspect-Fit Layout Calculation
    
    /// Computes the exact aspect-fit content rectangle within a given container size,
    /// accounting for optional symmetric horizontal and vertical padding.
    public static func contentAspectFitRect(
        in containerSize: CGSize,
        contentAspect: CGFloat,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 16
    ) -> CGRect {
        guard containerSize.width > 0, containerSize.height > 0 else { return .zero }
        let aspect = max(0.01, contentAspect.isFinite ? contentAspect : 1.0)
        
        let availableWidth = max(0, containerSize.width - 2 * horizontalPadding)
        let availableHeight = max(0, containerSize.height - 2 * verticalPadding)
        guard availableWidth > 0, availableHeight > 0 else { return .zero }
        
        let containerAspect = availableWidth / availableHeight
        let fittedSize: CGSize
        
        if containerAspect > aspect {
            // Container is wider than content: height is constrained
            let height = availableHeight
            let width = height * aspect
            fittedSize = CGSize(width: width, height: height)
        } else {
            // Container is taller than content: width is constrained
            let width = availableWidth
            let height = width / aspect
            fittedSize = CGSize(width: width, height: height)
        }
        
        let originX = (containerSize.width - fittedSize.width) / 2
        let originY = (containerSize.height - fittedSize.height) / 2
        return CGRect(origin: CGPoint(x: originX, y: originY), size: fittedSize)
    }
    
    // MARK: - Coordinate Transformations
    
    /// Maps a canonical point (0...1) to viewport canvas points given the canvas size.
    public static func canonicalToViewport(point: CGPoint, in canvasSize: CGSize) -> CGPoint {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return .zero }
        return CGPoint(
            x: clamp(point.x) * canvasSize.width,
            y: clamp(point.y) * canvasSize.height
        )
    }
    
    /// Maps a canonical rectangle (0...1) to viewport canvas points given the canvas size.
    public static func canonicalToViewport(rect: CGRect, in canvasSize: CGSize) -> CGRect {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return .zero }
        let clamped = clampedCanonicalRect(rect, minimumSize: 0)
        return CGRect(
            x: clamped.origin.x * canvasSize.width,
            y: clamped.origin.y * canvasSize.height,
            width: clamped.width * canvasSize.width,
            height: clamped.height * canvasSize.height
        )
    }
    
    /// Maps a viewport canvas point back to canonical normalized coordinates (0...1).
    public static func viewportToCanonical(point: CGPoint, in canvasSize: CGSize) -> CGPoint {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return .zero }
        return CGPoint(
            x: clamp(point.x / canvasSize.width),
            y: clamp(point.y / canvasSize.height)
        )
    }
    
    /// Maps a viewport canvas rectangle back to canonical normalized coordinates (0...1).
    public static func viewportToCanonical(
        rect: CGRect,
        in canvasSize: CGSize,
        minimumSize: CGFloat = 0.02
    ) -> CGRect {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return .zero }
        let normalized = CGRect(
            x: rect.origin.x / canvasSize.width,
            y: rect.origin.y / canvasSize.height,
            width: rect.width / canvasSize.width,
            height: rect.height / canvasSize.height
        )
        return clampedCanonicalRect(normalized, minimumSize: minimumSize)
    }
    
    /// Converts a delta translation from gesture space to normalized canonical space,
    /// taking current effective zoom scale into account.
    public static func canonicalDelta(
        translation: CGSize,
        zoom: CGFloat,
        canvasSize: CGSize
    ) -> (dx: CGFloat, dy: CGFloat) {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return (0, 0) }
        let effectiveZoom = max(0.5, zoom.isFinite ? zoom : 1.0)
        let dx = (translation.width / effectiveZoom) / canvasSize.width
        let dy = (translation.height / effectiveZoom) / canvasSize.height
        return (
            dx: dx.isFinite ? dx : 0,
            dy: dy.isFinite ? dy : 0
        )
    }
    
    // MARK: - Pan & Zoom Continuity Across Layout Transitions
    
    /// Adjusts pan offset when the viewport container size changes (e.g. unfolding Duo,
    /// resizing Split View, rotating) so the user's visual focal point remains preserved.
    public static func preserveFocalPoint(
        oldSize: CGSize,
        newSize: CGSize,
        currentPan: CGSize,
        effectiveZoom: CGFloat
    ) -> CGSize {
        guard oldSize.width > 0, oldSize.height > 0,
              newSize.width > 0, newSize.height > 0,
              effectiveZoom > 1 else {
            return .zero
        }
        
        let widthRatio = newSize.width / oldSize.width
        let heightRatio = newSize.height / oldSize.height
        
        let adjustedX = currentPan.width * widthRatio
        let adjustedY = currentPan.height * heightRatio
        
        let maxPanX = max(0, (newSize.width * effectiveZoom - newSize.width) / 2 + 180)
        let maxPanY = max(0, (newSize.height * effectiveZoom - newSize.height) / 2 + 180)
        
        let clampedX = min(maxPanX, max(-maxPanX, adjustedX))
        let clampedY = min(maxPanY, max(-maxPanY, adjustedY))
        
        return CGSize(width: clampedX, height: clampedY)
    }
}

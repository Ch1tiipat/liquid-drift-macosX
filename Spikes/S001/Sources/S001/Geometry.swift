import AppKit

/// Notch values read from one screen. All rects use AppKit global screen
/// coordinates (origin at the bottom-left of the primary screen, y grows up).
struct NotchGeometry {
    let frame: NSRect
    let visibleFrame: NSRect
    let safeAreaInsets: NSEdgeInsets
    let topLeftArea: NSRect?
    let topRightArea: NSRect?
    let backingScaleFactor: CGFloat

    @MainActor
    init(screen: NSScreen) {
        frame = screen.frame
        visibleFrame = screen.visibleFrame
        safeAreaInsets = screen.safeAreaInsets
        topLeftArea = screen.auxiliaryTopLeftArea
        topRightArea = screen.auxiliaryTopRightArea
        backingScaleFactor = screen.backingScaleFactor
    }

    var hasNotch: Bool { safeAreaInsets.top > 0 && topLeftArea != nil && topRightArea != nil }

    /// Candidate 1 (from the task prompt): width from the two auxiliary widths.
    var notchFromWidths: NSRect? {
        guard hasNotch, let left = topLeftArea, let right = topRightArea else { return nil }
        let height = safeAreaInsets.top
        return NSRect(
            x: frame.minX + left.width,
            y: frame.maxY - height,
            width: frame.width - left.width - right.width,
            height: height
        )
    }

    /// Candidate 2: the gap between the two auxiliary rects' edges.
    var notchFromEdges: NSRect? {
        guard hasNotch, let left = topLeftArea, let right = topRightArea else { return nil }
        let height = safeAreaInsets.top
        return NSRect(x: left.maxX, y: frame.maxY - height, width: right.minX - left.maxX, height: height)
    }

    func report(index: Int) -> String {
        func r(_ rect: NSRect?) -> String {
            guard let rect else { return "nil" }
            return "x=\(rect.minX) y=\(rect.minY) w=\(rect.width) h=\(rect.height)"
        }
        let i = safeAreaInsets
        return """
        screen[\(index)]
          frame                 \(r(frame))
          visibleFrame          \(r(visibleFrame))
          safeAreaInsets        top=\(i.top) left=\(i.left) bottom=\(i.bottom) right=\(i.right)
          auxiliaryTopLeftArea  \(r(topLeftArea))
          auxiliaryTopRightArea \(r(topRightArea))
          backingScaleFactor    \(backingScaleFactor)
          notch (widths)        \(r(notchFromWidths))
          notch (edges)         \(r(notchFromEdges))
          formulas agree        \(notchFromWidths == notchFromEdges)
        """
    }
}

enum PanelVariant: String {
    case a = "A"
    case b = "B"

    /// A: exactly the notch. B: notch + 16 pt each side, extends 24 pt below.
    func frame(forNotch notch: NSRect) -> NSRect {
        switch self {
        case .a:
            return notch
        case .b:
            return NSRect(
                x: notch.minX - 16,
                y: notch.minY - 24,
                width: notch.width + 32,
                height: notch.height + 24
            )
        }
    }
}

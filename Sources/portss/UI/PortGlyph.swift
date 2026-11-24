import AppKit

/// Shared RJ45-style port glyph used by the status bar icon and the app icon generator.
/// Geometry is defined on a 16x16 grid with the origin at the top-left.
enum PortGlyph {
    private static let gridSize: CGFloat = 16

    private static let socketOutline: [CGPoint] = [
        CGPoint(x: 2, y: 2.5),
        CGPoint(x: 14, y: 2.5),
        CGPoint(x: 14, y: 11),
        CGPoint(x: 11, y: 11),
        CGPoint(x: 11, y: 13.5),
        CGPoint(x: 5, y: 13.5),
        CGPoint(x: 5, y: 11),
        CGPoint(x: 2, y: 11)
    ]

    private static let pinXPositions: [CGFloat] = [5, 7, 9, 11]
    private static let pinTopY: CGFloat = 5
    private static let pinBottomY: CGFloat = 7.5

    static func socketPath(in rect: NSRect, lineWidth: CGFloat) -> NSBezierPath {
        let path = NSBezierPath()
        for (index, gridPoint) in socketOutline.enumerated() {
            let point = convert(gridPoint, into: rect)
            if index == 0 {
                path.move(to: point)
            } else {
                path.line(to: point)
            }
        }
        path.close()
        path.lineWidth = lineWidth
        path.lineJoinStyle = .round
        return path
    }

    static func pinsPath(in rect: NSRect, lineWidth: CGFloat) -> NSBezierPath {
        let path = NSBezierPath()
        for pinX in pinXPositions {
            path.move(to: convert(CGPoint(x: pinX, y: pinTopY), into: rect))
            path.line(to: convert(CGPoint(x: pinX, y: pinBottomY), into: rect))
        }
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        return path
    }

    static func statusBarImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { bounds in
            let glyphRect = bounds.insetBy(dx: 1, dy: 1)
            NSColor.black.setStroke()
            socketPath(in: glyphRect, lineWidth: 1.5).stroke()
            pinsPath(in: glyphRect.offsetBy(dx: 0.5, dy: 0), lineWidth: 1).stroke()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "portss"
        return image
    }

    private static func convert(_ gridPoint: CGPoint, into rect: NSRect) -> NSPoint {
        let scale = rect.width / gridSize
        return NSPoint(x: rect.minX + gridPoint.x * scale, y: rect.maxY - gridPoint.y * scale)
    }
}

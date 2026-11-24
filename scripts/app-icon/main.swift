import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    FileHandle.standardError.write("usage: render-app-icon <output.iconset>\n".data(using: .utf8)!)
    exit(64)
}

let iconsetURL = URL(fileURLWithPath: arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let iconVariants: [(fileName: String, pixelSize: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func drawAppIcon(canvasSize: CGFloat) {
    let plateInset = canvasSize * 0.0977
    let plateRect = NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize).insetBy(dx: plateInset, dy: plateInset)
    let cornerRadius = plateRect.width * 0.2237
    let platePath = NSBezierPath(roundedRect: plateRect, xRadius: cornerRadius, yRadius: cornerRadius)

    NSGraphicsContext.saveGraphicsState()
    let dropShadow = NSShadow()
    dropShadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    dropShadow.shadowBlurRadius = canvasSize * 0.025
    dropShadow.shadowOffset = NSSize(width: 0, height: -canvasSize * 0.01)
    dropShadow.set()
    NSColor(calibratedRed: 0.20, green: 0.24, blue: 0.80, alpha: 1).setFill()
    platePath.fill()
    NSGraphicsContext.restoreGraphicsState()

    let backgroundGradient = NSGradient(
        starting: NSColor(calibratedRed: 0.36, green: 0.58, blue: 1.00, alpha: 1),
        ending: NSColor(calibratedRed: 0.22, green: 0.22, blue: 0.82, alpha: 1)
    )
    backgroundGradient?.draw(in: platePath, angle: -90)

    NSGraphicsContext.saveGraphicsState()
    platePath.addClip()
    let highlightRect = NSRect(x: plateRect.minX, y: plateRect.midY, width: plateRect.width, height: plateRect.height / 2)
    let highlightGradient = NSGradient(
        starting: NSColor.white.withAlphaComponent(0.18),
        ending: NSColor.white.withAlphaComponent(0)
    )
    highlightGradient?.draw(in: highlightRect, angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    let glyphSide = plateRect.width * 0.62
    let glyphRect = NSRect(
        x: plateRect.midX - glyphSide / 2,
        y: plateRect.midY - glyphSide / 2,
        width: glyphSide,
        height: glyphSide
    )
    let strokeWidth = glyphSide * 0.085

    NSGraphicsContext.saveGraphicsState()
    let glyphShadow = NSShadow()
    glyphShadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    glyphShadow.shadowBlurRadius = canvasSize * 0.012
    glyphShadow.shadowOffset = NSSize(width: 0, height: -canvasSize * 0.006)
    glyphShadow.set()

    let socketPath = PortGlyph.socketPath(in: glyphRect, lineWidth: strokeWidth)
    NSColor.white.withAlphaComponent(0.14).setFill()
    socketPath.fill()
    NSColor.white.setStroke()
    socketPath.stroke()
    PortGlyph.pinsPath(in: glyphRect, lineWidth: strokeWidth * 0.8).stroke()
    NSGraphicsContext.restoreGraphicsState()
}

for variant in iconVariants {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: variant.pixelSize,
        pixelsHigh: variant.pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        FileHandle.standardError.write("failed to create bitmap for \(variant.fileName)\n".data(using: .utf8)!)
        exit(1)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    drawAppIcon(canvasSize: CGFloat(variant.pixelSize))
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write("failed to encode \(variant.fileName)\n".data(using: .utf8)!)
        exit(1)
    }
    try pngData.write(to: iconsetURL.appendingPathComponent(variant.fileName))
}

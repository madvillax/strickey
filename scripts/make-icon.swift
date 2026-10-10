import AppKit

// A single sculpted keycap, using Finder-inspired blue/ice split surfaces.
// Draw every size directly so the release icon needs no external asset tooling.
guard CommandLine.arguments.count == 2 else { fatalError("Expected iconset output directory") }
let destination = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

func drawKeycap() {
    let body = NSBezierPath(roundedRect: NSRect(x: 80, y: 74, width: 864, height: 864), xRadius: 190, yRadius: 190)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(white: 0, alpha: 0.20)
    shadow.shadowBlurRadius = 20
    shadow.shadowOffset = NSSize(width: 0, height: -9)
    shadow.set()
    NSColor(red: 0.10, green: 0.31, blue: 0.52, alpha: 1).setFill()
    body.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: NSColor(red: 0.13, green: 0.38, blue: 0.61, alpha: 1),
               ending: NSColor(red: 0.30, green: 0.56, blue: 0.77, alpha: 1))!.draw(in: body, angle: 90)

    let face = NSBezierPath(roundedRect: NSRect(x: 90, y: 166, width: 844, height: 772), xRadius: 180, yRadius: 180)
    NSGraphicsContext.saveGraphicsState()
    face.addClip()
    NSGradient(starting: NSColor(red: 0.18, green: 0.55, blue: 0.93, alpha: 1),
               ending: NSColor(red: 0.47, green: 0.78, blue: 1, alpha: 1))!.draw(in: face, angle: 90)
    let ice = NSBezierPath()
    ice.move(to: NSPoint(x: 558, y: 166))
    ice.line(to: NSPoint(x: 934, y: 166))
    ice.line(to: NSPoint(x: 934, y: 938))
    ice.line(to: NSPoint(x: 530, y: 938))
    ice.curve(to: NSPoint(x: 494, y: 556), controlPoint1: NSPoint(x: 534, y: 792), controlPoint2: NSPoint(x: 470, y: 678))
    ice.curve(to: NSPoint(x: 558, y: 166), controlPoint1: NSPoint(x: 518, y: 423), controlPoint2: NSPoint(x: 561, y: 304))
    ice.close()
    NSGradient(starting: NSColor(red: 0.78, green: 0.89, blue: 0.98, alpha: 1),
               ending: NSColor(red: 0.94, green: 0.98, blue: 1, alpha: 1))!.draw(in: ice, angle: 90)
    let seam = NSBezierPath()
    seam.move(to: NSPoint(x: 530, y: 938))
    seam.curve(to: NSPoint(x: 494, y: 556), controlPoint1: NSPoint(x: 534, y: 792), controlPoint2: NSPoint(x: 470, y: 678))
    seam.curve(to: NSPoint(x: 558, y: 166), controlPoint1: NSPoint(x: 518, y: 423), controlPoint2: NSPoint(x: 561, y: 304))
    seam.lineWidth = 3
    NSColor(red: 0.10, green: 0.33, blue: 0.56, alpha: 0.18).setStroke()
    seam.stroke()
    NSGraphicsContext.restoreGraphicsState()

    NSColor(white: 1, alpha: 0.52).setStroke()
    face.lineWidth = 3
    face.stroke()
    // Angular S from the supplied reference, with a solid black fill.
    let mark = NSBezierPath()
    let referencePoints: [NSPoint] = [
        NSPoint(x: 0, y: 0), NSPoint(x: 288, y: 0),
        NSPoint(x: 288, y: 80), NSPoint(x: 80, y: 80),
        NSPoint(x: 80, y: 128), NSPoint(x: 256, y: 128),
        NSPoint(x: 256, y: 288), NSPoint(x: 0, y: 288),
        NSPoint(x: 0, y: 208), NSPoint(x: 176, y: 208),
        NSPoint(x: 176, y: 160), NSPoint(x: 0, y: 160),
    ]
    let markScale: CGFloat = 1.18
    let markOrigin = NSPoint(x: 512 - 144 * markScale, y: 554 + 144 * markScale)
    for (index, point) in referencePoints.enumerated() {
        let vertex = NSPoint(x: markOrigin.x + point.x * markScale, y: markOrigin.y - point.y * markScale)
        if index == 0 { mark.move(to: vertex) } else { mark.line(to: vertex) }
    }
    mark.close()
    NSColor.black.setFill()
    mark.fill()
    let frontHighlight = NSBezierPath()
    frontHighlight.move(to: NSPoint(x: 288, y: 126))
    frontHighlight.line(to: NSPoint(x: 736, y: 126))
    frontHighlight.lineWidth = 3
    frontHighlight.lineCapStyle = .round
    NSColor(white: 1, alpha: 0.20).setStroke()
    frontHighlight.stroke()
}

for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                      colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        let transform = AffineTransform(scale: Double(pixels) / 1_024)
        (transform as NSAffineTransform).concat()
        drawKeycap()
        NSGraphicsContext.restoreGraphicsState()
        let suffix = scale == 2 ? "@2x" : ""
        try bitmap.representation(using: .png, properties: [:])!.write(
            to: destination.appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
    }
}

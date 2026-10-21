import AppKit

// A vector app asset: a lock framed by four focus brackets, legible at Dock sizes.
let destination = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: destination, withIntermediateDirectories: true)
for (name, size) in [("icon_16x16",16), ("icon_16x16@2x",32), ("icon_32x32",32), ("icon_32x32@2x",64), ("icon_128x128",128), ("icon_128x128@2x",256), ("icon_256x256",256), ("icon_256x256@2x",512), ("icon_512x512",512), ("icon_512x512@2x",1024)] {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.cgContext.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    let tile = NSBezierPath(roundedRect: NSRect(x: 82, y: 82, width: 860, height: 860), xRadius: 194, yRadius: 194)
    NSGradient(starting: NSColor(srgbRed: 0.12, green: 0.35, blue: 0.27, alpha: 1), ending: NSColor(srgbRed: 0.025, green: 0.13, blue: 0.12, alpha: 1))!.draw(in: tile, angle: -70)
    NSColor(srgbRed: 0.48, green: 0.93, blue: 0.68, alpha: 1).setStroke()
    for (x, y, dx, dy) in [(278.0,278.0,1.0,1.0), (746.0,278.0,-1.0,1.0), (278.0,746.0,1.0,-1.0), (746.0,746.0,-1.0,-1.0)] {
        let bracket = NSBezierPath()
        bracket.move(to: NSPoint(x: x, y: y + dy * 106))
        bracket.line(to: NSPoint(x: x, y: y))
        bracket.line(to: NSPoint(x: x + dx * 106, y: y))
        bracket.lineWidth = 36; bracket.lineCapStyle = .round; bracket.lineJoinStyle = .round
        bracket.stroke()
    }
    NSColor(srgbRed: 0.91, green: 1, blue: 0.94, alpha: 1).setStroke()
    let shackle = NSBezierPath()
    shackle.move(to: NSPoint(x: 438, y: 518))
    shackle.line(to: NSPoint(x: 438, y: 576))
    shackle.curve(to: NSPoint(x: 586, y: 576), controlPoint1: NSPoint(x: 438, y: 680), controlPoint2: NSPoint(x: 586, y: 680))
    shackle.line(to: NSPoint(x: 586, y: 518))
    shackle.lineWidth = 37; shackle.lineCapStyle = .round; shackle.stroke()
    NSColor(srgbRed: 0.91, green: 1, blue: 0.94, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 398, y: 370, width: 228, height: 181), xRadius: 40, yRadius: 40).fill()
    NSColor(srgbRed: 0.06, green: 0.24, blue: 0.18, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 495, y: 450, width: 34, height: 34)).fill()
    NSBezierPath(roundedRect: NSRect(x: 504, y: 420, width: 16, height: 48), xRadius: 8, yRadius: 8).fill()
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: destination).appendingPathComponent(name + ".png"))
}

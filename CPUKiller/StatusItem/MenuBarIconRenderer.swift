import AppKit

@MainActor
enum MenuBarIconRenderer {
    static let pointSize: CGFloat = 18

    private static let ringWidth: CGFloat = 2.2
    private static let trackOpacity: CGFloat = 0.3
    private static let outerRadius: CGFloat = 7.0
    private static let innerRadius: CGFloat = 4.1

    static func image(cpuPercent: Double, memoryPercent: Double) -> NSImage {
        let image = NSImage(
            size: NSSize(width: pointSize, height: pointSize),
            flipped: false
        ) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else {
                return false
            }

            context.saveGState()
            defer { context.restoreGState() }

            context.setShouldAntialias(true)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            drawRing(
                in: context,
                center: center,
                radius: outerRadius,
                progress: cpuPercent
            )
            drawRing(
                in: context,
                center: center,
                radius: innerRadius,
                progress: memoryPercent
            )
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func drawRing(
        in context: CGContext,
        center: CGPoint,
        radius: CGFloat,
        progress: Double
    ) {
        let bounds = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        context.saveGState()
        defer { context.restoreGState() }

        context.setLineWidth(ringWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setStrokeColor(NSColor.black.withAlphaComponent(trackOpacity).cgColor)
        context.strokeEllipse(in: bounds)

        let normalized = min(max(progress, 0), 100) / 100
        guard normalized > 0 else { return }

        context.setStrokeColor(NSColor.black.cgColor)
        if normalized >= 1 {
            context.strokeEllipse(in: bounds)
            return
        }

        let startAngle = CGFloat.pi / 2
        let endAngle = startAngle - (CGFloat.pi * 2 * CGFloat(normalized))
        context.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        context.strokePath()
    }
}

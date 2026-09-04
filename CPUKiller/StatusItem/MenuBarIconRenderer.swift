import AppKit
import CoreText

enum NetworkSpeedEmphasis: Equatable {
    case balanced
    case upload
    case download

    static func resolve(
        uploadBytesPerSecond: Double?,
        downloadBytesPerSecond: Double?
    ) -> Self {
        guard let uploadBytesPerSecond, let downloadBytesPerSecond else {
            return .balanced
        }
        if uploadBytesPerSecond > downloadBytesPerSecond {
            return .upload
        }
        if downloadBytesPerSecond > uploadBytesPerSecond {
            return .download
        }
        return .balanced
    }
}

@MainActor
enum MenuBarIconRenderer {
    static let pointSize: CGFloat = 19

    private static let ringWidth: CGFloat = 2
    private static let trackOpacity: CGFloat = 0.3
    private static let outerRadius: CGFloat = 7.5
    private static let innerRadius: CGFloat = 4.35
    private static let menuBarHeight: CGFloat = 22
    private static let visualBlockHeight: CGFloat = 17
    private static let visualBlockInset = (menuBarHeight - visualBlockHeight) / 2
    private static let speedGap: CGFloat = 2
    private static let readingGap: CGFloat = 2
    private static let unitColumnGap: CGFloat = 2
    private static let baseSpeedFont = NSFont.monospacedDigitSystemFont(ofSize: 8.5, weight: .regular)
    private static let prominentSpeedFont = NSFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .regular)
    private static let secondarySpeedFont = NSFont.monospacedDigitSystemFont(ofSize: 7.5, weight: .regular)
    private static let arrowColumnWidth = textWidth("↑", font: baseSpeedFont)
    private static let rateColumnWidth = textWidth("9999", font: prominentSpeedFont)
    private static let unitColumnWidth = textWidth("GB/s", font: prominentSpeedFont)

    static func image(
        cpuPercent: Double,
        memoryPercent: Double,
        uploadBytesPerSecond: Double?,
        downloadBytesPerSecond: Double?,
        showsNetworkSpeed: Bool,
        layout: MenuBarLayout = .ringsOnLeft
    ) -> NSImage {
        let width = showsNetworkSpeed
            ? pointSize + speedGap + rateColumnWidth + readingGap + unitColumnWidth + unitColumnGap + arrowColumnWidth
            : pointSize
        let image = NSImage(
            size: NSSize(width: width, height: menuBarHeight),
            flipped: false
        ) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else {
                return false
            }

            context.saveGState()
            defer { context.restoreGState() }

            context.setShouldAntialias(true)
            let speedWidth = width - pointSize - speedGap
            let ringX = layout == .ringsOnLeft || !showsNetworkSpeed ? 0 : speedWidth + speedGap
            let speedX = layout == .ringsOnLeft ? pointSize + speedGap : 0
            let center = CGPoint(x: ringX + pointSize / 2, y: rect.midY)
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
            if showsNetworkSpeed {
                drawNetworkSpeed(
                    uploadBytesPerSecond: uploadBytesPerSecond,
                    downloadBytesPerSecond: downloadBytesPerSecond,
                    originX: speedX,
                    using: context
                )
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    static func panelTarget(
        at point: NSPoint,
        in buttonBounds: NSRect,
        showsNetworkSpeed: Bool,
        layout: MenuBarLayout
    ) -> StatusItemPanelTarget {
        guard showsNetworkSpeed else { return .process }
        let width = imageWidth(showsNetworkSpeed: true)
        let imageMinX = buttonBounds.midX - width / 2
        let speedWidth = width - pointSize - speedGap
        let ringMinX = imageMinX + (layout == .ringsOnLeft ? 0 : speedWidth + speedGap)
        // 状态栏会在不同菜单栏高度下调整纵向命中坐标；双环只按其横向区带判断。
        let ringFrame = NSRect(x: ringMinX - 1, y: buttonBounds.minY, width: pointSize + 2, height: buttonBounds.height)
        guard !ringFrame.contains(point) else { return .process }
        // 上下行读数进入的是同一张网络表，且产品要求总是以 Download 降序打开；
        // 因此这里不再把纵向位置映射成两种结果，避免菜单栏坐标差异影响入口。
        return .networkDownload
    }

    private static func imageWidth(showsNetworkSpeed: Bool) -> CGFloat {
        showsNetworkSpeed
            ? pointSize + speedGap + rateColumnWidth + readingGap + unitColumnWidth + unitColumnGap + arrowColumnWidth
            : pointSize
    }

    private static func drawNetworkSpeed(
        uploadBytesPerSecond: Double?,
        downloadBytesPerSecond: Double?,
        originX: CGFloat,
        using context: CGContext
    ) {
        let reading = NetworkRateFormatter.pair(
            uploadBytesPerSecond: uploadBytesPerSecond,
            downloadBytesPerSecond: downloadBytesPerSecond
        )
        let emphasis = NetworkSpeedEmphasis.resolve(
            uploadBytesPerSecond: uploadBytesPerSecond,
            downloadBytesPerSecond: downloadBytesPerSecond
        )
        let topLine = makeTextLine(
            rate: reading.upload,
            unit: reading.unit ?? "",
            arrow: "↑",
            readingFont: speedFont(for: .upload, emphasis: emphasis)
        )
        let bottomLine = makeTextLine(
            rate: reading.download,
            unit: reading.unit ?? "",
            arrow: "↓",
            readingFont: speedFont(for: .download, emphasis: emphasis)
        )
        let arrowX = originX + rateColumnWidth + readingGap + unitColumnWidth + unitColumnGap
        let unitRightX = arrowX - unitColumnGap
        let baselines = edgeAnchoredBaselines(topLine: topLine, bottomLine: bottomLine, context: context)
        let topRateRightX = leftEdge(of: topLine.unit, rightAlignedAt: unitRightX, in: context) - readingGap
        let bottomRateRightX = leftEdge(of: bottomLine.unit, rightAlignedAt: unitRightX, in: context) - readingGap

        draw(topLine.rate, at: topRateRightX, baselineY: baselines.top, alignment: .right, in: context)
        draw(bottomLine.rate, at: bottomRateRightX, baselineY: baselines.bottom, alignment: .right, in: context)
        draw(topLine.unit, at: unitRightX, baselineY: baselines.top, alignment: .right, in: context)
        draw(bottomLine.unit, at: unitRightX, baselineY: baselines.bottom, alignment: .right, in: context)
        draw(topLine.arrow, at: arrowX + arrowColumnWidth, baselineY: baselines.top, alignment: .right, in: context)
        draw(bottomLine.arrow, at: arrowX + arrowColumnWidth, baselineY: baselines.bottom, alignment: .right, in: context)
    }

    private static func makeTextLine(
        rate: String,
        unit: String,
        arrow: String,
        readingFont: NSFont
    ) -> NetworkTextLine {
        let readingAttributes: [NSAttributedString.Key: Any] = [
            .font: readingFont,
            .foregroundColor: NSColor.black
        ]
        let arrowAttributes: [NSAttributedString.Key: Any] = [
            .font: baseSpeedFont,
            .foregroundColor: NSColor.black
        ]
        return NetworkTextLine(
            rate: CTLineCreateWithAttributedString(NSAttributedString(string: rate, attributes: readingAttributes)),
            unit: CTLineCreateWithAttributedString(NSAttributedString(string: unit, attributes: readingAttributes)),
            arrow: CTLineCreateWithAttributedString(NSAttributedString(string: arrow, attributes: arrowAttributes))
        )
    }

    private static func speedFont(
        for direction: NetworkSpeedEmphasis,
        emphasis: NetworkSpeedEmphasis
    ) -> NSFont {
        guard emphasis != .balanced else { return baseSpeedFont }
        return direction == emphasis ? prominentSpeedFont : secondarySpeedFont
    }

    private static func edgeAnchoredBaselines(
        topLine: NetworkTextLine,
        bottomLine: NetworkTextLine,
        context: CGContext
    ) -> (top: CGFloat, bottom: CGFloat) {
        let topBounds = topLine.imageBounds(in: context)
        let bottomBounds = bottomLine.imageBounds(in: context)
        let topBaseline = visualBlockInset + visualBlockHeight - topBounds.maxY
        let bottomBaseline = visualBlockInset - bottomBounds.minY
        return (top: topBaseline, bottom: bottomBaseline)
    }

    private static func draw(
        _ line: CTLine,
        at x: CGFloat,
        baselineY: CGFloat,
        alignment: NSTextAlignment,
        in context: CGContext
    ) {
        let bounds = glyphBounds(of: line, in: context)
        guard !bounds.isNull else { return }
        let originX = alignment == .right ? x - bounds.maxX : x - bounds.minX
        context.textPosition = CGPoint(x: originX, y: baselineY)
        CTLineDraw(line, context)
    }

    private static func leftEdge(
        of line: CTLine,
        rightAlignedAt x: CGFloat,
        in context: CGContext
    ) -> CGFloat {
        let bounds = glyphBounds(of: line, in: context)
        guard !bounds.isNull else { return x }
        return x - bounds.width
    }

    private static func glyphBounds(of line: CTLine, in context: CGContext) -> CGRect {
        let previousTextPosition = context.textPosition
        context.textPosition = .zero
        defer { context.textPosition = previousTextPosition }
        return CTLineGetImageBounds(line, context)
    }

    private struct NetworkTextLine {
        let rate: CTLine
        let unit: CTLine
        let arrow: CTLine

        func imageBounds(in context: CGContext) -> CGRect {
            [rate, unit, arrow]
                .map { MenuBarIconRenderer.glyphBounds(of: $0, in: context) }
                .reduce(.null) { $0.union($1) }
        }
    }

    private static func textWidth(_ text: String, font: NSFont) -> CGFloat {
        ceil((text as NSString).size(withAttributes: [.font: font]).width)
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

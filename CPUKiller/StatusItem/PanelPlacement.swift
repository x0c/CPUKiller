import Foundation

/// 菜单栏浮层只允许锚在屏幕顶上的图标下方；空矩形或屏幕底部的假位置不能拿去定位。
nonisolated enum PanelPlacement {
    static func isMenuBarAnchor(_ rect: NSRect, screens: [NSRect]) -> Bool {
        guard rect.width > 1, rect.height > 1 else { return false }
        return screens.contains { screen in
            rect.midX >= screen.minX
                && rect.midX <= screen.maxX
                && rect.midY >= screen.maxY - 48
                && rect.midY <= screen.maxY + 4
        }
    }

    static func origin(
        anchor: NSRect?,
        size: CGSize,
        screens: [NSRect],
        visibleScreens: [NSRect],
        fallbackVisible: NSRect
    ) -> CGPoint {
        if let anchor, isMenuBarAnchor(anchor, screens: screens) {
            let visible = visibleScreen(containing: anchor, visibles: visibleScreens) ?? fallbackVisible
            var origin = CGPoint(
                x: anchor.midX - size.width / 2,
                y: anchor.minY - size.height - 6
            )
            origin.x = min(max(origin.x, visible.minX + 8), max(visible.minX + 8, visible.maxX - size.width - 8))
            origin.y = min(origin.y, visible.maxY - size.height)
            origin.y = max(origin.y, visible.minY + 8)
            return origin
        }
        return CGPoint(
            x: fallbackVisible.midX - size.width / 2,
            y: fallbackVisible.maxY - size.height - 6
        )
    }

    private static func visibleScreen(containing rect: NSRect, visibles: [NSRect]) -> NSRect? {
        visibles.first { $0.insetBy(dx: -48, dy: -48).contains(CGPoint(x: rect.midX, y: rect.midY)) }
    }
}

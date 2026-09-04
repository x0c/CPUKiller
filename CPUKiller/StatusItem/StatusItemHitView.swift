import AppKit

/// 状态栏按钮的透明点击层：直接接收本地坐标，不能再从全局当前事件反推。
@MainActor
final class StatusItemHitView: NSView {
    var onPrimaryClick: ((NSPoint) -> Void)?
    var onSecondaryClick: (() -> Void)?

    override func mouseDown(with event: NSEvent) {}

    override func mouseUp(with event: NSEvent) {
        if event.modifierFlags.contains(.control) {
            onSecondaryClick?()
        } else {
            onPrimaryClick?(convert(event.locationInWindow, from: nil))
        }
    }

    override func rightMouseDown(with event: NSEvent) {}

    override func rightMouseUp(with event: NSEvent) {
        onSecondaryClick?()
    }
}

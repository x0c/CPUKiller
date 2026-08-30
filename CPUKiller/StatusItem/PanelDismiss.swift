import Foundation

nonisolated enum PanelDismiss {
    static func shouldHide(click: CGPoint, keptFrames: [CGRect]) -> Bool {
        !keptFrames.contains { $0.contains(click) }
    }
}

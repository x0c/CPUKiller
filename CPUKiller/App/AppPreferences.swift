import Foundation

enum AppPreferences {
    static let launchAtLoginKey = "general.launchAtLogin"
    static let launchAtLoginDefault = false

    static let refreshEnabledKey = "panel.refreshEnabled"
    static let refreshEnabledDefault = true

    static let refreshInterval: TimeInterval = 1.5

    static let compactSize = CGSize(width: 336, height: 360)
    static let compactCornerRadius: CGFloat = 16
    static let metricColumnWidth: CGFloat = 72
    static let endColumnWidth: CGFloat = 22
}

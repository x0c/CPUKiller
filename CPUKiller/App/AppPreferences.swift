import Foundation

nonisolated enum AppPreferences {
    static let launchAtLoginKey = "general.launchAtLogin"
    static let launchAtLoginDefault = false

    static let refreshEnabledKey = "panel.refreshEnabled"
    static let refreshEnabledDefault = true

    static let refreshInterval: TimeInterval = 1.5

    /// 常显滚动条后名字列仍够 Google Chrome / Activity Monitor；禁止为包名再加宽。
    static let compactSize = CGSize(width: 368, height: 360)
    static let compactCornerRadius: CGFloat = 16
    static let metricColumnWidth: CGFloat = 66
    static let endColumnWidth: CGFloat = 22
}

import Foundation
import Observation

nonisolated enum AppPreferences {
    static let launchAtLoginKey = "general.launchAtLogin"
    static let launchAtLoginDefault = false

    static let refreshEnabledKey = "panel.refreshEnabled"
    static let refreshEnabledDefault = true
    static let networkRefreshEnabledKey = "panel.networkRefreshEnabled"
    static let networkRefreshEnabledDefault = true

    static let showNetworkSpeedKey = "menuBar.showNetworkSpeed"
    static let showNetworkSpeedDefault = true
    static let menuBarLayoutKey = "menuBar.layout"
    static let menuBarLayoutDefault = MenuBarLayout.ringsOnLeft

    static let refreshInterval: TimeInterval = 1.5
    /// 网络列表直接采用 nettop 的一秒差分，节奏必须与菜单栏读数一致。
    static let networkRefreshInterval: TimeInterval = 1

    /// 常显滚动条后名字列仍够 Google Chrome / Activity Monitor；禁止为包名再加宽。
    static let compactSize = CGSize(width: 368, height: 360)
    static let compactCornerRadius: CGFloat = 16
    static let metricColumnWidth: CGFloat = 66
    static let endColumnWidth: CGFloat = 22
}

enum MenuBarLayout: String, CaseIterable {
    case ringsOnLeft
    case speedOnLeft
}

/// 菜单栏展示偏好集中在这里，避免菜单状态和绘制状态各存一份。
@MainActor
@Observable
final class MenuBarDisplayPreferences {
    static let shared = MenuBarDisplayPreferences()

    var showsNetworkSpeed: Bool {
        didSet {
            defaults.set(showsNetworkSpeed, forKey: AppPreferences.showNetworkSpeedKey)
            onChange?()
        }
    }

    var layout: MenuBarLayout {
        didSet {
            defaults.set(layout.rawValue, forKey: AppPreferences.menuBarLayoutKey)
            onChange?()
        }
    }

    @ObservationIgnored var onChange: (() -> Void)?
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showsNetworkSpeed = defaults.object(forKey: AppPreferences.showNetworkSpeedKey) as? Bool
            ?? AppPreferences.showNetworkSpeedDefault
        layout = defaults.string(forKey: AppPreferences.menuBarLayoutKey)
            .flatMap(MenuBarLayout.init(rawValue:))
            ?? AppPreferences.menuBarLayoutDefault
    }
}

import Foundation
import Observation

/// 菜单栏图标显隐。缺省为显示；用键是否存在判断，避免把空当成关。
@MainActor
@Observable
final class MenuBarIconStore {
    static let shared = MenuBarIconStore()
    static let key = "menuBar.iconVisible"

    var isVisible: Bool {
        didSet {
            UserDefaults.standard.set(isVisible, forKey: Self.key)
            onChange?(isVisible)
        }
    }

    var onChange: ((Bool) -> Void)?

    private init() {
        if UserDefaults.standard.object(forKey: Self.key) == nil {
            isVisible = true
        } else {
            isVisible = UserDefaults.standard.bool(forKey: Self.key)
        }
    }
}

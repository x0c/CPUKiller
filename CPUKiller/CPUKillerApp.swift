import AppKit
import SwiftUI

@main
struct CPUKillerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var hiddenMenuInserted = false

    init() {
        UserDefaults.standard.register(defaults: [
            "NSAutoFillHeuristicControllerEnabled": false,
            AppPreferences.refreshEnabledKey: AppPreferences.refreshEnabledDefault
        ])
    }

    var body: some Scene {
        // 永远隐藏：只为满足 SwiftUI App 必须有 Scene。真正菜单栏在 AppDelegate。
        MenuBarExtra("", isInserted: $hiddenMenuInserted) {
            EmptyView()
        }
    }
}

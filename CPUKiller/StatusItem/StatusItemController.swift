import AppKit
import MacKitCore

enum StatusItemPanelTarget: Equatable {
    case process
    case networkUpload
    case networkDownload
}

/// 系统状态栏会从右向左接纳后来加入的项目；固定创建顺序，保证圆环在左、网速在右。
extension StatusItemPanelTarget {
    static let statusItemCreationOrder: [StatusItemPanelTarget] = [.networkDownload, .process]
}

/// 本地状态项：菜单栏图标是动态双环，不能换成静态图。左右键分发仍在这里，左键永不弹菜单。
/// 图标即主入口，禁止隐藏；圆环始终可见，网速项仅受「显示网速」偏好控制。
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private var ringStatusItem: NSStatusItem!
    private var networkStatusItem: NSStatusItem!
    private let menu: NSMenu
    private var activeStatusItem: NSStatusItem?
    private let onOpenPanel: (StatusItemPanelTarget) -> Void
    private let onOpenMainWindow: () -> Void
    private let onOpenSettings: () -> Void
    private let onCheckForUpdates: () -> Void
    private let onQuit: () -> Void
    private let launchAtLogin = LaunchAtLoginManager.shared
    private let displayPreferences = MenuBarDisplayPreferences.shared
    private var cpuPercent = 0.0
    private var memoryPercent = 0.0
    private var uploadBytesPerSecond: Double?
    private var downloadBytesPerSecond: Double?

    private lazy var launchAtLoginItem = NSMenuItem(
        title: String(localized: "menu.launchAtLogin"),
        action: #selector(toggleLaunchAtLogin(_:)),
        keyEquivalent: ""
    )
    private lazy var openLoginItemsItem = NSMenuItem(
        title: String(localized: "menu.openLoginItems"),
        action: #selector(openLoginItems(_:)),
        keyEquivalent: ""
    )
    private lazy var showNetworkSpeedItem = NSMenuItem(
        title: String(localized: "menu.showNetworkSpeed"),
        action: #selector(toggleNetworkSpeed(_:)),
        keyEquivalent: ""
    )
    private lazy var openMainWindowItem = NSMenuItem(
        title: String(localized: "menu.openMainWindow"),
        action: #selector(openMainWindow(_:)),
        keyEquivalent: ""
    )
    private lazy var settingsItem = NSMenuItem(
        title: String(localized: "menu.settings"),
        action: #selector(openSettings(_:)),
        keyEquivalent: ","
    )
    private lazy var checkForUpdatesItem = NSMenuItem(
        title: String(localized: "menu.checkForUpdates"),
        action: #selector(checkForUpdates(_:)),
        keyEquivalent: ""
    )
    private lazy var quitItem = NSMenuItem(
        title: String(localized: "menu.quit"),
        action: #selector(quit(_:)),
        keyEquivalent: "q"
    )

    init(
        onOpenPanel: @escaping (StatusItemPanelTarget) -> Void,
        onOpenMainWindow: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onCheckForUpdates: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onOpenPanel = onOpenPanel
        self.onOpenMainWindow = onOpenMainWindow
        self.onOpenSettings = onOpenSettings
        self.onCheckForUpdates = onCheckForUpdates
        self.onQuit = onQuit
        menu = NSMenu()
        super.init()
        configureMenu()
        rebuildStatusItems()
        displayPreferences.onChange = { [weak self] in
            self?.rebuildStatusItems()
        }
    }

    func buttonScreenFrame() -> NSRect? {
        guard let item = activeStatusItem ?? ringStatusItem,
              let button = item.button,
              let window = button.window else { return nil }
        let frame = window.convertToScreen(button.convert(button.bounds, to: nil))
        guard PanelPlacement.isMenuBarAnchor(frame, screens: NSScreen.screens.map(\.frame)) else {
            return nil
        }
        return frame
    }

    private func rebuildStatusItems() {
        if let ringStatusItem {
            NSStatusBar.system.removeStatusItem(ringStatusItem)
        }
        if let networkStatusItem {
            NSStatusBar.system.removeStatusItem(networkStatusItem)
        }
        activeStatusItem = nil

        for target in StatusItemPanelTarget.statusItemCreationOrder {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            configureButton(item.button, target: target)
            switch target {
            case .process:
                ringStatusItem = item
            case .networkUpload, .networkDownload:
                networkStatusItem = item
            }
        }

        ringStatusItem.length = MenuBarIconRenderer.pointSize
        networkStatusItem.length = MenuBarIconRenderer.networkWidth
        renderStatusItem()
        applyIconVisibility()
    }

    private func configureButton(_ button: NSStatusBarButton?, target: StatusItemPanelTarget) {
        guard let button else { return }
        button.imageScaling = .scaleProportionallyDown
        button.imagePosition = .imageOnly
        button.focusRingType = .none
        button.setAccessibilityLabel(String(localized: "status.item.accessibility"))
        button.target = self
        button.action = target == .process ? #selector(openProcessPanel(_:)) : #selector(openNetworkPanel(_:))
        button.sendAction(on: [.leftMouseUp])
        let rightClick = NSClickGestureRecognizer(target: self, action: #selector(showContextMenuFromGesture(_:)))
        rightClick.buttonMask = 0x2
        button.addGestureRecognizer(rightClick)
    }

    func updateMetrics(cpuPercent: Double, memoryPercent: Double) {
        self.cpuPercent = cpuPercent
        self.memoryPercent = memoryPercent
        renderStatusItem()
    }

    func updateNetworkSpeed(uploadBytesPerSecond: Double?, downloadBytesPerSecond: Double?) {
        self.uploadBytesPerSecond = uploadBytesPerSecond
        self.downloadBytesPerSecond = downloadBytesPerSecond
        renderStatusItem()
    }

    private func applyIconVisibility() {
        ringStatusItem.isVisible = true
        networkStatusItem.isVisible = displayPreferences.showsNetworkSpeed
    }

    private func configureMenu() {
        for item in [
            openMainWindowItem,
            launchAtLoginItem,
            openLoginItemsItem,
            showNetworkSpeedItem,
            settingsItem,
            checkForUpdatesItem,
            quitItem
        ] {
            item.target = self
        }
        menu.delegate = self
        menu.items = [
            openMainWindowItem,
            launchAtLoginItem,
            openLoginItemsItem,
            showNetworkSpeedItem,
            settingsItem,
            checkForUpdatesItem,
            .separator(),
            quitItem
        ]
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        launchAtLogin.refresh()
        launchAtLoginItem.state = menuState(for: launchAtLogin.status)
        openLoginItemsItem.isHidden = !launchAtLogin.requiresApproval
        showNetworkSpeedItem.state = displayPreferences.showsNetworkSpeed ? .on : .off
    }

    @objc
    private func openProcessPanel(_ sender: Any?) {
        activeStatusItem = ringStatusItem
        onOpenPanel(.process)
    }

    @objc
    private func openNetworkPanel(_ sender: Any?) {
        activeStatusItem = networkStatusItem
        onOpenPanel(.networkDownload)
    }

    @objc
    private func showContextMenuFromGesture(_ sender: NSClickGestureRecognizer) {
        guard sender.state == .ended else { return }
        activeStatusItem = sender.view === ringStatusItem.button ? ringStatusItem : networkStatusItem
        activeStatusItem?.popUpMenu(menu)
    }

    @objc
    private func toggleLaunchAtLogin(_ sender: Any?) {
        launchAtLogin.refresh()
        launchAtLogin.setEnabled(!launchAtLogin.isEnabled)
    }

    @objc
    private func openLoginItems(_ sender: Any?) {
        launchAtLogin.openSystemSettings()
    }

    @objc
    private func toggleNetworkSpeed(_ sender: Any?) {
        displayPreferences.showsNetworkSpeed.toggle()
    }

    @objc
    private func openMainWindow(_ sender: Any?) {
        onOpenMainWindow()
    }

    @objc
    private func openSettings(_ sender: Any?) {
        onOpenSettings()
    }

    @objc
    private func checkForUpdates(_ sender: Any?) {
        onCheckForUpdates()
    }

    @objc
    private func quit(_ sender: Any?) {
        onQuit()
    }

    private func menuState(for status: LaunchAtLoginStatus) -> NSControl.StateValue {
        switch status.menuTriState {
        case .on: return .on
        case .off: return .off
        case .mixed: return .mixed
        }
    }

    private func renderStatusItem() {
        let ringImage = MenuBarIconRenderer.image(
            cpuPercent: cpuPercent,
            memoryPercent: memoryPercent
        )
        ringImage.isTemplate = true
        ringStatusItem.button?.image = ringImage

        let networkImage = MenuBarIconRenderer.networkImage(
            uploadBytesPerSecond: uploadBytesPerSecond,
            downloadBytesPerSecond: downloadBytesPerSecond
        )
        networkImage.isTemplate = true
        networkStatusItem.button?.image = networkImage
        networkStatusItem.isVisible = displayPreferences.showsNetworkSpeed
    }
}

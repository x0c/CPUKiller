import AppKit
import MacKitCore

enum StatusItemPanelTarget: Equatable {
    case process
    case networkUpload
    case networkDownload
}

/// 本地状态项：菜单栏图标是动态双环，不能换成静态图。左右键分发仍在这里，左键永不弹菜单。
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let menu: NSMenu
    private let onOpenPanel: (StatusItemPanelTarget) -> Void
    private let onOpenMainWindow: () -> Void
    private let onHideMenuBarIcon: () -> Void
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
    private lazy var hideIconItem = NSMenuItem(
        title: String(localized: "menu.hideMenuBarIcon"),
        action: #selector(hideMenuBarIcon(_:)),
        keyEquivalent: ""
    )
    private lazy var showNetworkSpeedItem = NSMenuItem(
        title: String(localized: "menu.showNetworkSpeed"),
        action: #selector(toggleNetworkSpeed(_:)),
        keyEquivalent: ""
    )
    private lazy var menuBarLayoutItem = NSMenuItem(
        title: String(localized: "menu.menuBarLayout"),
        action: nil,
        keyEquivalent: ""
    )
    private lazy var ringsOnLeftItem = NSMenuItem(
        title: String(localized: "menu.ringsOnLeft"),
        action: #selector(showRingsOnLeft(_:)),
        keyEquivalent: ""
    )
    private lazy var speedOnLeftItem = NSMenuItem(
        title: String(localized: "menu.speedOnLeft"),
        action: #selector(showSpeedOnLeft(_:)),
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
        onHideMenuBarIcon: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onCheckForUpdates: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onOpenPanel = onOpenPanel
        self.onOpenMainWindow = onOpenMainWindow
        self.onHideMenuBarIcon = onHideMenuBarIcon
        self.onOpenSettings = onOpenSettings
        self.onCheckForUpdates = onCheckForUpdates
        self.onQuit = onQuit
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu = NSMenu()
        super.init()
        configureMenu()
        configureButton()
        displayPreferences.onChange = { [weak self] in
            self?.renderStatusItem()
        }
        applyIconVisibility(MenuBarIconStore.shared.isVisible)
        MenuBarIconStore.shared.onChange = { [weak self] visible in
            self?.applyIconVisibility(visible)
        }
    }

    func buttonScreenFrame() -> NSRect? {
        guard let button = statusItem.button, let window = button.window else { return nil }
        let frame = window.convertToScreen(button.convert(button.bounds, to: nil))
        guard PanelPlacement.isMenuBarAnchor(frame, screens: NSScreen.screens.map(\.frame)) else {
            return nil
        }
        return frame
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        updateMetrics(cpuPercent: 0, memoryPercent: 0)
        button.imageScaling = .scaleProportionallyDown
        button.imagePosition = .imageOnly
        button.setAccessibilityLabel(String(localized: "status.item.accessibility"))
        button.target = self
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.focusRingType = .none
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

    private func applyIconVisibility(_ visible: Bool) {
        statusItem.isVisible = visible
    }

    private func configureMenu() {
        for item in [
            openMainWindowItem,
            launchAtLoginItem,
            openLoginItemsItem,
            showNetworkSpeedItem,
            ringsOnLeftItem,
            speedOnLeftItem,
            hideIconItem,
            settingsItem,
            checkForUpdatesItem,
            quitItem
        ] {
            item.target = self
        }
        menu.delegate = self
        let layoutMenu = NSMenu()
        layoutMenu.items = [ringsOnLeftItem, speedOnLeftItem]
        menuBarLayoutItem.submenu = layoutMenu
        menu.items = [
            openMainWindowItem,
            launchAtLoginItem,
            openLoginItemsItem,
            showNetworkSpeedItem,
            menuBarLayoutItem,
            hideIconItem,
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
        ringsOnLeftItem.state = displayPreferences.layout == .ringsOnLeft ? .on : .off
        speedOnLeftItem.state = displayPreferences.layout == .speedOnLeft ? .on : .off
    }

    @objc
    private func handleClick(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            onOpenPanel(.process)
            return
        }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            let target: StatusItemPanelTarget
            if let button = statusItem.button {
                let point = button.convert(event.locationInWindow, from: nil)
                // 状态项按钮会为了点击留出额外宽度；命中判断必须以实际绘制的图像框为准。
                let imageBounds = button.cell?.imageRect(forBounds: button.bounds) ?? button.bounds
                target = MenuBarIconRenderer.panelTarget(
                    at: point,
                    in: imageBounds,
                    showsNetworkSpeed: displayPreferences.showsNetworkSpeed,
                    layout: displayPreferences.layout
                )
            } else {
                target = .process
            }
            onOpenPanel(target)
        }
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
    private func showRingsOnLeft(_ sender: Any?) {
        displayPreferences.layout = .ringsOnLeft
    }

    @objc
    private func showSpeedOnLeft(_ sender: Any?) {
        displayPreferences.layout = .speedOnLeft
    }

    @objc
    private func hideMenuBarIcon(_ sender: Any?) {
        onHideMenuBarIcon()
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
        guard let button = statusItem.button else { return }
        let image = MenuBarIconRenderer.image(
            cpuPercent: cpuPercent,
            memoryPercent: memoryPercent,
            uploadBytesPerSecond: uploadBytesPerSecond,
            downloadBytesPerSecond: downloadBytesPerSecond,
            showsNetworkSpeed: displayPreferences.showsNetworkSpeed,
            layout: displayPreferences.layout
        )
        image.isTemplate = true
        button.image = image
        button.image?.isTemplate = true
    }
}

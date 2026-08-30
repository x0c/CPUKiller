import AppKit

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let menu: NSMenu
    private let onTogglePanel: () -> Void
    private let onOpenSettings: () -> Void
    private let onCheckForUpdates: () -> Void
    private let onQuit: () -> Void

    init(
        onTogglePanel: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onCheckForUpdates: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onTogglePanel = onTogglePanel
        self.onOpenSettings = onOpenSettings
        self.onCheckForUpdates = onCheckForUpdates
        self.onQuit = onQuit
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu = NSMenu()
        super.init()
        configureMenu()
        configureButton()
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
        guard let button = statusItem.button else { return }
        let image = MenuBarIconRenderer.image(
            cpuPercent: cpuPercent,
            memoryPercent: memoryPercent
        )
        image.isTemplate = true
        button.image = image
        button.image?.isTemplate = true
    }

    private func configureMenu() {
        let settings = NSMenuItem(
            title: String(localized: "menu.settings"),
            action: #selector(openSettings(_:)),
            keyEquivalent: ","
        )
        settings.target = self

        let checkForUpdates = NSMenuItem(
            title: String(localized: "menu.checkForUpdates"),
            action: #selector(checkForUpdates(_:)),
            keyEquivalent: ""
        )
        checkForUpdates.target = self

        let quit = NSMenuItem(
            title: String(localized: "menu.quit"),
            action: #selector(quit(_:)),
            keyEquivalent: "q"
        )
        quit.target = self

        menu.items = [settings, checkForUpdates, .separator(), quit]
    }

    @objc
    private func handleClick(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            onTogglePanel()
            return
        }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            onTogglePanel()
        }
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
}

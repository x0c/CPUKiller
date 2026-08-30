import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) static weak var shared: AppDelegate?
    let listModel = ProcessListModel()
    private var statusItemController: StatusItemController?
    private var compactPanel: CompactPanel?
    private let appUpdater = AppUpdater()
    private var allowTermination = false
    private var commaMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        let panel = CompactPanel(model: listModel)
        compactPanel = panel

        statusItemController = StatusItemController(
            onTogglePanel: { [weak self] in self?.toggleCompactPanel() },
            onOpenSettings: { [weak self] in self?.showSettings() },
            onCheckForUpdates: { [weak appUpdater] in appUpdater?.checkForUpdates(nil) },
            onQuit: { [weak self] in self?.requestTermination() }
        )
        listModel.setMetricsObserver { [weak statusItemController] cpuPercent, memoryPercent in
            statusItemController?.updateMetrics(
                cpuPercent: cpuPercent,
                memoryPercent: memoryPercent
            )
        }
        panel.additionalKeptFrames = { [weak statusItemController] in
            statusItemController?.buttonScreenFrame().map { [$0] } ?? []
        }
        panel.onVisibilityChange = { [weak self] visible in
            self?.listModel.setPanelVisible(visible)
        }

        commaMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let command = event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command)
            if command, event.charactersIgnoringModifiers == "," {
                SettingsWindowController.shared.show()
                return nil
            }
            return event
        }

        if CommandLine.arguments.contains("--show-panel") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.showPanelBelowStatusItem(attempt: 0)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if allowTermination { return .terminateNow }
        // Sparkle「安装并重新打开」会发 terminate；更新会话进行中必须放行，
        // 否则按钮无响应，安装永远不会开始。
        if appUpdater.updater.sessionInProgress { return .terminateNow }
        return .terminateCancel
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        toggleCompactPanel()
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let commaMonitor {
            NSEvent.removeMonitor(commaMonitor)
        }
    }

    func requestTermination() {
        allowTermination = true
        NSApp.terminate(nil)
    }

    func showSettings() {
        compactPanel?.hidePanel()
        SettingsWindowController.shared.show()
    }

    private func toggleCompactPanel() {
        guard let panel = compactPanel else { return }
        if panel.isVisible {
            panel.hidePanel()
        } else {
            showPanelBelowStatusItem(attempt: 0)
        }
    }

    private func showPanelBelowStatusItem(attempt: Int) {
        guard let panel = compactPanel else { return }
        let frame = statusItemController?.buttonScreenFrame()
        let screens = NSScreen.screens.map(\.frame)
        if let frame, PanelPlacement.isMenuBarAnchor(frame, screens: screens) {
            panel.show(anchor: frame)
            return
        }
        if attempt < 12 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.showPanelBelowStatusItem(attempt: attempt + 1)
            }
            return
        }
        panel.show(anchor: nil)
    }
}

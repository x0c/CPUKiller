import AppKit
import MacKitCore
import MacKitLifecycle
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) static weak var shared: AppDelegate?
    let listModel = ProcessListModel()
    private var statusItemController: StatusItemController?
    private var compactPanel: CompactPanel?
    private let appUpdater = AppUpdater()
    private let terminationGuard = TerminationGuard()
    private var commaMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        terminationGuard.isUpdateSessionInProgress = { [weak self] in
            self?.appUpdater.updater.sessionInProgress ?? false
        }

        let panel = CompactPanel(model: listModel)
        compactPanel = panel

        statusItemController = StatusItemController(
            onTogglePanel: { [weak self] in self?.toggleCompactPanel() },
            onOpenMainWindow: { [weak self] in self?.showRecoveryWindow() },
            onHideMenuBarIcon: { [weak self] in self?.hideMenuBarIcon() },
            onOpenSettings: { [weak self] in self?.showSettings() },
            onCheckForUpdates: { [weak self] in self?.checkForUpdates() },
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

        if MenuBarReopenPolicy.shouldShowRecoveryWindow(iconVisible: MenuBarIconStore.shared.isVisible) {
            showRecoveryWindow()
        } else if CommandLine.arguments.contains("--show-panel") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.showPanelBelowStatusItem(attempt: 0)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        terminationGuard.shouldTerminate() ? .terminateNow : .terminateCancel
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if MenuBarReopenPolicy.presentation(
            iconVisible: MenuBarIconStore.shared.isVisible,
            isReopenOrLaunch: true
        ) == .showRecoveryWindow {
            showRecoveryWindow()
        }
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let commaMonitor {
            NSEvent.removeMonitor(commaMonitor)
        }
    }

    func requestTermination() {
        terminationGuard.requestTermination()
    }

    func checkForUpdates() {
        appUpdater.checkForUpdates(nil)
    }

    func showSettings() {
        compactPanel?.hidePanel()
        SettingsWindowController.shared.show()
    }

    func showRecoveryWindow() {
        showSettings()
    }

    private func hideMenuBarIcon() {
        compactPanel?.hidePanel()
        MenuBarIconStore.shared.isVisible = false
        showRecoveryWindow()
    }

    private func toggleCompactPanel() {
        guard MenuBarIconStore.shared.isVisible else {
            showRecoveryWindow()
            return
        }
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

import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
final class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()

    private(set) var status = SMAppService.mainApp.status
    private(set) var lastErrorMessage: String?

    private init() {}

    var isEnabled: Bool {
        status == .enabled
    }

    var requiresApproval: Bool {
        status == .requiresApproval
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status == .notRegistered || SMAppService.mainApp.status == .notFound {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status != .notRegistered {
                try SMAppService.mainApp.unregister()
            }
            lastErrorMessage = nil
            refresh()
        } catch {
            refresh()
            lastErrorMessage = String(localized: "settings.launchAtLogin.failed")
        }
    }

    func refresh() {
        status = SMAppService.mainApp.status
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}

import SwiftUI

struct SettingsView: View {
    @Bindable private var launchAtLogin = LaunchAtLoginManager.shared
    @Bindable private var menuBarIcon = MenuBarIconStore.shared
    @FocusState private var focused: Field?

    private enum Field: Hashable {
        case launch
        case openLogin
        case showIcon
        case checkUpdates
    }

    var body: some View {
        Form {
            Section(String(localized: "settings.status")) {
                Text(statusText)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section(String(localized: "settings.general")) {
                Toggle(String(localized: "settings.launchAtLogin"), isOn: launchBinding)
                    .focused($focused, equals: .launch)
                    .focusEffectDisabled()
                    .overlay(alignment: .leading) {
                        focusMark(focused == .launch)
                    }

                Text(String(localized: "settings.launchAtLogin.help"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if launchAtLogin.requiresApproval {
                    Text(String(localized: "settings.launchAtLogin.needsApproval"))
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Button(String(localized: "settings.launchAtLogin.openLoginItems")) {
                        launchAtLogin.openSystemSettings()
                    }
                    .focused($focused, equals: .openLogin)
                    .focusEffectDisabled()
                    .overlay {
                        if focused == .openLogin {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.primary.opacity(0.85), lineWidth: 2)
                        }
                    }
                }

                if let message = launchAtLogin.lastErrorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Toggle(String(localized: "settings.showMenuBarIcon"), isOn: iconBinding)
                    .focused($focused, equals: .showIcon)
                    .focusEffectDisabled()
                    .overlay(alignment: .leading) {
                        focusMark(focused == .showIcon)
                    }

                Button(String(localized: "menu.checkForUpdates")) {
                    AppDelegate.shared?.checkForUpdates()
                }
                .focused($focused, equals: .checkUpdates)
                .focusEffectDisabled()
                .overlay {
                    if focused == .checkUpdates {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.primary.opacity(0.85), lineWidth: 2)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 420, minHeight: 320)
        .focusEffectDisabled()
        .onAppear {
            launchAtLogin.refresh()
        }
    }

    private var statusText: String {
        if menuBarIcon.isVisible {
            String(localized: "settings.running")
        } else {
            String(localized: "settings.running.iconHidden")
        }
    }

    private var launchBinding: Binding<Bool> {
        Binding(
            get: { launchAtLogin.isEnabled },
            set: { launchAtLogin.setEnabled($0) }
        )
    }

    private var iconBinding: Binding<Bool> {
        Binding(
            get: { menuBarIcon.isVisible },
            set: { menuBarIcon.isVisible = $0 }
        )
    }

    @ViewBuilder
    private func focusMark(_ on: Bool) -> some View {
        if on {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Color.primary.opacity(0.85), lineWidth: 2)
                .offset(x: -6)
        }
    }
}

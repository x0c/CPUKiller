import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ProcessRowView: View {
    let row: ProcessRow
    let onEnd: () -> Void
    let onEndHover: (Bool) -> Void
    @State private var hoveringEnd = false
    @FocusState private var isEndFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            icon
            Text(row.displayName)
                .lineLimit(1)
                .allowsTightening(true)
                .minimumScaleFactor(ProcessNamePresentation.minimumScaleFactor)
                .truncationMode(ProcessNamePresentation.truncationMode(for: row.displayName))
                .help(row.displayName)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            Text(ProcessTableRanking.percentText(row.cpuPercent))
                .monospacedDigit()
                .foregroundStyle(heat(row.cpuPercent))
                .frame(width: AppPreferences.metricColumnWidth, alignment: .trailing)
            Text(ProcessTableRanking.percentText(row.memoryPercent))
                .monospacedDigit()
                .foregroundStyle(row.memoryPercent >= 8 ? Color.primary : Color.secondary)
                .frame(width: AppPreferences.metricColumnWidth, alignment: .trailing)
            endButton
        }
        .font(.system(size: ProcessNamePresentation.bodySize))
        .padding(.horizontal, 6)
        .frame(height: 26)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var icon: some View {
        Image(nsImage: iconImage)
            .resizable()
            .interpolation(.high)
            .frame(width: 16, height: 16)
    }

    private var iconImage: NSImage {
        if let path = row.iconPath ?? row.bundlePath {
            return NSWorkspace.shared.icon(forFile: path)
        }
        return NSWorkspace.shared.icon(for: .unixExecutable)
    }

    @ViewBuilder
    private var endButton: some View {
        let enabled = row.isCurrentUser && !row.isSystemProtected
        Button(action: onEnd) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(enabled && hoveringEnd ? Color.red : Color.secondary)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .help(helpText(enabled: enabled))
        .focused($isEndFocused)
        .focusEffectDisabled()
        .overlay {
            if isEndFocused, enabled {
                Circle()
                    .stroke(Color.primary.opacity(0.85), lineWidth: 1.5)
            }
        }
        .accessibilityLabel(String(localized: "table.end"))
        .accessibilityHint(helpText(enabled: enabled))
        .frame(width: AppPreferences.endColumnWidth, height: 22)
        .contentShape(Rectangle())
        .onHover { hovering in
            hoveringEnd = enabled && hovering
            onEndHover(hovering)
        }
        .opacity(enabled && hoveringEnd ? 1 : enabled ? 0.45 : 0.18)
    }

    private func heat(_ value: Double) -> Color {
        if value >= 15 { return .red }
        if value >= 5 { return .orange }
        if value >= 1 { return .primary }
        return .secondary
    }

    private func helpText(enabled: Bool) -> String {
        if row.isSystemProtected {
            return String(localized: "table.end.disabled.system")
        }
        if !row.isCurrentUser {
            return String(localized: "table.end.disabled.otherUser")
        }
        return ""
    }

    private var accessibilityText: String {
        "\(row.displayName), CPU \(ProcessTableRanking.percentText(row.cpuPercent)), \(String(localized: "table.column.memory")) \(ProcessTableRanking.percentText(row.memoryPercent))"
    }
}

nonisolated enum ProcessNamePresentation {
    static let bodySize: CGFloat = 12
    static let minimumScaleFactor: CGFloat = 0.85

    static func truncationMode(for displayName: String) -> Text.TruncationMode {
        looksLikeReverseDNS(displayName) ? .head : .tail
    }

    static func looksLikeReverseDNS(_ displayName: String) -> Bool {
        displayName.contains(".") && !displayName.contains(" ")
    }
}

import AppKit
import SwiftUI

struct NetworkRowView: View {
    let row: NetworkProcessRow
    let onEnd: () -> Void
    let onEndHover: (Bool) -> Void
    @State private var hoveringEnd = false
    @FocusState private var isEndFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(nsImage: iconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 16, height: 16)
            Text(row.displayName)
                .lineLimit(1)
                .allowsTightening(true)
                .minimumScaleFactor(ProcessNamePresentation.minimumScaleFactor)
                .truncationMode(ProcessNamePresentation.truncationMode(for: row.displayName))
                .help(row.displayName)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            rateCell(bytesPerSecond: row.uploadBytesPerSecond)
            rateCell(bytesPerSecond: row.downloadBytesPerSecond)
            endButton
        }
        .font(.system(size: ProcessNamePresentation.bodySize))
        .padding(.horizontal, 6)
        .frame(height: 26)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var iconImage: NSImage {
        if let path = row.process.iconPath ?? row.process.bundlePath {
            return NSWorkspace.shared.icon(forFile: path)
        }
        return NSWorkspace.shared.icon(for: .unixExecutable)
    }

    private func rateCell(bytesPerSecond: Double?) -> some View {
        let parts = NetworkRateFormatter.parts(for: bytesPerSecond)
        let color = bytesPerSecond.map {
            TableMetricPresentation.color(for: $0, metric: .network)
        } ?? Color.secondary
        return HStack(spacing: 2) {
            Text(parts.value)
                .font(.system(size: ProcessNamePresentation.bodySize))
                .monospacedDigit()
            if let unit = parts.unit {
                Text(unit)
                    .font(.system(size: ProcessNamePresentation.unitSize))
            }
        }
        .foregroundStyle(color)
        .frame(width: AppPreferences.metricColumnWidth, alignment: .trailing)
    }

    @ViewBuilder
    private var endButton: some View {
        let enabled = row.process.isCurrentUser && !row.process.isSystemProtected
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
                Circle().stroke(Color.primary.opacity(0.85), lineWidth: 1.5)
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

    private func helpText(enabled: Bool) -> String {
        if row.process.isSystemProtected {
            return String(localized: "table.end.disabled.system")
        }
        if !row.process.isCurrentUser {
            return String(localized: "table.end.disabled.otherUser")
        }
        return ""
    }

    private var accessibilityText: String {
        let upload = String(localized: "table.column.upload")
        let download = String(localized: "table.column.download")
        return "\(row.displayName), \(upload) \(NetworkRateFormatter.text(for: row.uploadBytesPerSecond)), \(download) \(NetworkRateFormatter.text(for: row.downloadBytesPerSecond))"
    }
}

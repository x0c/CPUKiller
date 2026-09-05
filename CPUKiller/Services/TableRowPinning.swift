import Foundation

/// 悬停「结束」时把行钉在原位；进程表与网络表共用同一插入规则。
nonisolated enum TableRowPinning {
    static func pin<Row: Identifiable>(
        _ visible: [Row],
        onto allRows: [Row],
        pinnedID: Row.ID?,
        pinnedIndex: Int?
    ) -> [Row] {
        guard let pinnedID, let pinnedIndex else { return visible }
        guard let pinned = allRows.first(where: { $0.id == pinnedID }) else {
            return visible
        }
        var result = visible.filter { $0.id != pinnedID }
        let index = min(max(pinnedIndex, 0), result.count)
        result.insert(pinned, at: index)
        return result
    }
}

/// 悬停结束钮时的钉行状态机；进程表与网络表行为一致。
@MainActor
enum PinnedEndHover {
    static func apply(
        hovering: Bool,
        rowID: String,
        pinnedRowID: inout String?,
        pinnedIndex: inout Int?,
        unpinTask: inout Task<Void, Never>?,
        visibleIndexForRow: () -> Int?,
        clearPin: @escaping () -> Void,
        currentPinnedID: @escaping () -> String?
    ) {
        if hovering {
            unpinTask?.cancel()
            unpinTask = nil
            if pinnedRowID != rowID {
                pinnedIndex = visibleIndexForRow()
                pinnedRowID = rowID
            }
            return
        }
        guard pinnedRowID == rowID else { return }
        unpinTask?.cancel()
        unpinTask = Task {
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled, currentPinnedID() == rowID else { return }
            clearPin()
        }
    }
}

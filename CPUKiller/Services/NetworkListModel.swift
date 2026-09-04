import Foundation
import Observation

nonisolated enum NetworkSortColumn: String, Sendable {
    case upload
    case download
}

nonisolated enum NetworkTableRanking {
    static func visibleRows(
        from rows: [NetworkProcessRow],
        sort: NetworkSortColumn,
        pinnedID: String? = nil,
        pinnedIndex: Int? = nil
    ) -> [NetworkProcessRow] {
        let ranked = rows.sorted { lhs, rhs in
            let left = sort == .upload ? lhs.uploadBytesPerSecond : lhs.downloadBytesPerSecond
            let right = sort == .upload ? rhs.uploadBytesPerSecond : rhs.downloadBytesPerSecond
            if left != right { return left > right }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
        let visible = Array(ranked.prefix(12))
        guard let pinnedID, let pinnedIndex,
              let pinned = rows.first(where: { $0.id == pinnedID })
        else { return visible }
        var result = visible.filter { $0.id != pinnedID }
        result.insert(pinned, at: min(max(pinnedIndex, 0), result.count))
        return result
    }
}

/// 网络表与 CPU/内存表共享责任进程、图标和结束边界，只替换两列实时速率。
@MainActor
@Observable
final class NetworkListModel {
    static let defaultSortColumn: NetworkSortColumn = .download
    private(set) var rows: [NetworkProcessRow] = []
    private(set) var lastError: String?
    private(set) var isReading = false
    var sortColumn: NetworkSortColumn = defaultSortColumn
    private let sampler = ProcessNetworkSampler()
    private let processRows: @MainActor () -> [ProcessRow]
    private var listLoop: Task<Void, Never>?
    private var isRefreshing = false
    private var pinnedRowID: String?
    private var pinnedIndex: Int?
    private var unpinTask: Task<Void, Never>?

    var refreshEnabled: Bool = AppPreferences.networkRefreshEnabledDefault {
        didSet {
            UserDefaults.standard.set(refreshEnabled, forKey: AppPreferences.networkRefreshEnabledKey)
        }
    }

    init(processRows: @escaping @MainActor () -> [ProcessRow]) {
        self.processRows = processRows
        let defaults = UserDefaults.standard
        refreshEnabled = defaults.object(forKey: AppPreferences.networkRefreshEnabledKey) as? Bool
            ?? AppPreferences.networkRefreshEnabledDefault
    }

    var visibleRows: [NetworkProcessRow] {
        NetworkTableRanking.visibleRows(
            from: rows,
            sort: sortColumn,
            pinnedID: pinnedRowID,
            pinnedIndex: pinnedIndex
        )
    }

    func setPanelVisible(_ visible: Bool) {
        if visible {
            isReading = rows.isEmpty
            start()
        } else {
            stop()
            clearPin()
            isReading = false
            Task { await sampler.reset() }
        }
    }

    func setEndHover(_ hovering: Bool, rowID: String) {
        if hovering {
            unpinTask?.cancel()
            unpinTask = nil
            if pinnedRowID != rowID {
                pinnedIndex = visibleRows.firstIndex { $0.id == rowID }
                pinnedRowID = rowID
            }
            return
        }
        guard pinnedRowID == rowID else { return }
        unpinTask?.cancel()
        unpinTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled, self?.pinnedRowID == rowID else { return }
            self?.clearPin()
        }
    }

    func end(_ row: NetworkProcessRow) async {
        lastError = nil
        switch await ProcessTerminator.end(row.process) {
        case .ended, .blocked:
            break
        case .failed(let message):
            lastError = message
        }
        await refresh()
    }

    private func start() {
        guard listLoop == nil else { return }
        listLoop = Task { [weak self] in
            while !Task.isCancelled {
                let deadline = ContinuousClock.now.advanced(by: .seconds(AppPreferences.networkRefreshInterval))
                await self?.refresh()
                guard !Task.isCancelled else { break }
                try? await Task.sleep(until: deadline, clock: .continuous)
            }
        }
    }

    private func stop() {
        listLoop?.cancel()
        listLoop = nil
    }

    private func refresh() async {
        guard !isRefreshing else { return }
        guard refreshEnabled || rows.isEmpty else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let sampledRates = await sampler.sample()
        // 首帧的一秒采样结束后再取责任进程快照，避免刚启动时把尚未就绪的空名单当成无流量。
        let currentProcesses = processRows()
        isReading = false

        rows = currentProcesses.compactMap { process in
            let total = process.memberPIDs.reduce(
                into: ProcessNetworkRate(receivedBytesPerSecond: 0, sentBytesPerSecond: 0)
            ) { aggregate, pid in
                guard let rate = sampledRates[pid] else { return }
                aggregate = ProcessNetworkRate(
                    receivedBytesPerSecond: aggregate.receivedBytesPerSecond + rate.receivedBytesPerSecond,
                    sentBytesPerSecond: aggregate.sentBytesPerSecond + rate.sentBytesPerSecond
                )
            }
            guard total.receivedBytesPerSecond > 0 || total.sentBytesPerSecond > 0 else { return nil }
            return NetworkProcessRow(
                process: process,
                uploadBytesPerSecond: total.sentBytesPerSecond,
                downloadBytesPerSecond: total.receivedBytesPerSecond
            )
        }
        if let pinnedRowID, !rows.contains(where: { $0.id == pinnedRowID }) {
            clearPin()
        }
    }

    private func clearPin() {
        unpinTask?.cancel()
        unpinTask = nil
        pinnedRowID = nil
        pinnedIndex = nil
    }
}

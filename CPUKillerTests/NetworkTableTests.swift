import AppKit
import XCTest
@testable import CPUKiller

final class ProcessNetworkSamplerTests: XCTestCase {
    func testParsesNettopProcessCounters() {
        let counters = ProcessNetworkSampler.parse("""
        ,bytes_in,bytes_out,
        Google Chrome.42,1024,2048,
        com.example.worker.99,0,7,
        """)
        XCTAssertEqual(counters[42]?.received, 1_024)
        XCTAssertEqual(counters[42]?.sent, 2_048)
        XCTAssertEqual(counters[99]?.received, 0)
        XCTAssertEqual(counters[99]?.sent, 7)
    }
}

final class NetworkTableRankingTests: XCTestCase {
    func testUploadAndDownloadRemainIndependentlyDescending() {
        let rows = [
            makeRow(name: "Upload", upload: 50, download: 2),
            makeRow(name: "Download", upload: 2, download: 80)
        ]
        XCTAssertEqual(
            NetworkTableRanking.visibleRows(from: rows, sort: .upload).map(\.displayName),
            ["Upload", "Download"]
        )
        XCTAssertEqual(
            NetworkTableRanking.visibleRows(from: rows, sort: .download).map(\.displayName),
            ["Download", "Upload"]
        )
    }

    func testPinnedNetworkRowKeepsItsPositionWithNewRates() {
        let rows = [
            makeRow(name: "A", upload: 30, download: 1),
            makeRow(name: "B", upload: 5, download: 90)
        ]
        let visible = NetworkTableRanking.visibleRows(
            from: rows,
            sort: .upload,
            pinnedID: "B",
            pinnedIndex: 0
        )
        XCTAssertEqual(visible.map(\.displayName), ["B", "A"])
        XCTAssertEqual(visible.first?.downloadBytesPerSecond, 90)
    }

    func testRecentlyActiveRowSurvivesZeroRateSample() {
        let chrome = makeProcess(name: "Google Chrome", pid: 42)
        let now = Date(timeIntervalSince1970: 1_000)
        let active = NetworkListPresence.rows(
            processes: [chrome],
            rates: [42: ProcessNetworkRate(receivedBytesPerSecond: 8_192, sentBytesPerSecond: 0)],
            holdUntil: [:],
            now: now
        )
        XCTAssertEqual(active.rows.map(\.displayName), ["Google Chrome"])
        XCTAssertEqual(active.rows.first?.downloadBytesPerSecond, 8_192)

        let quiet = NetworkListPresence.rows(
            processes: [chrome],
            rates: [:],
            holdUntil: active.holdUntil,
            now: now.addingTimeInterval(2)
        )
        XCTAssertEqual(quiet.rows.map(\.displayName), ["Google Chrome"])
        XCTAssertEqual(quiet.rows.first?.downloadBytesPerSecond, 0)
        XCTAssertEqual(quiet.rows.first?.uploadBytesPerSecond, 0)
    }

    func testHoldExpiresAfterFiveSecondsWithoutTraffic() {
        let chrome = makeProcess(name: "Google Chrome", pid: 42)
        let now = Date(timeIntervalSince1970: 1_000)
        let active = NetworkListPresence.rows(
            processes: [chrome],
            rates: [42: ProcessNetworkRate(receivedBytesPerSecond: 1_024, sentBytesPerSecond: 0)],
            holdUntil: [:],
            now: now
        )
        let expired = NetworkListPresence.rows(
            processes: [chrome],
            rates: [:],
            holdUntil: active.holdUntil,
            now: now.addingTimeInterval(NetworkListPresence.holdDuration + 0.01)
        )
        XCTAssertTrue(expired.rows.isEmpty)
        XCTAssertTrue(expired.holdUntil.isEmpty)
    }

    func testDeadProcessIsRemovedEvenDuringHold() {
        let chrome = makeProcess(name: "Google Chrome", pid: 42)
        let now = Date(timeIntervalSince1970: 1_000)
        let active = NetworkListPresence.rows(
            processes: [chrome],
            rates: [42: ProcessNetworkRate(receivedBytesPerSecond: 1_024, sentBytesPerSecond: 0)],
            holdUntil: [:],
            now: now
        )
        let gone = NetworkListPresence.rows(
            processes: [],
            rates: [:],
            holdUntil: active.holdUntil,
            now: now.addingTimeInterval(1)
        )
        XCTAssertTrue(gone.rows.isEmpty)
        XCTAssertTrue(gone.holdUntil.isEmpty)
    }

    private func makeRow(name: String, upload: Double, download: Double) -> NetworkProcessRow {
        NetworkProcessRow(
            process: makeProcess(name: name, pid: 1),
            uploadBytesPerSecond: upload,
            downloadBytesPerSecond: download
        )
    }

    private func makeProcess(name: String, pid: pid_t) -> ProcessRow {
        ProcessRow(
            id: name,
            displayName: name,
            bundlePath: nil,
            iconPath: nil,
            memberIdentities: [ProcessIdentity(pid: pid, startTime: 1)],
            cpuPercent: 0,
            memoryPercent: 0,
            kind: .other,
            isCurrentUser: true,
            isSystemProtected: false
        )
    }
}

@MainActor
final class StatusItemPanelTargetTests: XCTestCase {
    func testRingAndNetworkUseSeparateStatusImages() {
        let ringImage = MenuBarIconRenderer.image(
            cpuPercent: 0,
            memoryPercent: 0
        )
        let networkImage = MenuBarIconRenderer.networkImage(
            uploadBytesPerSecond: nil,
            downloadBytesPerSecond: nil
        )
        XCTAssertEqual(ringImage.size.width, MenuBarIconRenderer.pointSize)
        XCTAssertGreaterThan(networkImage.size.width, 0)
        XCTAssertEqual(ringImage.size.height, networkImage.size.height)
        XCTAssertTrue(ringImage.isTemplate, "圆环必须是模板图，由系统按菜单栏明暗着色")
        XCTAssertTrue(networkImage.isTemplate, "网速块必须是模板图，由系统按菜单栏明暗着色")
        XCTAssertTrue(
            ringImage.representations.contains(where: { $0 is NSBitmapImageRep }),
            "动态绘制必须先栅格成位图，不能只留 NSCustomImageRep 直接往菜单栏画黑笔"
        )
        XCTAssertTrue(
            networkImage.representations.contains(where: { $0 is NSBitmapImageRep }),
            "动态绘制必须先栅格成位图，不能只留 NSCustomImageRep 直接往菜单栏画黑笔"
        )
    }

    func testNetworkTableDefaultsToDownloadOrder() {
        XCTAssertEqual(NetworkListModel.defaultSortColumn, .download)
    }

    func testMenuBarItemsUseFixedVisualOrder() {
        XCTAssertEqual(
            StatusItemPanelTarget.statusItemCreationOrder,
            [.networkDownload, .process]
        )
    }

}

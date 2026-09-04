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

    private func makeRow(name: String, upload: Double, download: Double) -> NetworkProcessRow {
        NetworkProcessRow(
            process: ProcessRow(
                id: name,
                displayName: name,
                bundlePath: nil,
                iconPath: nil,
                memberPIDs: [1],
                cpuPercent: 0,
                memoryPercent: 0,
                kind: .other,
                isCurrentUser: true,
                isSystemProtected: false
            ),
            uploadBytesPerSecond: upload,
            downloadBytesPerSecond: download
        )
    }
}

@MainActor
final class StatusItemPanelTargetTests: XCTestCase {
    func testRingsAndDirectionsHaveSeparateTargets() {
        let image = MenuBarIconRenderer.image(
            cpuPercent: 0,
            memoryPercent: 0,
            uploadBytesPerSecond: nil,
            downloadBytesPerSecond: nil,
            showsNetworkSpeed: true
        )
        let bounds = NSRect(x: 0, y: 0, width: 200, height: 22)
        let imageMinX = bounds.midX - image.size.width / 2
        XCTAssertEqual(
            MenuBarIconRenderer.panelTarget(
                at: NSPoint(x: imageMinX + 9.5, y: 11),
                in: bounds,
                showsNetworkSpeed: true,
                layout: .ringsOnLeft
            ),
            .process
        )
        XCTAssertEqual(
            MenuBarIconRenderer.panelTarget(
                at: NSPoint(x: imageMinX + image.size.width - 1, y: 18),
                in: bounds,
                showsNetworkSpeed: true,
                layout: .ringsOnLeft
            ),
            .networkUpload
        )
        XCTAssertEqual(
            MenuBarIconRenderer.panelTarget(
                at: NSPoint(x: imageMinX + image.size.width - 1, y: 4),
                in: bounds,
                showsNetworkSpeed: true,
                layout: .ringsOnLeft
            ),
            .networkDownload
        )
    }

    func testNetworkTableDefaultsToDownloadOrder() {
        XCTAssertEqual(NetworkListModel.defaultSortColumn, .download)
    }
}

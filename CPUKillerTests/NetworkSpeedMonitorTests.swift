import XCTest
@testable import CPUKiller

final class NetworkSpeedMonitorTests: XCTestCase {
    func testParsesCurrentDefaultRouteInterface() {
        let route = """
        route to: default
        interface: en0
        flags: <UP,GATEWAY,DONE,STATIC>
        """
        XCTAssertEqual(NetworkSpeedMonitor.defaultRouteInterfaceName(from: route), "en0")
    }

    func testMissingDefaultRouteHasNoInterface() {
        XCTAssertNil(NetworkSpeedMonitor.defaultRouteInterfaceName(from: "route to: default\n"))
    }

    func testUsesCompleteRateUnits() {
        XCTAssertEqual(NetworkRateFormatter.text(for: 512), "<1 KB/s")
        XCTAssertEqual(NetworkRateFormatter.text(for: 1_024 * 1_024 * 8.4), "8 MB/s")
        XCTAssertEqual(NetworkRateFormatter.text(for: 1_024 * 1_024 * 1_024 * 2), "2 GB/s")
    }

    func testPairsDirectionsUnderTheirLargestUnit() {
        let pair = NetworkRateFormatter.pair(
            uploadBytesPerSecond: 349 * 1_024,
            downloadBytesPerSecond: 5 * 1_024 * 1_024
        )
        XCTAssertEqual(pair.upload, "<1")
        XCTAssertEqual(pair.download, "5")
        XCTAssertEqual(pair.unit, "MB/s")
    }

    func testMissingSampleUsesDashInsteadOfStaleSpeed() {
        XCTAssertEqual(NetworkRateFormatter.text(for: nil), "—")
    }

    @MainActor
    func testFasterDirectionReceivesTextEmphasis() {
        XCTAssertEqual(
            NetworkSpeedEmphasis.resolve(
                uploadBytesPerSecond: 8_000,
                downloadBytesPerSecond: 2_000
            ),
            .upload
        )
        XCTAssertEqual(
            NetworkSpeedEmphasis.resolve(
                uploadBytesPerSecond: 2_000,
                downloadBytesPerSecond: 8_000
            ),
            .download
        )
    }

    @MainActor
    func testEqualOrMissingRatesRemainVisuallyBalanced() {
        XCTAssertEqual(
            NetworkSpeedEmphasis.resolve(
                uploadBytesPerSecond: 2_000,
                downloadBytesPerSecond: 2_000
            ),
            .balanced
        )
        XCTAssertEqual(
            NetworkSpeedEmphasis.resolve(
                uploadBytesPerSecond: nil,
                downloadBytesPerSecond: 2_000
            ),
            .balanced
        )
    }

    @MainActor
    func testSpeedContrastKeepsStatusItemFrameStable() {
        let uploadDominant = MenuBarIconRenderer.image(
            cpuPercent: 50,
            memoryPercent: 50,
            uploadBytesPerSecond: 8_000,
            downloadBytesPerSecond: 2_000,
            showsNetworkSpeed: true
        )
        let downloadDominant = MenuBarIconRenderer.image(
            cpuPercent: 50,
            memoryPercent: 50,
            uploadBytesPerSecond: 2_000,
            downloadBytesPerSecond: 8_000,
            showsNetworkSpeed: true
        )
        XCTAssertEqual(uploadDominant.size, downloadDominant.size)
        XCTAssertEqual(uploadDominant.size.height, 22)
    }

    @MainActor
    func testLayoutChoiceKeepsStatusItemFrameStable() {
        let ringsOnLeft = MenuBarIconRenderer.image(
            cpuPercent: 50,
            memoryPercent: 50,
            uploadBytesPerSecond: 8_000,
            downloadBytesPerSecond: 2_000,
            showsNetworkSpeed: true,
            layout: .ringsOnLeft
        )
        let speedOnLeft = MenuBarIconRenderer.image(
            cpuPercent: 50,
            memoryPercent: 50,
            uploadBytesPerSecond: 8_000,
            downloadBytesPerSecond: 2_000,
            showsNetworkSpeed: true,
            layout: .speedOnLeft
        )
        XCTAssertEqual(ringsOnLeft.size, speedOnLeft.size)
    }

}

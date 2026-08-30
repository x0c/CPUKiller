import AppKit
import Darwin
import Foundation

nonisolated enum TerminationOutcome: Sendable {
    case ended
    case failed(String)
    case blocked
}

@MainActor
enum ProcessTerminator {
    static func end(_ row: ProcessRow) async -> TerminationOutcome {
        if row.isSystemProtected {
            return .blocked
        }
        if !row.isCurrentUser {
            return .blocked
        }

        switch row.kind {
        case .desktopApp, .chatgpt:
            await endApplication(row)
        case .cursorAgent, .pi, .corral, .namedTool, .other:
            await endInterpreter(row.memberPIDs)
        }

        try? await Task.sleep(for: .milliseconds(200))
        let still = row.memberPIDs.filter(isAlive)
        if still.isEmpty {
            return .ended
        }
        return .failed(String(localized: "table.end.failed"))
    }

    private static func endApplication(_ row: ProcessRow) async {
        var apps: [NSRunningApplication] = []
        if let bundlePath = row.bundlePath {
            let url = URL(fileURLWithPath: bundlePath)
            apps = NSWorkspace.shared.runningApplications.filter { $0.bundleURL == url }
        }
        if apps.isEmpty {
            apps = row.memberPIDs.compactMap { NSRunningApplication(processIdentifier: $0) }
        }
        for app in apps {
            _ = app.terminate()
        }
        try? await Task.sleep(for: .milliseconds(700))
        for app in apps where !app.isTerminated {
            _ = app.forceTerminate()
        }
        await endInterpreter(row.memberPIDs)
    }

    private static func endInterpreter(_ pids: [pid_t]) async {
        for pid in pids where isAlive(pid) {
            kill(pid, SIGTERM)
        }
        try? await Task.sleep(for: .milliseconds(500))
        for pid in pids where isAlive(pid) {
            kill(pid, SIGKILL)
        }
    }

    private static func isAlive(_ pid: pid_t) -> Bool {
        kill(pid, 0) == 0
    }
}

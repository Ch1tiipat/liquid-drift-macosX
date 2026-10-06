import AppKit

/// Log to the terminal with a timestamp in seconds since start. Never prints names, paths or content.
@MainActor
enum Log {
    private static let start = Date()
    private static let ownPID = ProcessInfo.processInfo.processIdentifier
    private static var lastFrontPID = NSWorkspace.shared.frontmostApplication?.processIdentifier

    static func line(_ text: String) {
        let t = Date().timeIntervalSince(start)
        print(String(format: "[%8.3f] ", t) + text)
    }

    /// Focus fields: unchanged since the previous call, and whether this spike is frontmost.
    static func focus() -> String {
        let front = NSWorkspace.shared.frontmostApplication?.processIdentifier
        defer { lastFrontPID = front }
        return "frontmost application unchanged: \(front == lastFrontPID) spike is frontmost: \(front == ownPID)"
    }
}

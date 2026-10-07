import Foundation

/// Terminal log with seconds since start. Never prints pasteboard text, image content or file names.
enum Log {
    private static let start = Date()

    static func line(_ text: String) {
        print(String(format: "[%8.3f] ", Date().timeIntervalSince(start)) + text)
    }

    static func ms(since t0: UInt64) -> String {
        String(format: "%.1f ms", Double(DispatchTime.now().uptimeNanoseconds - t0) / 1_000_000)
    }
}

import Foundation

enum Stamp {
    /// Wall-clock milliseconds since 1970, so hook lines and watcher lines share one time base.
    static func nowMS() -> Int64 {
        Int64((Date().timeIntervalSince1970 * 1000).rounded())
    }
}

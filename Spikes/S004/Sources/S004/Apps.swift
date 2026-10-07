import AppKit

/// The two apps under test. Checks never launch an app.
enum PlayerApp: String, CaseIterable {
    case music = "com.apple.Music"
    case spotify = "com.spotify.client"

    var scriptName: String { self == .music ? "Music" : "Spotify" }

    var installed: Bool { NSWorkspace.shared.urlForApplication(withBundleIdentifier: rawValue) != nil }
    var running: Bool { !NSRunningApplication.runningApplications(withBundleIdentifier: rawValue).isEmpty }

    /// Distributed notification names to observe. Candidates from memory; the spike records which ones arrive.
    var notificationCandidates: [String] {
        switch self {
        case .music: ["com.apple.Music.playerInfo", "com.apple.iTunes.playerInfo"]
        case .spotify: ["com.spotify.client.PlaybackStateChanged"]
        }
    }
}

/// Wall-clock milliseconds, one time base for commands and notifications.
enum Stamp {
    static func nowMS() -> Int64 { Int64((Date().timeIntervalSince1970 * 1000).rounded()) }
}

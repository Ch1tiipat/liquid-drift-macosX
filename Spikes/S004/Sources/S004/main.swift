import AppKit
import MediaPlayer

// Usage:
//   S004 status                              installed / running for Music and Spotify (launches nothing)
//   S004 listen [--seconds 300]              option 1: distributed notifications; prints names and userInfo KEY names
//   S004 read <music|spotify>                option 2: player state and field presence (needs Automation)
//   S004 artwork <music|spotify>             option 2: artwork as data or URL (needs Automation)
//   S004 cmd <music|spotify> <play|pause|playpause|next track|previous track>
//   S004 mpinfo                              option 3: public MPNowPlayingInfoCenter, as seen from this process
// Scripting commands check that the app runs first and are not sent otherwise.
// listen quits by itself after --seconds (default 300). Ctrl+C also stops it.

setvbuf(stdout, nil, _IOLBF, 0)
let arguments = Array(CommandLine.arguments.dropFirst())

func app(_ index: Int) -> PlayerApp {
    guard arguments.count > index, let app = ["music": PlayerApp.music, "spotify": .spotify][arguments[index]] else {
        print("refused: app must be music or spotify"); exit(2)
    }
    return app
}

MainActor.assumeIsolated {
    switch arguments.first {
    case "status":
        for app in PlayerApp.allCases {
            print("\(app.scriptName): installed \(app.installed), running \(app.running)")
        }

    case "listen":
        let seconds = arguments.firstIndex(of: "--seconds").flatMap { Int(arguments[safe: $0 + 1] ?? "") } ?? 300
        print("pid \(ProcessInfo.processInfo.processIdentifier), stops after \(seconds) s or Ctrl+C")
        let center = DistributedNotificationCenter.default()
        for app in PlayerApp.allCases {
            for name in app.notificationCandidates {
                center.addObserver(forName: Notification.Name(name), object: nil, queue: .main) { note in
                    // Key names only. Values can hold titles, artists and albums.
                    let keys = (note.userInfo?.keys.map { "\($0)" } ?? []).sorted()
                    let state = note.userInfo?["Player State"] as? String
                    let enumState = state.map { ["Playing", "Paused", "Stopped"].contains($0) ? $0 : "other" } ?? "none"
                    print("\(Stamp.nowMS()) \(note.name.rawValue): \(keys.count) keys, Player State \(enumState): \(keys.joined(separator: ", "))")
                }
                print("observing \(name)")
            }
        }
        let quit = { (why: String) in print(why); exit(0) }
        signal(SIGINT, SIG_IGN)
        let sigint = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigint.setEventHandler { quit("stopped by Ctrl+C") }
        sigint.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds)) { quit("stopped after \(seconds) s") }
        let ns = NSApplication.shared
        ns.setActivationPolicy(.accessory)
        withExtendedLifetime(sigint) { ns.run() }

    case "read": Script.read(app(1))
    case "artwork": Script.artwork(app(1))
    case "cmd":
        guard arguments.count >= 3 else { print("refused: missing command"); exit(2) }
        Script.command(app(1), arguments[2...].joined(separator: " "))

    case "mpinfo":
        let center = MPNowPlayingInfoCenter.default()
        let keys = center.nowPlayingInfo?.keys.sorted() ?? []
        print("nowPlayingInfo: \(center.nowPlayingInfo == nil ? "nil" : "\(keys.count) keys: \(keys.joined(separator: ", "))")")
        print("playbackState raw value: \(center.playbackState.rawValue)")

    default:
        print("usage: S004 status | listen | read | artwork | cmd | mpinfo")
        exit(2)
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

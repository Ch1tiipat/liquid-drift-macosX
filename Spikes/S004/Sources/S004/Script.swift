import AppKit

/// Option 2: AppleScript through NSAppleScript. Each call first checks that the app runs, so a script never
/// launches it. Prints field presence, counts, state and error numbers, never titles, artists or albums.
@MainActor
enum Script {
    /// Read player state and whether track fields are present.
    static func read(_ app: PlayerApp) {
        let source = """
        tell application "\(app.scriptName)"
            set s to player state as text
            if s is "stopped" then return s & "|no track"
            set t to current track
            set n to (length of (name of t as text)) > 0
            set a to (length of (artist of t as text)) > 0
            set b to (length of (album of t as text)) > 0
            set d to duration of t
            set p to player position
            return s & "|title present " & n & "|artist present " & a & "|album present " & b & "|duration present " & (d > 0) & "|position present " & (p ≥ 0)
        end tell
        """
        run(app, "read", source)
    }

    /// Artwork: count and byte size of the first artwork's data, if any. The data is not kept.
    static func artwork(_ app: PlayerApp) {
        let source: String
        switch app {
        case .music:
            source = """
            tell application "Music"
                if player state is stopped then return "no track"
                set c to count of artworks of current track
                if c is 0 then return "artworks 0"
                set r to raw data of artwork 1 of current track
                -- Return the class of the data only; the data itself is not kept or printed.
                return "artworks " & c & "|raw data class " & ((class of r) as text)
            end tell
            """
        case .spotify:
            source = """
            tell application "Spotify"
                if player state is stopped then return "no track"
                set u to artwork url of current track
                return "artwork url present " & ((length of u) > 0)
            end tell
            """
        }
        run(app, "artwork", source)
    }

    static func command(_ app: PlayerApp, _ verb: String) {
        guard ["play", "pause", "playpause", "next track", "previous track"].contains(verb) else {
            print("refused: unknown command"); return
        }
        run(app, verb, "tell application \"\(app.scriptName)\" to \(verb)")
    }

    private static func run(_ app: PlayerApp, _ label: String, _ source: String) {
        guard app.running else { print("\(Stamp.nowMS()) \(app.scriptName) \(label): not running, not sent"); return }
        let t0 = Stamp.nowMS()
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        let t1 = Stamp.nowMS()
        if let error {
            let number = error[NSAppleScript.errorNumber] as? Int ?? 0
            print("\(t1) \(app.scriptName) \(label): error \(number), \(t1 - t0) ms (sent at \(t0))")
        } else {
            print("\(t1) \(app.scriptName) \(label): ok, \(t1 - t0) ms (sent at \(t0)) -> \(result?.stringValue ?? "no value")")
        }
    }
}

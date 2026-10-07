# S-004 findings: Now Playing from Spotify and Apple Music

## Environment

```
ProductName:    macOS
ProductVersion: 27.0.1
BuildVersion:   26A434
Xcode 27.0
Build version 27A266a
Apple Swift version 6.4 (swiftlang-6.4.0.34.1 clang-2100.3.34.1)
arm64
```

## How to run

```
swift build --package-path Spikes/S004
B=Spikes/S004/.build/debug/S004
$B status                          # installed / running for Music and Spotify; launches nothing
$B listen --seconds 300            # option 1: distributed notifications (names, key names, Player State)
$B mpinfo                          # option 3: public MPNowPlayingInfoCenter, read from this process
$B read music                      # option 2: player state and field presence (Automation)
$B artwork music                   # option 2: artwork count and data class (Automation)
$B cmd music "next track"          # option 2: play, pause, playpause, next track, previous track
```

- Every scripting call checks `NSRunningApplication` first and is not sent when the app is not running.
- `listen` is an AppKit app with the accessory activation policy; it stops after `--seconds` and on Ctrl+C.
- Output holds notification names, userInfo key names, `Player State` values, field presence, counts and timings.
  No title, artist, album, genre or playlist value is printed.

## Answers

Latency: for option 2 commands, the time from sending the command to the first matching `com.apple.Music.playerInfo`
notification, on one wall clock. Option 1 alone has no latency figure: the moment the owner pressed a button in
Music was not recorded by code.

| App | Option | Works | Permission | Latency | App closed |
|---|---|---|---|---|---|
| Apple Music | 1 distributed notifications | YES | none asked | see option 2 rows for timing | quitting gave one notification with `Player State` `Paused` and no other key; no relaunch; listener kept running |
| Apple Music | 2 AppleScript (read state, fields, artwork) | YES | Automation; the prompt named the terminal app, not the spike; owner allowed | 226 ms per read after consent (first read 6,086 ms including the prompt) | read refused by the spike (not running, not sent); Music stayed closed |
| Apple Music | 2 AppleScript (play, pause, next, previous) | YES | same Automation consent | command round trip 135 to 149 ms; pause to `Paused` 175 to 178 ms; play to `Playing` 122 to 130 ms; next to first notification 571 to 573 ms; previous 433 ms | command refused by the spike (not running, not sent); Music stayed closed |
| Apple Music | 3 public system-wide API | NO | none asked | `MPNowPlayingInfoCenter` returned `nil` and playback state 0 while Music played | not applicable |
| Apple Music | 4 simulated media keys | UNCONFIRMED | not tried | not tried: option 2 works | not tried |
| Spotify | 1 distributed notifications | UNCONFIRMED | not installed | no `com.spotify.client.PlaybackStateChanged` arrived (app not installed) | not tested |
| Spotify | 2 AppleScript | UNCONFIRMED | not installed | not tested | not tested |
| Spotify | 3 public system-wide API | NO | none asked | same `MPNowPlayingInfoCenter` result as above; the API reflects this process | not applicable |
| Spotify | 4 simulated media keys | UNCONFIRMED | not tried | not tried | not tried |

Other answers:

| Question | Answer | Evidence |
|---|---|---|
| Music notifications still carry content on macOS 27 | YES | 118 notifications seen; userInfo key names `Player State`, `Name`, `Album`, `Artist`, `Genre` (some notifications carried `Player State` alone or with `Name`) |
| Music track fields readable by script | YES | title, artist, album and position present; duration not present for the track played (guess, UNCONFIRMED: a stream) |
| Music artwork as local data | YES | `artworks 1`, raw data class `«class tdta»` (data, not a URL); byte size not measured |
| Music artwork in the notification | NO | no artwork key among the userInfo keys |
| A system-wide public API exists | NO | private API only: the public `MPNowPlayingInfoCenter` reads this process's own info; `MediaRemote` is in `PrivateFrameworks` of the SDK and was not loaded |
| Scripting a closed app launches it | NO | in the runs we did, the spike checked `NSRunningApplication` and did not send; `status` showed Music not running 3 s later |

### Observations

- Music posts each notification under two names at the same millisecond: `com.apple.Music.playerInfo` and
  `com.apple.iTunes.playerInfo`. A provider should observe one of them.
- On a track change, notifications arrive in a burst: first `Player State` alone, then with `Name`, later with
  `Album`, `Artist`, `Genre`. A provider should wait or merge before showing fields.
- After a pause or play command, a notification with the old state came 117 to 127 ms after the command, then the
  new state 3 to 61 ms later. A provider should use the last notification of a burst.
- The Automation prompt appeared once; later scripts ran without a prompt in this session.

### Recommendation (input for ADR-008; the owner decides)

- `AppleMusicProvider`: track and state from distributed notifications (no permission in these runs); controls and
  artwork through AppleScript, which needs the Automation permission. Ask for Automation when the user first uses a
  control or wants artwork, not at module start. Check `NSRunningApplication` before every script.
- `SpotifyProvider`: same shape is the likely design, UNCONFIRMED; Spotify was not installed.
- No public system-wide now-playing API was found; the system-wide path is private API only and is not used.
- Permission results come from a bare executable started in a terminal, and the prompt named the terminal app.
  Repeat in Phase 1 with an app bundle.

## Limits

- Bare executable started from a terminal, not an app bundle. The Automation prompt named the terminal app, so the
  consent belongs to the terminal app; every permission result is UNCONFIRMED for an app bundle.
- Nothing tested on macOS 15. One Music version, one track source.
- Spotify was not installed; all Spotify rows except option 3 are UNCONFIRMED.
- The race between the running check and sending a script (the app quits in between) was not tested.
- Whether compiling a `tell application "Music"` script can launch Music was not isolated; in these runs scripts
  were sent with Music running.
- Option 1 latency for buttons pressed in Music was not measured.

## Open items

- Spotify: options 1, 2 and 4 with the app installed.
- Option 4 (simulated media keys) and its permission: not tried.
- Artwork byte size and image format: not measured.
- Automation consent denied, and consent reset: not tested.
- Notifications while another app plays audio, and with no network: not tested.
- Docs read: none; names come from the SDK headers and runs.

## VERIFY items answered

- `docs/FEATURES.md`, Now Playing providers, "The system-wide media API may be restricted on new macOS": answered
  for public API: none found that reads other apps; private API only. Suggest replacing the VERIFY with that.
- `docs/FEATURES.md`, F-07 permissions "Automation or none": Music track info needed no permission (notifications);
  controls and artwork needed Automation. Spotify still VERIFY. Keep VERIFY for an app bundle.
- `docs/ARCHITECTURE.md`: no Now Playing VERIFY item there; ADR-008 input above.

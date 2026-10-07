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
| Apple Music | 1 distributed notifications | YES | none asked, from a terminal-started executable; UNCONFIRMED for an app bundle | see option 2 rows for timing | quitting gave one notification with `Player State` `Paused` and no other key; no relaunch; listener kept running |
| Apple Music | 2 AppleScript (read state, fields, artwork) | YES | Automation; the prompt named the terminal app, not the spike (owner answer only); owner allowed | 226 ms per read after consent; the first read took 6,086 ms (printed by code), which included the prompt (owner answer only) | read refused by the spike (not running, not sent); Music stayed closed |
| Apple Music | 2 AppleScript (play, pause, next, previous) | YES | same Automation consent | command round trip 135 to 149 ms; pause to `Paused` 175 to 178 ms; play to `Playing` 122 to 130 ms; next to first notification 571 to 573 ms; previous 433 ms | command refused by the spike (not running, not sent); Music stayed closed |
| Apple Music | 3 public system-wide API | NO | none asked | none found in what we checked (see the row "A public system-wide API exists"); `MPNowPlayingInfoCenter` returned `nil` and playback state 0 while Music played, as expected for an API that holds this process's own info | not applicable |
| Apple Music | 4 simulated media keys | UNCONFIRMED | not tried | not tried: option 2 works | not tried |
| Spotify | 1 distributed notifications | UNCONFIRMED | not installed | no `com.spotify.client.PlaybackStateChanged` arrived (app not installed) | not tested |
| Spotify | 2 AppleScript | UNCONFIRMED | not installed | not tested | not tested |
| Spotify | 3 public system-wide API | UNCONFIRMED | not installed | not tested with Spotify; the header search below is not app specific | not tested |
| Spotify | 4 simulated media keys | UNCONFIRMED | not tried | not tried | not tried |

Other answers:

| Question | Answer | Evidence |
|---|---|---|
| Music notifications still carry content on macOS 27 | YES | 58 notifications under each of the two names (116 in all); userInfo key names `Player State`, `Name`, `Album`, `Artist`, `Genre` (some notifications carried `Player State` alone or with `Name`) |
| Music track fields readable by script | YES | title, artist, album and position present; duration not present for the track played |
| Music artwork as local data | YES | `artworks 1`, raw data class `«class tdta»` (data, not a URL); byte size not measured |
| Music artwork in the notification | NO | no artwork key among the userInfo keys |
| A public system-wide API exists | NO | none found in what we checked: a recursive `grep` for `NowPlaying` or `nowPlaying` over the public framework headers of the macOS 27 SDK gave 19 files. In `MediaPlayer`, `MPNowPlayingInfoCenter` publishes this process's own info, and `MPMusicPlayerController` and `MPNowPlayingSession` are not available on macOS (header annotations). The other 16 files were not read one by one. The system-wide path found in the SDK is private (`MediaRemote` in `PrivateFrameworks`); not loaded |
| Scripting a closed app launches it | UNCONFIRMED | guard prevented sending; not tested. The spike checked `NSRunningApplication` and did not send; `status` showed Music not running 3 s later |

### Observations

- Music posted each of the 58 notifications under two names at the same millisecond (within 1 ms):
  `com.apple.Music.playerInfo` and `com.apple.iTunes.playerInfo`. Suggestion: a provider observes one of them.
- Key counts per notification: 1 key (`Player State`) 7 times, 2 keys (`Name`, `Player State`) 12 times, 5 keys
  39 times. In 5 places a notification with fewer keys followed a full one, at a track start or change, and the full
  set came later. Suggestion: a provider merges or waits briefly before showing fields.
- In 4 of 4 play or pause commands, a notification with the old state came 117 to 127 ms after the command, then
  the new state 3 to 61 ms later. Suggestion: a provider uses the last notification of a burst.
- The Automation prompt appeared once; later scripts ran without a prompt in this session.

### Recommendation (input for ADR-008; the owner decides)

- `AppleMusicProvider`: track and state from distributed notifications (no permission in these runs, from a
  terminal-started executable; UNCONFIRMED for an app bundle); controls and
  artwork through AppleScript, which needs the Automation permission. Ask for Automation when the user first uses a
  control or wants artwork, not at module start. Check `NSRunningApplication` before every script.
- `SpotifyProvider`: same shape is the likely design, UNCONFIRMED; Spotify was not installed.
- No public system-wide now-playing API was found in what we checked; the system-wide path found in the SDK is
  private (`MediaRemote`); not loaded.
- Permission results come from a bare executable started in a terminal, and the prompt named the terminal app
  (owner answer only).
  Repeat in Phase 1 with an app bundle.

## Limits

- Bare executable started from a terminal, not an app bundle. The Automation prompt named the terminal app (owner
  answer only), so the
  consent belongs to the terminal app; every permission result is UNCONFIRMED for an app bundle.
- Nothing tested on macOS 15. One Music version, one track source.
- Spotify was not installed; all Spotify rows are UNCONFIRMED.
- The race between the running check and sending a script (the app quits in between) was not tested.
- Whether compiling a `tell application "Music"` script can launch Music was not isolated; in these runs scripts
  were sent with Music running.
- Option 1 latency for buttons pressed in Music was not measured.

## Open items

- Spotify: options 1, 2, 3 and 4 with the app installed, and Spotify artwork (URL or data).
- Option 1 latency when the owner presses a button in Music (task card step 2): not measured.
- Option 4 (simulated media keys) and its permission: not tried.
- Music artwork byte size and image format: not measured.
- Read the other 16 SDK headers found by the search, and the Apple docs, for a public API that reads another app's
  now-playing info.
- Automation consent denied, and consent reset: not tested.
- Notifications while another app plays audio, and with no network: not tested.
- Docs read: none; names come from the SDK headers and runs.

## VERIFY items answered

- `docs/FEATURES.md`, Now Playing providers, "The system-wide media API may be restricted on new macOS": answered
  partly. No public API that reads other apps was found in what we checked; the system-wide path found in the SDK
  is private (`MediaRemote`). Suggest writing that, and keeping VERIFY until the header and docs search in Open
  items is done.
- `docs/FEATURES.md`, F-07 permissions "Automation or none": Music track info needed no permission (notifications,
  terminal-started executable);
  controls and artwork needed Automation. Spotify still VERIFY. Keep VERIFY for an app bundle.
- `docs/ARCHITECTURE.md`: no Now Playing VERIFY item there; ADR-008 input above.

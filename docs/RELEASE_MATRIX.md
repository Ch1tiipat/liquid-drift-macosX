# Release matrix

Fill the Result column on a real Mac. Use: PASS, FAIL, N/A, and a note.

Environment: macOS ______  Xcode ______  Mac model ______  Date ______

| # | Scenario | Expected | Result |
|---|---|---|---|
| 1 | Notch position and size are correct | Island matches the notch | |
| 2 | App in full screen | Island still reachable | |
| 3 | Switch between Spaces | Island present on every Space | |
| 4 | Stage Manager on | Island still works | |
| 5 | Mission Control | No broken state afterwards | |
| 6 | External display connected | Defined behavior, no crash | |
| 7 | Lid closed, then opened | Island recovers | |
| 8 | Sleep and wake | Island recovers, observers restored | |
| 9 | Light and dark appearance | Readable | |
| 10 | Reduce Motion on | No spring animation | |
| 11 | Switch a module off | CPU about 0 for that module | |
| 12 | Quit and relaunch | Settings and mode restored | |
| 13 | Launch at login | Starts without a Dock icon | |
| 14 | Clipboard: password manager copy | Item is not stored | |
| 15 | Clipboard: large image | No hang, size limit works | |
| 16 | Shelf: delete file after adding | Shows missing state, no crash | |
| 17 | Now Playing: Spotify | Title, artist, controls work | |
| 18 | Now Playing: Apple Music | Title, artist, controls work | |
| 19 | Screen recording on | Behavior as designed | |
| 20 | Idle CPU and energy | Near zero in Activity Monitor | |

# S-002 findings: panel across Spaces, full screen, Stage Manager, Mission Control, sleep and wake

Throwaway spike. Do not merge into the app. Tested on one MacBook Air M4, built-in display only.
Nothing here is tested on macOS 15.

## Environment

```
ProductName:		macOS
ProductVersion:		27.0.1
BuildVersion:		26A434
Xcode 27.0
Build version 27A266a
swift-driver version: 1.168.6 Apple Swift version 6.4 (swiftlang-6.4.0.34.1 clang-2100.3.34.1)
Target: arm64-apple-macosx27.0.0
arm64
```

## How to run

```
swift build --package-path Spikes/S002
Spikes/S002/.build/debug/S002 --info
Spikes/S002/.build/debug/S002 --behavior base|spacesOnly|stationary \
    --level mainMenu|statusBar|popUpMenu|screenSaver --seconds 300
```

The panel is the S-001 variant B pill, with the `constrainFrameRect` override kept.
Collection behaviors: `base` = `[.canJoinAllSpaces, .fullScreenAuxiliary]`, `spacesOnly` = `[.canJoinAllSpaces]`,
`stationary` = `base` + `.stationary`. The app quits by itself after `--seconds`; Ctrl+C or `pkill -x S002` also stops it.

Every log line prints the event, the raw panel frame, the expected frame, `isVisible`, whether `occlusionState`
contains `.visible`, and two focus fields:

- `frontmost application unchanged`: compared with the previous log line (process identifiers only). The owner
  switched apps on purpose during the scenarios, so a `false` here is expected and is not a focus steal.
- `spike is frontmost`: whether the spike process itself became the frontmost app. This is the focus-steal check.

## Scenarios

All runs `--behavior base --level statusBar` unless the row says otherwise.

| Scenario | Result | Workaround | Evidence |
|---|---|---|---|
| a. Second Space | YES | — | Owner: visible on both desktops, same place. Log: 11 `activeSpaceDidChange` events, every one at frame (629, 900, 211-212, 56), `isVisible=true`, no FRAME MISMATCH. An earlier owner answer ("yes, both") was given before a second desktop existed (log had no Space event, and the owner later said only one desktop was open); it was discarded. |
| b. Full-screen app | NO | none found | Owner screenshots (not committed) in full screen show only the lower part of the pill: the top band of the screen (0 to about 33 pt) covers the upper part, both while the menu bar is hidden and while it is shown. Tried one change at a time: `--level popUpMenu`, `--level screenSaver`, `--behavior stationary`, `--behavior spacesOnly`; owner saw the same lower-part-only result each time (screenshots for `screenSaver` and `stationary`; owner answer only for `popUpMenu` and `spacesOnly`). One owner answer ("full pill", `stationary`) disagreed with a screenshot taken right after it and was discarded. The menu bar stays clickable (screenshot). Frame stayed at y = 900 in every full-screen run, no FRAME MISMATCH, so this is drawing order, not a frame change. `.ignoresCycle` was not tried: it only affects window cycling, not drawing order. What the owner sees: in a full-screen app only the part of the pill below the top band is visible. Levels above `.screenSaver` (1000), for example the screen-shield level, were not tried, so NO holds only for the levels and behaviors listed here. |
| c. Stage Manager | YES | — | Owner: panel stays in place while windows are rearranged. Log: frame constant, `isVisible=true`, no FRAME MISMATCH. No screenshot, and no notification tells code that Stage Manager is on, so this rests on the owner answer. |
| d. Mission Control | YES | — | Owner: visible during Mission Control and back in place after. Log: no `didMove`, no FRAME MISMATCH, frame constant. No temporary MISMATCH appeared. |
| e. Sleep and wake | YES with `stationary`; UNCONFIRMED with `base` | — | Run `--behavior stationary`: log `willSleep`, `screensDidWake`, `didWake`, frame (629, 900, 212, 56) before and after, `isVisible=true`, no FRAME MISMATCH. Owner: visible in the same place after wake; owner screenshot taken after wake shows the pill on the notch. The owner chose not to repeat sleep with `base`. |
| f. Click and focus | YES | — | 6 `panel click` lines across runs; every log line in every run has `spike is frontmost: false`. The panel never became the frontmost app. |
| g. Show Desktop (click the wallpaper), found during the test | NO with `base`; WORKAROUND with `stationary` | `--behavior stationary` | `base`: owner screenshot shows the pill gone from the notch while windows are pushed to the screen edges; a thin line at the bottom edge matches the pill width (best guess: the pill was pushed off-screen with the other windows). Log frame did not change, so code cannot see this. `stationary`: owner screenshot in the same state shows the pill on the notch; a later recheck run gave the same owner answer. Note: the fix is only active when the spike runs with `--behavior stationary`. |

## Predictions for docs/RELEASE_MATRIX.md

| Row | Scenario | Prediction | Reason |
|---|---|---|---|
| 2 | App in full screen | UNCONFIRMED | Part of the pill stays visible below the top band, but the upper part is hidden at every level and behavior tried. Clicking the panel inside a full-screen Space was not tested, so "still reachable" is not proven. The island design needs a full-screen rule (see VERIFY items). |
| 3 | Switch between Spaces | PASS | Scenario a. |
| 4 | Stage Manager on | PASS | Scenario c, owner answer only. |
| 5 | Mission Control | PASS | Scenario d. |
| 8 | Sleep and wake | UNCONFIRMED | The panel recovered after wake with `stationary` (scenario e), and the sleep and wake notifications arrived. Not tested with `base`, and no event after wake proves that every observer still works. |

## Carry-over from S-001

### Q4 display scaling

`System Settings > Displays` on this Mac had "Show all resolutions" switched on, so the options are a list of sizes,
not named thumbnails. This probably explains S-001: the scaling was never really changed there (not proven). The owner's original option is
`1470 x 956` (labelled as the default). The owner set it back at the end (log shows frame 1470 x 956 again).

| Option (as listed) | frame (pt) | Notch rect | Panel frame after reposition | Owner: lines up |
|---|---|---|---|---|
| 1470 x 956 (default) | 1470 x 956 | (645.5, 924, 179, 32) | (629, 900, 211, 56) | yes (S-001 and this run) |
| 1710 x 1112 (more space) | 1710 x 1112 | (751, 1074.5, 208, 37.5) | (735, 1050, 240, 62) | yes |
| 1280 x 832 (larger text) | 1280 x 832 | (562, 804, 156, 28) | (546, 780, 188, 52) | yes |

Each change printed a screen-parameters event with a different frame size. Result: YES, the notch rect and the
panel follow the scaling. No screenshot for the two non-default options; the frame evidence is from code.

### Window level recheck

Asked on a normal desktop (not full screen). Every answer below was given while the printed frame was within 1.0 pt
of the expected frame. Answers discarded because of a FRAME MISMATCH: 0. Answers discarded because a screenshot
contradicted them: 2 (one level answer given while a full-screen app was active, and one Control Center answer).

Q3 again, "is the panel drawn above the menu bar area":

| Level | Owner answer | Evidence |
|---|---|---|
| `.mainMenu` (24) | yes | owner answer |
| `.statusBar` (25) | yes | owner answer and screenshot |
| `.popUpMenu` (101) | yes | owner answer and screenshot |
| `.screenSaver` (1000) | yes | owner answer; screenshot from a scenario b run on a normal desktop also shows it |

Side effects ("does the panel cover any part of it"):

| Level | Control Center | Spotlight | Widest app menu near the notch |
|---|---|---|---|
| `.statusBar` | no (screenshot: no overlap) | UNCONFIRMED (owner could not tell; screenshot taken after Spotlight closed) | UNCONFIRMED (owner: no overlap; but the same menu reaches under the pill at `.popUpMenu`, so the areas do overlap and only the drawing order is unknown) |
| `.popUpMenu` | no (owner) | not asked | yes: screenshot shows the pill drawn over the top-right corner of the open menu |

Suggestion: keep `.statusBar` as the Phase 1 starting point. `.popUpMenu` draws over open app menus.

## Frame mismatch

Rule: the expected frame is the S-001 variant B formula applied to the current notch rect, recomputed at every log
line from the current screen values. FRAME MISMATCH is added only when x, y, width or height differs from the
expected value by more than 1.0 pt. The raw frame is printed every time.

All 13 FRAME MISMATCH lines happened in the Q4 scaling run, in the moment between a scaling change and the
reposition. Each one is followed by a "after reposition" line within tolerance:

```
[panel didChangeScreen] frame (629.0, 900.0, 211.0, 56.0) expected (735.0, 1050.5, 240.0, 61.5) FRAME MISMATCH
[didChangeScreenParameters] frame (629.0, 900.0, 211.0, 56.0) expected (735.0, 1050.5, 240.0, 61.5) FRAME MISMATCH
[panel didChangeScreen] frame (629.0, 900.0, 240.0, 62.0) expected (629.5, 900.0, 211.0, 56.0) FRAME MISMATCH
[panel didMove] frame (629.0, 900.0, 240.0, 62.0) expected (629.5, 900.0, 211.0, 56.0) FRAME MISMATCH
[didChangeScreenParameters] frame (629.0, 900.0, 240.0, 62.0) expected (629.5, 900.0, 211.0, 56.0) FRAME MISMATCH
[panel didChangeScreen] frame (735.0, 1050.0, 211.0, 56.0) expected (735.0, 1050.5, 240.0, 61.5) FRAME MISMATCH
[panel didMove] frame (735.0, 1050.0, 211.0, 56.0) expected (735.0, 1050.5, 240.0, 61.5) FRAME MISMATCH
[didChangeScreenParameters] frame (735.0, 1050.0, 211.0, 56.0) expected (735.0, 1050.5, 240.0, 61.5) FRAME MISMATCH
[panel didChangeScreen] frame (735.0, 1050.0, 240.0, 62.0) expected (546.0, 780.0, 188.0, 52.0) FRAME MISMATCH
[didChangeScreenParameters] frame (735.0, 1050.0, 240.0, 62.0) expected (546.0, 780.0, 188.0, 52.0) FRAME MISMATCH
[panel didChangeScreen] frame (629.0, 900.0, 188.0, 52.0) expected (629.5, 900.0, 211.0, 56.0) FRAME MISMATCH
[panel didMove] frame (629.0, 900.0, 188.0, 52.0) expected (629.5, 900.0, 211.0, 56.0) FRAME MISMATCH
[didChangeScreenParameters] frame (629.0, 900.0, 188.0, 52.0) expected (629.5, 900.0, 211.0, 56.0) FRAME MISMATCH
```

First appearance: Q4, first change from 1470 x 956 to 1710 x 1112. The sequence of sizes in the log is
1470 → 1710 → 1470 → 1710 → 1280 → 1470 (the owner briefly went back to the default once).
Best explanation (UNCONFIRMED): the screen changes first and the panel keeps its old frame until our handler calls
`setFrame`; some lines show the system already moved the origin but kept the old size. These are transient and expected.

No FRAME MISMATCH appeared in any Space, full-screen, Stage Manager, Mission Control, Show Desktop or sleep and wake
run. The S-001 position bug (y = 867) did not reappear with the `constrainFrameRect` override in place.

Related, UNCONFIRMED: in full screen the upper part of the pill is hidden **without** any frame change (scenario b).
The S-001 screenshot that showed the pill 'below the menu bar' may have been taken with a full-screen app in front (a guess; it is not known). This guess does not explain the S-001 bug by itself: S-001 reports the panel frame at y = 867 and a full-height pill below the bar, while in full screen S-002 saw the frame stay at y = 900 and only the lower part of the pill. Keep the `constrainFrameRect` override in the Phase 1 notes until a run without the override shows it is not needed.

`occlusionVisible` was `false` on several `activeSpaceDidChange` lines and on the first line after showing the panel,
while the owner saw the pill. It looks like occlusion is updated after the transition; it is not a reliable
visibility signal at the moment of an event (UNCONFIRMED).

## Limits

- Bare executable started from a terminal, not an app bundle.
- Built-in display only, one display. No external display.
- Nothing tested on macOS 15.
- The log went to the terminal session (background command output outside the repo); no log file is in the repo.
- Several results rest on owner answers without a screenshot; the Evidence column says which.

## Open items

- Full screen: try levels above `.screenSaver` (for example the shield level). The top band may be drawn by the system outside normal window levels. This is not known.
- `.stationary`: only scenarios e and g were run with it. Rerun a, c, d and f with `--behavior stationary` before adopting it.
- Window level `.statusBar`: Spotlight and the widest app menu are UNCONFIRMED. Check with a screenshot taken while they are open.
- The `constrainFrameRect` override was always on in S-002. A run without it would show whether the S-001 y = 867 comes back, and when.
- Not tested: clicking the panel in a full-screen Space, an external display, macOS 15, an app bundle.

## VERIFY items answered

- `docs/ARCHITECTURE.md`, "Panel (VERIFY on macOS 27)": `canJoinAllSpaces` + `fullScreenAuxiliary` works for Spaces,
  Stage Manager and Mission Control. Suggest adding:
  - `.stationary`, because without it the panel is pushed away by Show Desktop (scenario g). Only scenarios e and g were run with it (see Open items).
  - A note that in a full-screen app the top band hides the upper part of the panel at every level tried, so the
    island needs a full-screen rule (for example: content only below the notch, or a presentation mode).
  - `constrainFrameRect` override (already suggested in S-001).
- `docs/ARCHITECTURE.md`, "Notch geometry (VERIFY)": the notch rect and the panel follow display scaling
  (1710 x 1112 and 1280 x 832 tested). Suggest noting that the notch height changes with scaling (37.5 / 32 / 28 pt).
- `docs/FEATURES.md`: no VERIFY item there is answered by this spike.

Not edited: no doc outside `Spikes/S002/` and the four agreed edits in `Spikes/S001/FINDINGS.md`. The owner decides.

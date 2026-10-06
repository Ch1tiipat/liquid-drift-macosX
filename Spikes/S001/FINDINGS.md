# S-001 findings: notch geometry, panel placement, hotkey

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
swift build --package-path Spikes/S001
Spikes/S001/.build/debug/S001 --info                       # print screen values and quit
Spikes/S001/.build/debug/S001 --variant A|B --level mainMenu|statusBar|popUpMenu|screenSaver|custom \
    --hotkey none|carbon|monitor --seconds 180
```

The app has no menu and no Dock icon. It quits by itself after `--seconds` (default 180). Ctrl+C or `pkill -x S001` also stops it.

## Answers

| Question | Answer | Evidence |
|---|---|---|
| Q1 notch size readable | YES | `safeAreaInsets.top` = 32, `auxiliaryTopLeftArea` / `auxiliaryTopRightArea` both present. Two formulas give the same rect (see Formulas). |
| Q2 panel hugging the notch | YES | Owner confirmed variant A and variant B line up with the notch. Owner screenshot (not committed) shows the pill centered over the notch, above the menu bar. |
| Q3 window level above menu bar | YES | Owner confirmed the panel is drawn above the menu bar at every level tried. Lowest tried: `.mainMenu` (24). |
| Q4 display scaling | UNCONFIRMED | The scaling option was never actually changed: the screen stayed 1470 x 956 pt in all reads and in owner screenshots (2940 x 1912 px). The repositioning path was exercised by Dock-area changes only (see Scaling table). |
| Q5 hotkey without Accessibility | YES | Carbon `RegisterEventHotKey` (Control+Option+Command+L) returned status 0. Owner pressed it twice: panel hid, then came back (log: `visible = false`, then `visible = true`). Owner saw no permission prompt. |
| Q6 hotkey with Accessibility | UNCONFIRMED | `NSEvent.addGlobalMonitorForEvents` without trust: `AXIsProcessTrusted()` = false, monitor object returned, but key presses were never delivered and no prompt appeared (owner confirmed). Owner chose not to grant Accessibility (see Hotkeys limit). |
| Focus check | YES | `frontmost application unchanged: true` in every run (10 runs). |
| macOS 15 deployment target builds | YES (build only) | `swift build` with `platforms: [.macOS(.v15)]` and Swift 6 mode compiled with `-target arm64-apple-macos15.0`, no warnings. Says nothing about running on macOS 15. |

## Formulas

All numbers use AppKit global screen coordinates: origin at the bottom-left of the primary screen, y grows up.
Values read on the built-in display at the default scaling:

```
frame                 x=0     y=0    w=1470   h=956
visibleFrame          x=0     y=64   w=1470   h=859
safeAreaInsets        top=32  left=0 bottom=0 right=0
auxiliaryTopLeftArea  x=0     y=924  w=645.5  h=32
auxiliaryTopRightArea x=824.5 y=924  w=645.5  h=32
backingScaleFactor    2.0
```

Notch rect (both formulas checked against the real values and they agree):

```
height = safeAreaInsets.top                                   = 32
y      = frame.maxY - height                                  = 924
x      = auxiliaryTopLeftArea.maxX                            = 645.5
width  = auxiliaryTopRightArea.minX - auxiliaryTopLeftArea.maxX = 179
# same result from the width form:
x      = frame.minX + auxiliaryTopLeftArea.width               = 645.5
width  = frame.width - topLeft.width - topRight.width          = 179
```

The edge form (`maxX` / `minX`) is the one used in code. It does not depend on `frame.minX`, so it should also hold
for a screen that is not at origin (not tested).

Panel frames:

```
Variant A = notch                                  = (645.5, 924, 179, 32)
Variant B = (notch.minX - 16, notch.minY - 24,
             notch.width + 32, notch.height + 24)  = (629.5, 900, 211, 56)
```

AppKit rounds the window frame to whole points: variant A came out as (645, 924, 180, 32) and variant B as
(629, 900, 212, 56) at first show, (629, 900, 211, 56) after `setFrame`. Half-point notch edges cannot be matched
exactly by the window frame. Draw the shape inside the content view if sub-point alignment matters.

**Bug found and fixed in the spike:** after a screen-parameter change, `setFrame` moved the panel to
y = 867 (its top at the bottom of the menu bar), not y = 900. The owner screenshot showed the pill below the menu bar.
Cause: `NSWindow.constrainFrameRect(_:to:)` keeps windows below the menu bar. The first `orderFront` was not
constrained, later `setFrame` calls were. Fix: override `constrainFrameRect` in the panel subclass and return the
frame unchanged. After the fix, five more change events kept the panel at y = 900.

## Window level

Raw values read from the SDK: `.mainMenu` = 24, `.statusBar` = 25, `.popUpMenu` = 101, `.screenSaver` = 1000,
custom = 26 (`.mainMenu` + 2, because `.statusBar` is already `.mainMenu` + 1).

| Level | Above menu bar (owner) | Side effect (owner) |
|---|---|---|
| `.mainMenu` (24) | yes | not asked |
| `.statusBar` (25) | yes | none |
| `.popUpMenu` (101) | yes | none (owner was asked to open a menu near the notch) |
| `.screenSaver` (1000) | yes | none |
| custom (26) | yes | covers an open menu |

Lowest working level: `.mainMenu` (24). Note the side-effect answers do not fit the raw values: menus normally draw
at `.popUpMenu` (101), so level 26 should be below an open menu and 101 / 1000 should be at or above it.
Treat the side-effect column as **needs recheck**. Suggestion for Phase 1: start with `.statusBar` and recheck
open-menu overlap with a deliberate test.

## Hotkeys

| Method | Works | Permission | What the owner saw |
|---|---|---|---|
| Carbon `RegisterEventHotKey`, Control+Option+Command+L | yes (toggle off and on) | none observed | no prompt |
| `NSEvent.addGlobalMonitorForEvents(.keyDown)` | no, while not trusted | Accessibility (`AXIsProcessTrusted()` = false) | no prompt, no toggle |

Carbon callback isolation: the handler is installed on `GetApplicationEventTarget()`, so it runs on the main thread;
the C callback uses `MainActor.assumeIsolated` to reach main-actor state.

**Limit:** the spike is a bare executable started from a terminal session. macOS may attribute permissions
(and trust checks) to the terminal app, not to our own app. Every permission result here is UNCONFIRMED for a
real app bundle until the Phase 1 app exists.

## Scaling table

| Option | frame (pt) | Notch rect | Panel lines up (owner) |
|---|---|---|---|
| Default | 1470 x 956 | (645.5, 924, 179, 32) | yes (variants A and B; screenshot) |
| More Space | not reached: frame stayed 1470 x 956 | — | UNCONFIRMED |
| Larger Text | not tested | — | UNCONFIRMED |

`NSApplication.didChangeScreenParametersNotification` fired several times while the Dock area changed
(`visibleFrame` bottom 64 → 62 → 61 → 60); `frame`, `safeAreaInsets` and the notch rect did not change.

## VERIFY items answered

- `docs/ARCHITECTURE.md` "Notch geometry (VERIFY)": answered on macOS 27 for the built-in display. Suggest: replace
  VERIFY with the edge formula above, and note that only the default scaling was tested.
- `docs/ARCHITECTURE.md` "Panel (VERIFY on macOS 27)": borderless, non-activating, above the menu bar, no focus
  steal: confirmed. Suggest adding: "override `constrainFrameRect(_:to:)`, otherwise `setFrame` pushes the panel
  below the menu bar". `collectionBehavior` with Spaces / full screen / Stage Manager is still open (S-002).
- `docs/ARCHITECTURE.md` "Xcode 27 can build with a macOS 15 deployment target": partly answered. SwiftPM builds with
  a macOS 15 target. The Xcode project check in Phase 1 is still needed.
- `docs/FEATURES.md` F-09 "none if Carbon hotkey works": Carbon hotkey worked without a prompt from a terminal launch.
  Suggest keeping "none" but marking it UNCONFIRMED for an app bundle until Phase 1.

Not edited: no doc outside `Spikes/S001/` was changed. The owner decides.

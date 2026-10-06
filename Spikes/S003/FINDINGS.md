# S-003 findings: file drag near the notch

Throwaway spike. Do not merge into the app. Tested on one MacBook Air M4, built-in display only, default scaling
(1470 x 956). Nothing here is tested on macOS 15.

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
swift build --package-path Spikes/S003
Spikes/S003/.build/debug/S003 [--seconds N] [--level statusBar|popUpMenu] [--behavior base|stationary]
                              [--zone ALPHA] [--zone-on-drag] [--watch] [--collapse-delay MS] [--info]
kill -USR1 <pid>    # resolve every stored bookmark and print the result
```

Defaults: `--level statusBar`, `--behavior stationary`, `--seconds 300`, `--collapse-delay 250`.
The pill is the S-001 variant B pill (`constrainFrameRect` override kept), registered for file URLs, URLs, TIFF, PNG and
plain text. `--zone` adds a hot-zone window around the notch: notch width plus 80 pt on each side, 120 pt tall from the
top edge, frame (565, 836, 340, 120) at default scaling. Every log line has a timestamp; drops print only item counts,
file and folder counts and pasteboard type identifiers.

Test data: one scratch folder made with `mktemp -d` (deleted at the end) holding three small dummy text files, a
subfolder with two dummy text files, one generated two-colour PNG and one dummy text file opened in a text editor for the
text drag. No real files were used.

## Answers

| Question | Answer | Evidence |
|---|---|---|
| Q1 drop target inside the non-activating pill | YES | 10 `performDragOperation` lines across runs (files, a folder, two files at once, selected text). `draggingEntered` / `draggingExited` / `performDragOperation` all arrive although the panel cannot become key. The owner confirmed drops on the lower part of the pill. Frontmost check at each drop: `spike is frontmost: false` in 9 of 10 drops; in 1 drop the log shows `spike is frontmost: true` and `frontmost application unchanged: false`. The cause was not isolated (guess, UNCONFIRMED: the owner had just closed Mission Control). |
| Q2a drag pasteboard change count, no permission | YES | `NSPasteboard(name: .drag).changeCount` changed at the start of every file and text drag while the left button was down (3 of 3 in the watch run, including one drag that never reached the pill). Polled every 50 ms while the button is down and every 250 ms otherwise. No prompt (owner). |
| Q2b global `leftMouseDragged` monitor | YES | In this setup (bare executable, see Limits): events were delivered (769 events in one run) while `AXIsProcessTrusted()` = false and `CGPreflightListenEventAccess()` = false, both read without prompting. The owner saw no prompt. Limit W6 applies: the spike runs from a terminal, so macOS may attribute access to the terminal app. |
| Q2c did a permission prompt appear | NO | Owner answer only: no permission prompt during the whole spike. |
| Q3 expand when a drag enters the notch area | WORKAROUND | A near-transparent zone (alpha 0.01) receives `draggingEntered` and expands the pill before the cursor reaches it, but it also catches clicks: 8 `zone mouseDown` lines while the owner tried to click and move a window under it (owner screenshot and answer). A fully transparent zone (alpha 0) lets clicks through but received no drag events (0 zone events; owner: "expands only at the pill"). Working variant: `--zone-on-drag`, a zone kept at alpha 0 that switches to 0.01 only while a drag is seen through Q2a and back to 0 on mouse up. In that run clicks passed through (no `zone mouseDown`, owner: could move the window) and the pill expanded before the cursor reached it (log `zone armed`, `zone draggingEntered`; owner confirmed). |
| Q3 side effect: expand and collapse loop | WORKAROUND | Without a delay the pill flickered: 42 `zone draggingEntered` / `zone draggingExited` pairs about 30 ms apart (owner: "expands and shrinks rapidly"). Guess, UNCONFIRMED: the expanded pill window covers the cursor, so the zone reports an exit and the pill collapses. Tracking which views are hovered and collapsing only after 250 ms with nothing hovered stopped it (owner: "expands steadily, drop works"). The delay result rests on the owner's answer; no count of enter/exit pairs after the delay was recorded here. Only 250 ms was tried. |
| Q3 drop at the very top edge without a side effect | NO | Dragging a file up against the top edge of the screen and holding it there opened Mission Control (owner screenshot). Drops worked when the owner released on the lower part of the pill without pushing to the top edge. In the runs we did, keep the drop area below the top edge. Evidence is the owner's screenshot and answer only; no log line. Not isolated (guess, UNCONFIRMED): whether the hot zone window touching the top edge or the screen edge alone triggered it, and whether it depends on a system setting. |
| Q4 drop content | YES | Files from the file manager: `public.file-url` and `com.apple.finder.node`, one item per file; two files gave items=2. Folder: same types, counted as a folder by `isDirectory`. Selected text: `public.utf8-plain-text` only. The PNG dragged from the file manager arrived as a file URL only, with no image data type. Image data dragged from an image app was not tested (Open items). |
| Q5 bookmarks | YES | Bookmark data created in memory for each dropped file (1088 to 1112 bytes). Before changes: both resolved, stale=false. After renaming one scratch file with `mv`: resolved, stale=true, target exists=true. After deleting the other scratch file: resolve failed with error code 4, handled, no crash (RELEASE_MATRIX row 16). Bookmarks were created without security scope (options empty), so this holds for a non-sandboxed app only. |

### Q6 recommendation

- F-06 shelf: make the pill a drop target (Q1). To catch drags before the cursor reaches the notch, keep a hot-zone
  window that is fully transparent (clicks pass through) and arm it only while a drag is in progress, using the drag
  pasteboard change count (Q2a). Collapse with a short delay, not on the first exit. In the runs we did, a drop held at the top edge opened Mission Control (cause not isolated), so keep the drop area below the top
  edge of the screen. Store bookmarks, refresh stale ones, show a missing state for failed ones. In the runs we did,
  none of this needed a permission.
- F-11 shake basket: a drag can be seen anywhere on screen without a permission prompt in two ways in this setup: the
  drag pasteboard change count tells that a drag started (no position), and the global `leftMouseDragged` monitor gives
  positions. The monitor result is UNCONFIRMED for an app bundle (W6); recheck it in Phase 1 before relying on it.
  Shake detection itself was not built.

## Limits

- Bare executable started from a terminal, not an app bundle. Every permission and prompt result is UNCONFIRMED for a
  real app bundle: macOS may attribute access to the terminal app.
- Built-in display only, default scaling, one display. Nothing tested on macOS 15.
- Many results rest on the owner's answer plus log lines; screenshots exist only where the Evidence column says so.
- Logs went to the terminal session (background command output outside the repo). No log file is in the repo.

## Open items

- Full-screen apps: not tested. S-002 found the upper part of the pill hidden in full screen, so the drop area there
  is smaller. Recheck drops in a full-screen Space.
- Image data (TIFF / PNG types) dragged from an image app, and URLs dragged from a browser: not tested.
- The one drop with `spike is frontmost: true`: not reproduced in 9 other drops; cause unknown.
- The global `leftMouseDragged` monitor without trust: recheck in an app bundle.
- `--behavior base` was not used for drops; all drop runs used `stationary` (a first check of `stationary` for
  drags; S-002 open item).
- External display, other scaling options, `--level popUpMenu`: not tested.
- Shake gesture for F-11: not built.
- Mission Control at the top edge: not isolated whether the hot zone window or the screen edge alone caused it, or whether a system setting matters.
- Security-scoped bookmarks: not tested. A sandboxed build would need them (F-06 says "if not sandboxed").
- Delay values other than 250 ms: not tried.

## VERIFY items answered

- `docs/FEATURES.md` F-06 "Permissions: none (if not sandboxed)": in this setup no prompt appeared for drops, drag
  pasteboard watching or bookmarks. Suggest: keep "none", marked UNCONFIRMED for the app bundle until Phase 1.
- `docs/FEATURES.md` F-11 "event monitoring": a drag can be noticed without a permission prompt in this setup
  (Q2a, Q2b). Suggest: "drag pasteboard watch (no permission seen); global mouse monitor UNCONFIRMED for the app bundle".
- `docs/ARCHITECTURE.md` state machine line "drag of files near notch ──▶ dropTarget": suggest adding the armed hot zone,
  the collapse delay, and "drop area below the top edge (Mission Control opened at the top edge in our runs; cause not isolated)".
- `docs/SECURITY_MODEL.md` "Untrusted pasteboard and drag data": the spike read only type identifiers, counts and
  `isDirectory`; no contents. Nothing to change; keep the size limits for Phase 1.

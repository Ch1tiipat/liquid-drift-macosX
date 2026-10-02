# S-001: Notch geometry and panel placement

- **Owner of the task:** Claude Code
- **Phase:** 0 | **Branch:** `task/s-001-notch-geometry`
- **Depends on:** T-000

## Question
Can we read the notch size and place a borderless panel exactly around it on a MacBook Air M4?

## Steps
1. Spike app under `Spikes/S001/`. Read `NSScreen` values (`safeAreaInsets`, `auxiliaryTopLeftArea`, `auxiliaryTopRightArea`). Print them.
2. Show a borderless, non-activating `NSPanel` hugging the notch. Try window levels above the menu bar.
3. Test with the Mac's display scaling options.
4. Test hotkey options: a hotkey method that needs no Accessibility permission, versus one that does. Note what each needs.

## Acceptance criteria
- [ ] `FINDINGS.md`: values read, the panel frame formula, which window level works, hotkey result
- [ ] Clear yes / no / workaround for each question

## Do NOT
Merge spike code into the app. Add dependencies. Put screenshots, window titles of private apps or any personal data in FINDINGS.md.

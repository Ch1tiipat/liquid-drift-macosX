# S-003: Detect a file drag near the notch

- **Owner of the task:** Claude Code
- **Phase:** 0 | **Branch:** `task/s-003-drag`
- **Depends on:** S-001

## Question
How can the app know that the user is dragging files toward the notch, and accept a drop there,
without special permissions? This is the riskiest feature (F-06).

## Steps
1. Try a drop target in the panel itself (a small always-present drop area).
2. Try detecting a drag by watching the drag pasteboard while the mouse is down. Note what permission, if any, this needs.
3. Try expanding the panel when a drag enters the notch area.
4. Test dropping files, folders, images, and text.

## Acceptance criteria
- [ ] `FINDINGS.md` states which approach works, its permissions, and its limits
- [ ] A recommendation for F-06 and for F-11 (shake basket)

## Do NOT
Merge spike code into the app. Add dependencies. Use the owner's real files or folders. Put real file names in FINDINGS.md.

## Test data
Use only dummy files and folders that you create in an empty scratch folder for this test.

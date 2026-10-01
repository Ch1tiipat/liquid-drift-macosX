# S-005: Clipboard monitoring and pasteboard privacy on macOS 27

- **Owner of the task:** Claude Code
- **Phase:** 0 | **Branch:** `task/s-005-clipboard`

## Question
Can a background app watch the pasteboard without a permission prompt on macOS 27? How do we skip
secrets copied from password managers?

## Steps
1. Poll the change count on a timer with a low rate. Measure CPU. Read the item only when the count changes.
2. Check whether macOS asks the user for permission or lists the app under pasteboard privacy settings. Record what the user sees.
3. Copy from a password manager and inspect the pasteboard types for "concealed" or "transient" markers. Record the exact type names seen.
4. Test large images and rich text. Note size limits that stay responsive.

## Acceptance criteria
- [ ] `FINDINGS.md`: prompt behavior, polling cost, secret-marker type names, size limits
- [ ] Input for ADR-003 (encrypted store format)

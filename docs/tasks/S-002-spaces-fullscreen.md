# S-002: Panel across Spaces, full screen and Stage Manager

- **Owner of the task:** Claude Code
- **Phase:** 0 | **Branch:** `task/s-002-spaces`

## Question
Does the panel stay visible and usable with `collectionBehavior` `canJoinAllSpaces` + `fullScreenAuxiliary`,
on Spaces, full-screen apps, Stage Manager and Mission Control?

## Steps
1. Reuse the S-001 panel. Set the collection behavior. (Note: `primary`, `auxiliary`, `canJoinAllApplications` are mutually exclusive.)
2. Test: second Space, a full-screen app, Stage Manager on, Mission Control, sleep and wake.
3. Check that the panel does not steal focus from the frontmost app.

## Acceptance criteria
- [ ] `FINDINGS.md` has a table: scenario, result, workaround if any
- [ ] Rows 2 to 5 and 8 of `docs/RELEASE_MATRIX.md` can be predicted from it

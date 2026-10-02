# S-006: Agent status for Claude Code and Codex CLI

- **Owner of the task:** Claude Code
- **Phase:** 0 (Agent Status is in the MVP, ADR-013)
- **Branch:** `task/s-006-agent-status`
- **Depends on:** T-000

## Question
What is the most accurate way, with the fewest permissions, to know the state of a Claude Code session
and a Codex CLI session (working, waiting for the user, done)? Compare hooks with watching session files.

## Context
Read first: `AGENTS.md`, `docs/FEATURES.md` (section Agent Status), `docs/SECURITY_MODEL.md`,
`docs/ARCHITECTURE.md` (section Agent providers).
Scope: Claude Code and Codex CLI only. The Codex desktop app is out of scope (F-23).

## Steps
1. Put code in `Spikes/S006/` as a Swift Package executable (SwiftPM, no Xcode project). No dependencies.
2. Use dummy sessions only: a new empty scratch folder and a harmless prompt such as "say hello".
   Never use the owner's real projects, prompts or code.
3. **Option B first (read-only, changes nothing):** find where each tool keeps its session data. Record only folder names,
   file types and which fields carry the state. Write `~` instead of a real home path. Do not copy file content into `FINDINGS.md`.
4. Watch those files with a file watcher. Measure how long after the real event the state change is seen, and the idle CPU cost.
5. **Option A (hooks):** read the official documentation of each tool for hook events. Test without touching the owner's real config:
   use a separate config directory if the tool supports one (**VERIFY**), or ask the owner before any change to a real config file.
   For Codex, record what the user sees and must do before a hook runs. The CodeIsland README says there is a one-time trust step (**VERIFY**).
6. For each option and each tool, test: a normal turn, a tool call, waiting for the user, an interrupted turn,
   two sessions at the same time, the tool closed while a turn runs.
7. Check whether any option makes macOS show a permission prompt (files, automation). Record exactly what the user sees.
8. Check what happens when a tool updates and its format changes. Say how the app can notice this and show "unknown" instead of a wrong state.

## Acceptance criteria
- [ ] `FINDINGS.md` has a table: option, tool, scenario, result (YES / NO / WORKAROUND / UNCONFIRMED), latency, permissions
- [ ] A recommendation for ADR-012: hooks or session files, for each tool
- [ ] `FINDINGS.md` and the code contain no prompts, code, reply text, session IDs, real project names or home paths
- [ ] A list of the VERIFY items in the docs that are now answered, with suggested changes (the owner decides)

## How to verify
The owner reads `FINDINGS.md` for private data, then repeats one scenario per tool on the real Mac.

## Do NOT
Add dependencies. Merge spike code into the app. Edit the owner's real config files without asking.
Store, show or log content from sessions. Send anything over the network. Copy code or assets from CodeIsland or any other app.

## Final report (agent fills in)
- What changed:
- How verified:
- NOT verified:
- Risks / questions:

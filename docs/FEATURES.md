# Feature catalog

Inspired by the kinds of features other notch apps offer. **Ideas only. No code or assets are copied.**
The agent-status ideas (F-20 to F-25) come from reading the public README of CodeIsland (MIT license). We did not read its source code.
Tiers: **MVP** = first usable alpha. **R2** = after real use. **Later** = only if wanted.

| ID | Feature | Tier | Permissions (VERIFY) | Risk |
|---|---|---|---|---|
| F-01 | Island shell: idle / hover / expanded states | MVP | none | medium |
| F-02 | Control Center window with mode dropdown and module switches | MVP | none | low |
| F-03 | Settings: General, Features, Customize, Shortcuts, Permissions, About | MVP | none | low |
| F-04 | Launch at login | MVP | none (system login item API) | low |
| F-05 | Clipboard history: text and images, search, pin, per-app ignore list | MVP | maybe pasteboard access prompt | **high** |
| F-06 | File shelf: drag in, drag out, remove, bookmarks | MVP | none (if not sandboxed) | **high** |
| F-07 | Now Playing: Spotify and Apple Music, behind one provider protocol | MVP | Automation or none | **high** |
| F-08 | Battery status | MVP | none | low |
| F-09 | Global hotkey to open the island | MVP | none if Carbon hotkey works | medium |
| F-10 | Update checker (off by default) | MVP | network | low |
| F-11 | Floating basket (shake while dragging) | R2 | event monitoring | high |
| F-12 | OCR on clipboard images (Vision framework) | R2 | none | low |
| F-13 | Quick actions on shelf files (zip, share) | R2 | none | medium |
| F-14 | Hide clipboard content from screen sharing and recording | R2 | none | low |
| F-15 | Calendar next event | Later | Calendar access | medium |
| F-16 | System HUD replacement (volume, brightness) | Later | Accessibility / input monitoring | **high** |
| F-17 | Local dev ports monitor | Later | none | medium |
| F-18 | Floating pill for Macs without a notch, multi-display | Later | none | medium |
| F-19 | License key (offline, signed) | Later | none | medium |
| F-20 | Agent Status, read-only: live state of Claude Code and Codex CLI sessions (working, waiting, done) | MVP | VERIFY (depends on S-006) | **high** |
| F-21 | Agent Status quiet rules: no alert when you already look at that session, quiet hours, mute while screen is locked | Later | none | low |
| F-22 | Approve or deny an agent tool call from the island | Later | VERIFY | **high** |
| F-23 | Agent Status for the Codex desktop app | Later | VERIFY | **high** |
| F-24 | Click a session to jump to its terminal tab | Later | VERIFY (Automation or Accessibility) | medium |
| F-25 | Agent Status for other tools (new provider, only on demand) | Later | VERIFY | medium |

## Now Playing providers (F-07)
- `NowPlayingProvider` protocol with two implementations: `SpotifyProvider`, `AppleMusicProvider`.
- If one breaks after an OS update, the other keeps working.
- The system-wide media API may be restricted on new macOS. **VERIFY** in spike S-004.

## Agent Status (F-20 to F-25)
Goal: see what your coding agents are doing without switching windows.

**First target (owner decision):** Claude Code and Codex CLI only. The owner also uses the Codex
desktop app, but the CLI comes first to save time. The desktop app is F-23.
F-20 is part of the MVP (ADR-013).

Design:
- `AgentProvider` protocol with two implementations: `ClaudeCodeProvider` and `CodexCLIProvider`.
  Same idea as `NowPlayingProvider` (ADR-008): if one breaks after an update, the other keeps working.
- It is a normal `FeatureModule`. Off means off: no file watcher, no socket, no timer.
- Read-only first. F-22 (approve or deny) is a separate, later decision because it is high risk.
- **Default (owner can change it):** the first version shows only the tool name and the state (working, waiting for you, done). No prompt or reply text.

Two ways to get the status. Spike **S-006** (`docs/tasks/S-006-agent-status.md`) compares them with dummy data only:
1. **Hooks:** the agent calls a small helper when something happens. Needs a change in the tool's own config file.
2. **Session files:** watch the files the tool already writes, read-only. Nothing is installed in the tool.
Pick the one that is more accurate and needs fewer permissions (ADR-012). Do not decide before S-006. Run S-006 in Phase 0, together with S-001 to S-005 (ADR-013).

Rules:
- The user installs or enables any hook by hand. The app never edits another tool's config silently.
- If agent text is ever shown (replies, commands, file names), it is **untrusted data**. Show it as plain text, cut it short,
  never run it, never open links from it, never style it like a system dialog.
- Never log agent text. Use `os.Logger` with `.private` for anything about sessions.
- No network. No push to phone, chat or webhook.
- **VERIFY** (not checked yet): where each tool keeps its session files, the hook format of each tool,
  and whether Codex needs the user to trust a hook once. The CodeIsland README says it does. Check on the real Mac.
- Do not copy code, mascots or other assets from CodeIsland or any other app.

## Not planned
| Idea | Why not |
|---|---|
| Support for 30+ tools | Each tool needs its own integration. Start with two. Add more only through a new provider (F-25) |
| Push to phone, Slack, Telegram, webhook | Breaks "no network by default" |
| iPhone, Apple Watch or ESP32 companion | Out of scope and budget |
| Pixel-art mascots | Other people's assets. Use our own look (`docs/DESIGN.md`) |

## Mode presets (first draft)
| Mode | Modules on |
|---|---|
| Code Focus | F-06 shelf, F-05 clipboard, F-20 agent status |
| Listen | F-07 now playing, F-08 battery |
| Presentation | none |
| Everything | all |
| Custom | user choice |

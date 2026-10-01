# Liquid Drift

Repo: https://github.com/Ch1tiipat/liquid-drift-macosX

A free macOS utility that turns the MacBook notch into a small, fluid "island":
file shelf, clipboard history, Now Playing and battery. Every feature is a module
that you can switch on or off, and you can group those switches into **modes**.

> Status: **pre-alpha (planning)**. Nothing is released yet.

## Principles

- **One switch per feature.** Off means off: no observers, no timers, no CPU.
- **Private by default.** No telemetry. No network unless you turn on update checks.
- **Built from scratch.** Ideas come from other notch apps; code does not.
- **Free during alpha.** A license key system may come later (see `docs/LICENSING.md`).

## Modes (first draft)

| Mode | What is on |
|---|---|
| Code Focus | File shelf, clipboard history |
| Listen | Now Playing, battery |
| Presentation | Everything quiet |
| Everything | All modules |
| Custom | Your own mix |

## Requirements

- MacBook with Apple silicon. Developed on a MacBook Air M4.
- Planned development on macOS 27 with Xcode 27 (confirmed by task T-000). Minimum macOS version: **to be confirmed** (default: 15).

## Docs

| File | Purpose |
|---|---|
| `AGENTS.md` | Rules for AI coding agents (Claude Code, Codex CLI) |
| `docs/ARCHITECTURE.md` | Layers, module protocol, state machine |
| `docs/FEATURES.md` | Feature catalog and MVP tiers |
| `docs/ROADMAP.md` | Phases and exit criteria |
| `docs/DESIGN.md` | Colors, windows, modes, motion |
| `docs/SECURITY_MODEL.md` | Threats and mitigations |
| `docs/RELEASE_MATRIX.md` | Compatibility test checklist |
| `docs/LICENSING.md` | License decisions and checklist before the alpha release |
| `docs/DECISIONS.md` | Decision log |
| `docs/tasks/` | Task cards for agents |

## License

**Not decided yet.** Until a `LICENSE` file is added, all rights are reserved.
See `docs/LICENSING.md`.

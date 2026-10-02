# Roadmap

Confirmed by the owner on 2026-10-02: **minimum macOS = 15** (built for 15, tested on macOS 27 only), MVP = F-01 to F-10 plus F-20 (Agent Status).

| Phase | Goal | Exit criteria |
|---|---|---|
| -1 Setup | Mac ready, repo ready | `sw_vers`, `xcodebuild -version`, `swift --version` recorded in `docs/ENVIRONMENT.md`; public repo created (liquid-drift-macosX) |
| 0 Spikes | Prove risky platform behavior | S-001 to S-006 each have a `FINDINGS.md` with a clear yes / no / workaround |
| 1 Shell | App runs, panel shows at the notch | LSUIElement app, menu-bar item, NSPanel at notch, ModuleRegistry with stub modules, Settings shell, `LicenseGate` = `AlwaysAllowed`; deployment target macOS 15 builds with Xcode 27 (VERIFY, ADR-007) |
| 2 Transitions | Island feels right | State machine with tests, hover delay setting, global hotkey, ModeManager, Reduce Motion respected |
| 3 MVP modules | Real features | Clipboard, Shelf, Now Playing (2 providers), Battery, Agent Status (Claude Code and Codex CLI, read-only). Each can be switched off and then costs zero CPU |
| 4 Control Center | Full UI | Control Center window, Permissions page, About page with version, update check (off by default); launch at login (F-04) |
| 5 Compatibility | Release alpha | RELEASE_MATRIX filled, security checklist done, code license chosen and LICENSE added, alpha release published |
| 6 Later | R2 and beyond | Basket, OCR, quick actions, license key, HUD, Agent Status extras (F-21 to F-25) |

## Rules for moving between phases
- Do not start a phase before the previous exit criteria are met.
- Findings from Phase 0 can change Phase 1 to 3. Update `docs/ARCHITECTURE.md` and `docs/DECISIONS.md` when they do.
- The owner uses the app daily after Phase 3 and decides what to add, using the real experience.
- Phase 0 order: S-001 first. S-002 and S-003 reuse the S-001 panel, so they come after it. S-004, S-005 and S-006 do not depend on the panel.

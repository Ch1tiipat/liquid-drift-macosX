# Roadmap

Defaults still to be confirmed by the owner before Phase 1: **minimum macOS = 15**, MVP = F-01 to F-10.

| Phase | Goal | Exit criteria |
|---|---|---|
| -1 Setup | Mac ready, repo ready | `sw_vers`, `xcodebuild -version`, `swift --version` recorded in `docs/ENVIRONMENT.md`; public repo created (liquid-drift-macosX) |
| 0 Spikes | Prove risky platform behavior | S-001 to S-005 each have a `FINDINGS.md` with a clear yes / no / workaround |
| 1 Shell | App runs, panel shows at the notch | LSUIElement app, menu-bar item, NSPanel at notch, ModuleRegistry with stub modules, Settings shell, `LicenseGate` = `AlwaysAllowed` |
| 2 Transitions | Island feels right | State machine with tests, hover delay setting, global hotkey, ModeManager, Reduce Motion respected |
| 3 MVP modules | Real features | Clipboard, Shelf, Now Playing (2 providers), Battery. Each can be switched off and then costs zero CPU |
| 4 Control Center | Full UI | Control Center window, Permissions page, About page with version, update check (off by default) |
| 5 Compatibility | Release alpha | RELEASE_MATRIX filled, security checklist done, code license chosen and LICENSE added, alpha release published |
| 6 Later | R2 and beyond | Agent Status (F-20, starts with spike S-006), basket, OCR, quick actions, license key, HUD |

## Rules for moving between phases
- Do not start a phase before the previous exit criteria are met.
- Findings from Phase 0 can change Phase 1 to 3. Update `docs/ARCHITECTURE.md` and `docs/DECISIONS.md` when they do.
- Spike S-006 (agent status) is not part of the Phase 0 exit criteria. Run it after Phase 3, before F-20 starts.
- The owner uses the app daily after Phase 3 and decides what to add, using the real experience.

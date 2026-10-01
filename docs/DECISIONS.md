# Decision log (ADR)

Format: ID, date, status, decision, reason.

| ID | Date | Status | Decision | Reason |
|---|---|---|---|---|
| ADR-001 | 2026-10-01 | accepted | Every feature is a `FeatureModule` with start and stop | One switch per feature, zero cost when off, modes are just sets of modules |
| ADR-002 | 2026-10-01 | accepted | No third-party dependencies at first | Fewer risks, simpler licensing |
| ADR-003 | | open | Format of the encrypted clipboard store | Decide after spike S-005 |
| ADR-004 | | open | System font (SF) or bundled DM Sans | Native feel vs. matching the mock-up |
| ADR-005 | 2026-10-01 | accepted | Alpha is free, no key. `LicenseGate` hook exists but always allows | Owner decision. Key system comes later |
| ADR-006 | 2026-10-01 | accepted | Not sandboxed, Hardened Runtime on | Global features need broader access. Revisit if App Store is ever planned |
| ADR-007 | | open | Minimum macOS version | Default proposal: 15. Owner confirms before Phase 1 |
| ADR-008 | 2026-10-01 | accepted | Now Playing through a provider protocol, Spotify and Apple Music separate | One can break without the other |
| ADR-009 | | open | Update checker design (GitHub Releases, public repo only) | Needs public repo, no token inside the app |
| ADR-010 | 2026-10-01 | accepted | Repo is public from the start | Owner decision: AI agents could not fetch a private repo link. Risk: everything committed is public. No images or unreviewed assets are committed. |

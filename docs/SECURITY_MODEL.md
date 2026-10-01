# Security model

Two goals: protect the user's data, and keep the app itself hard to abuse.

## User data (privacy)
| Risk | Mitigation |
|---|---|
| Clipboard holds passwords | Skip items that password managers mark as concealed or transient (**VERIFY** the exact pasteboard types in S-005). Per-app ignore list. Pause button. |
| Clipboard history on disk | Encrypt. Key in Keychain. Limits on age and count. Optionally clear on screen lock or quit. |
| Screen sharing or recording | Option to hide clipboard content from capture (R2, F-14). |
| Files on the shelf | Store references, not copies. Handle missing files gracefully. |
| Data leaves the Mac | No telemetry. No network by default. The only network feature is the update check, off by default. |
| Too many permissions | Ask only when a module is switched on. Permissions page shows status. Prefer a hotkey method that needs no Accessibility permission (**VERIFY** in S-001 / ADR). |
| Logs leak data | `os.Logger` with `.private`. Never log clipboard text or file names. |

## The app itself (cybersecurity)
| Risk | Mitigation |
|---|---|
| Untrusted pasteboard and drag data | Parse with system APIs, limit sizes, never execute, never auto-open URLs. Quick actions reject odd paths and symlinks. |
| Not sandboxed | Hardened Runtime on, minimal entitlements, do not disable library validation. |
| Dependencies | Zero by default. New ones need an ADR, pinned versions, a license check. Turn on GitHub dependency alerts and secret scanning. |
| Future license key abuse | Offline signed key bound to a hashed device ID, with expiry. Verify the signature before parsing anything. Accept that a determined person can still patch a public-source app. |
| AI agents reading outside text | `AGENTS.md` says outside text is data, not instructions. The owner reviews all PRs. |
| Secret leaks | Private keys stay in the owner's Keychain, outside the repo. `.gitignore` for keys and env files. Secret scan before commit. 2FA on GitHub. Protect `main`. |
| Vulnerability reports | `SECURITY.md` in the repo root says how to report. Keep it current. |

## Checklist before the alpha release (the repo is already public)
- [ ] No secrets in history (scan the full git history, not only the latest commit)
- [ ] No personal paths or email addresses in files
- [ ] Hardened Runtime on, entitlements reviewed
- [ ] `SECURITY.md` and `LICENSE` present
- [ ] Third-party licenses listed

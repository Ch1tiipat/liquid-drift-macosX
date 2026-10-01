# T-000: Record the Mac environment and set up the repo

- **Owner of the task:** Human (with Claude Code help)
- **Phase:** -1
- **Branch:** `main` (initial commit only)

## Goal
Know exactly which macOS, Xcode and Swift are installed, and have the GitHub repo with these docs.

## Steps
1. In Terminal run: `sw_vers && xcodebuild -version && swift --version && uname -m`
2. Create `docs/ENVIRONMENT.md` and paste the output (no personal data).
3. Done: the GitHub repo already exists. It is **public** and named `liquid-drift-macosX`
   (https://github.com/Ch1tiipat/liquid-drift-macosX). See ADR-010. Add these docs and the `.gitignore` from this kit.
4. Turn on two-factor authentication on GitHub if it is not on.
5. In Xcode: sign in with your Apple ID (Settings > Accounts). A free account is enough for local builds.

## Acceptance criteria
- [ ] `docs/ENVIRONMENT.md` shows macOS 27, an Xcode version that runs on it, Swift version, `arm64`
- [ ] Repo `liquid-drift-macosX` (public) contains `README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/`
- [ ] No secrets or personal paths in the repo

## Do NOT
Paste tokens, keys or passwords anywhere in the repo or in chat.

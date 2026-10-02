# T-000: Record the Mac environment and set up the repo

- **Owner of the task:** Human (with Claude Code help)
- **Phase:** -1
- **Branch:** `task/t-000-environment` (never commit to `main` directly; the owner merges on GitHub)

## Goal
Know exactly which macOS, Xcode and Swift are installed, and have the GitHub repo with these docs.

## Steps
1. On a new machine, before the first commit: set the git email to the GitHub noreply address
   and check it with `git config --get user.email`. It must end with `@users.noreply.github.com`.
2. In Terminal run: `xcode-select -p && sw_vers && xcodebuild -version && swift --version && uname -m && sysctl -n machdep.cpu.brand_string`
   `xcode-select -p` must end with `Xcode.app/Contents/Developer`. If it points to CommandLineTools, the owner switches it (needs sudo). Agents never run sudo.
3. Fill in the placeholder block in `docs/ENVIRONMENT.md` (the file already exists) with the command output. No personal data: no user name, no computer name, no home path, no serial number.
4. Done: the GitHub repo already exists. It is **public** and named `liquid-drift-macosX`
   (https://github.com/Ch1tiipat/liquid-drift-macosX). See ADR-010. The docs and the `.gitignore` from the starter kit are already in it.
5. Turn on two-factor authentication on GitHub if it is not on.
6. In Xcode: sign in with your Apple ID (Settings > Accounts). A free account is enough for local builds.

## Acceptance criteria
- [ ] `docs/ENVIRONMENT.md` shows macOS 27, an Xcode version that runs on it, Swift version, `arm64`
- [ ] Repo `liquid-drift-macosX` (public) contains `README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/`
- [ ] `git log --format='%ae %ce'` shows only the noreply address
- [ ] No secrets or personal paths in the repo

## Do NOT
Paste tokens, keys or passwords anywhere in the repo or in chat.

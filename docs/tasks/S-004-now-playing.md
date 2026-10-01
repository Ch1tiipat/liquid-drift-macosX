# S-004: Now Playing from Spotify and Apple Music

- **Owner of the task:** Claude Code
- **Phase:** 0 | **Branch:** `task/s-004-now-playing`

## Question
What is the least-permission way to read track info and send play / pause / next / previous for each app on macOS 27?

## Steps
1. For each app, try the options: app notifications, scripting (needs Automation permission), any system media API.
2. Record, per option: works yes/no, permissions asked, latency, behavior when the app is closed.
3. Check whether artwork can be obtained and how.

## Acceptance criteria
- [ ] `FINDINGS.md` has one row per app and option
- [ ] A recommended implementation for `SpotifyProvider` and `AppleMusicProvider`
- [ ] Clear note if the system-wide API is not usable

# Feature catalog

Inspired by the kinds of features other notch apps offer. **Ideas only. No code is copied.**
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

## Now Playing providers (F-07)
- `NowPlayingProvider` protocol with two implementations: `SpotifyProvider`, `AppleMusicProvider`.
- If one breaks after an OS update, the other keeps working.
- The system-wide media API may be restricted on new macOS. **VERIFY** in spike S-004.

## Mode presets (first draft)
| Mode | Modules on |
|---|---|
| Code Focus | F-06 shelf, F-05 clipboard |
| Listen | F-07 now playing, F-08 battery |
| Presentation | none |
| Everything | all |
| Custom | user choice |

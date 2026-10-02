# Architecture

Items marked **VERIFY** are not confirmed on macOS 27 yet. A spike must prove them first.

## Layers

```
App (thin)            LSUIElement app, menu-bar item, windows, launch at login
 ├─ LDCore            FeatureModule, ModuleRegistry, ModeManager, SettingsStore,
 │                    PermissionCenter, LicenseGate (hook), UpdateChecker (off by default)
 ├─ LDIsland          IslandPanelController (NSPanel), IslandStateMachine, NotchGeometry
 ├─ LDModules         ShelfModule, ClipboardModule, NowPlayingModule, BatteryModule,
 │                    AgentStatusModule
 └─ LDUI              DesignTokens, ControlCenterView, SettingsView, shared components
```

Each box is a local Swift package (or a target inside one). Modules never import each other.
They talk to the island only through `IslandContribution` values.

## Module protocol (sketch)

```swift
@MainActor
protocol FeatureModule: AnyObject {
    var id: ModuleID { get }
    var displayName: String { get }
    var requiredPermissions: [PermissionKind] { get }
    var status: ModuleStatus { get }            // .off, .running, .needsPermission, .failed(String)

    func start() async throws                   // acquire observers, ask permission if needed
    func stop()                                 // release EVERYTHING: observers, timers, taps, windows

    var island: IslandContribution? { get }     // compact / expanded views, may be nil
    func makeSettingsView() -> AnyView
}
```

Rules:
- `stop()` must make the module cost zero CPU. A test checks that no timer or observer remains.
- `start()` is called only when the module is enabled **and** the app is not paused.
- A module never asks for a permission by itself. `PermissionCenter` asks, after the user flips the switch.

## Modes

```swift
struct Mode: Codable, Identifiable {
    let id: String            // "code", "listen", "present", "all", "custom"
    var name: String
    var enabledModules: Set<ModuleID>
}
```

- Switching mode applies `enabledModules` through `ModuleRegistry` (start the new ones, stop the others).
- If the user flips a single module switch by hand, the active mode becomes `custom`.
- Modes are switched by hand. No automatic switching in the first version.

## Island state machine

```
idle ──hover (after delay)──▶ hover ──click / hotkey──▶ expanded
  ▲                              │                         │
  └──────────── leave / Esc ◀────┴─────────────────────────┘
drag of files near notch ──▶ dropTarget (expands the shelf) ──▶ idle after drop or leave
```

- Hover delay: start at 0.25 s. Cancel if the pointer leaves. Make it a setting.
- Respect **Reduce Motion**: no spring or morph animation, use a short fade.
- Presentation mode: the island stays idle and draws nothing but the plain notch shape.

## Notch geometry (VERIFY)
- Read the notch size from `NSScreen` (`safeAreaInsets`, `auxiliaryTopLeftArea`, `auxiliaryTopRightArea`).
- No notch (external display): draw a floating pill at the top center (later feature).
- Multi-display: one panel per screen that has the island enabled (later feature).

## Panel (VERIFY on macOS 27)
- `NSPanel`, borderless, non-activating, level above the menu bar.
- `collectionBehavior`: `canJoinAllSpaces` + `fullScreenAuxiliary`, and test Stage Manager.
  `primary`, `auxiliary` and `canJoinAllApplications` are mutually exclusive.
- Never steal focus from the user's frontmost app unless the user clicks into a text field.

## Agent providers (VERIFY)
`AgentStatusModule` (F-20) gets its data from `AgentProvider` objects, one per tool, the same idea as
`NowPlayingProvider`. First tools: Claude Code and Codex CLI. The method (hooks or session files) is decided
after spike S-006 (ADR-012). Sketch, not final:

```swift
protocol AgentProvider: AnyObject {
    var id: AgentProviderID { get }                      // .claudeCode, .codexCLI
    func start() async throws                            // begin watching
    func stop()                                          // release EVERYTHING: watchers, sockets, timers
    var sessions: AsyncStream<[AgentSessionState]> { get }
}
// AgentSessionState: opaque id, tool, state (.working, .waitingForUser, .done, .idle, .unknown).
// No prompt, code or reply text is stored. An unreadable or changed format gives .unknown, never a guess.
```

## Persistence
- Settings: `UserDefaults` behind `SettingsStore`.
- Clipboard history: encrypted file store. The encryption key lives in the Keychain. (ADR-003 decides the format.)
- File shelf: store bookmark data (references), never copies of files.

## Platform
- Minimum macOS 15 (ADR-007). Built with the Xcode 27 SDK. Only macOS 27 is tested.
- Use availability checks (`#available`) for anything newer than macOS 15. Do not claim macOS 15 works until it is tested on a real Mac.

## Distribution (alpha)
- Not sandboxed (global features need broader access). Hardened Runtime ON. Minimal entitlements.
- Free Apple ID signing for local builds. Not notarized. See `docs/LICENSING.md`.

## Hooks reserved for later
- `LicenseGate`: a protocol with one implementation, `AlwaysAllowed`, for the free alpha.
  A signed-key implementation can replace it later without touching modules.
- `UpdateChecker`: compiled in, disabled by default.

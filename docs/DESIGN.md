# Design

Mood: deep navy-black with electric blue and a soft white glow, with film grain.
The look comes from the owner's reference images. Layouts are original.

## Colors (tokens)
| Token | Hex | Use |
|---|---|---|
| ink | #0F1219 | App background |
| midnight | #101426 | Cards |
| navy | #101E55 | Gradient mid |
| royal | #112B7D | Gradient |
| blue | #234EA8 | Gradient light |
| accent | #2F5BFF | Switches, buttons, active state |
| sky | #80A4D8 | Secondary highlight |
| glow | #EFECE5 | Glow, orb highlight |

The accent value was estimated from a reference image and may be tuned. Text on `accent`
must stay readable (check contrast, at least 4.5:1 for normal text).

## Type
- The design mock-up used DM Sans. A native app can use the system font (SF) instead, which is
  simpler and has no font license to track. **Decision pending** (ADR-004).

## Windows
- **Control Center** (about 560 x 720): title row with settings, minimize, close; big power button;
  mode dropdown; module list with one switch per module and a status label; footer with version
  and an "Update available" button when an update exists.
- **Settings** sidebar: General, Features, Customize, Shortcuts, Permissions, About.
  Rows have a title and a one-line description under it. Section titles are uppercase.
- Version number sits at the bottom left of the Settings sidebar.

## Island states
1. **Idle:** hugs the notch, almost invisible.
2. **Hover:** widens after a short delay, shows module icons.
3. **Expanded:** shelf, clipboard, now playing in columns.
4. **Drop target:** shelf opens while files are dragged near the notch.

## Motion
- Spring-like morph for expand and collapse. Disabled when Reduce Motion is on.
- Hover delay 0.25 s default. Adjustable.

## Logo
- Main mark: a dark liquid drop on a blue glowing field (owner's AI-made reference).
- Plan: redraw the drop as a vector for the app icon and a single-color menu-bar symbol.
- Provenance of the reference image is recorded in `docs/LICENSING.md`.

# S-006 findings: agent status (Claude Code and Codex CLI)

## Environment

```
ProductName:    macOS
ProductVersion: 27.0.1
BuildVersion:   26A434
Xcode 27.0
Build version 27A266a
Apple Swift version 6.4 (swiftlang-6.4.0.34.1 clang-2100.3.34.1)
arm64
```

## How to run

```
swift build --package-path Spikes/S006
S=$(mktemp -d -t s006-)                       # scratch folder, direct child of $TMPDIR
cp Spikes/S006/.build/debug/S006 "$S/"
# Claude Code hooks: "$S/.claude/settings.json", each event runs  "$S/S006" hook <Event> "$S"
# Codex hooks:       "$S/.codex/hooks.json",     each event runs  "$S/S006" hook <Event> "$S" --codex
"$S/S006" watch "$S" [--tool claude|codex] --seconds 300 --shapes   # stops after --seconds or Ctrl+C
"$S/S006" classify "$S" "$S/<copy>.jsonl" [--tool claude|codex]    # format-change test on a copy
```

- The watcher is a command-line tool built on Foundation with no AppKit: no window, no Dock icon, no menu. It
  replaces the accessory activation policy of earlier spikes. It stops after `--seconds` and on Ctrl+C.
- The spike refuses a scratch folder that is not a direct child of `$TMPDIR` named `s006-*`. It reads or watches a
  path if its symlink-resolved form is inside the scratch folder or the Claude Code session folder computed
  from it (exact path-prefix match), or is one Codex transcript file below `~/.codex/sessions/` named by a hook whose
  `cwd` is the scratch folder. Any other path is refused.
- Hook helper: writes "event name + ms" to `events.log` in the scratch folder. Claude Code mode discards the stdin
  payload. Codex mode keeps one field of the payload (the transcript path) in a file inside the scratch folder, and
  keeps nothing when the payload `cwd` is a different folder. The scratch folder is deleted at the end.

## Answers

Latency columns: for option A, the time from the hook helper writing its line to the watcher reading it. For
option B, the time from the matching hook (`UserPromptSubmit`, `Stop`, `Interrupt`) to the watcher reading the
session line; negative means the line came first. Neither is the time from the real event inside the tool.

### Claude Code

6 planned dummy turns in a scratch folder: 1 with `claude -p`, 5 typed by the owner in separate terminal windows.

| Option | Tool | Scenario | Result | Latency | Permissions |
|---|---|---|---|---|---|
| A hooks | Claude Code | normal turn | YES | 0 to 1 ms | project `.claude/settings.json`; trust dialog seen in interactive runs |
| A hooks | Claude Code | tool call | YES | 0 to 1 ms (`PreToolUse`, `PostToolUse`) | same |
| A hooks | Claude Code | waiting for the user | YES | `PermissionRequest` 23 ms after `PreToolUse`; `Notification` 6.0 s later | same; needs a permission mode that asks |
| A hooks | Claude Code | interrupted turn (Esc) | UNCONFIRMED | see note 1 | same |
| A hooks | Claude Code | two sessions at once | UNCONFIRMED | events of both sessions arrive in one file; the helper keeps no `session_id` | same |
| A hooks | Claude Code | tool closed during a turn | UNCONFIRMED | see note 1 | same |
| B session files | Claude Code | normal turn | YES | done 45 to 98 ms after `Stop` (4 turns) | none asked; the watcher does not write |
| B session files | Claude Code | tool call | YES | tool_use line 91 ms after `PreToolUse` | none asked |
| B session files | Claude Code | waiting for the user | NO | no line written during a 50 s approval wait; state stayed working | none asked |
| B session files | Claude Code | interrupted turn (Esc) | NO | see note 2 | none asked |
| B session files | Claude Code | two sessions at once | YES | one file per session; working 247 and 248 ms after `UserPromptSubmit` | none asked |
| B session files | Claude Code | tool closed during a turn | WORKAROUND | see note 2 | none asked |

Note 1. Esc (window A) and the closed window (window B) ran at the same time and share one `events.log`. From
`UserPromptSubmit` of both sessions to the end of the run, the code saw no `Stop` event at all, then 2 `SessionEnd`
events 9.5 s apart. With no `session_id` kept, the code cannot say which `SessionEnd` belongs to which window.

Note 2. State from code at the moment of Esc and of closing: both files were in state working, with no `end_turn`
line and no assistant line after the prompt. That the turns were still running when Esc was pressed and the
window was closed is owner answer only. After that, neither file got a line marking the interrupt; each got
`cost-state` lines when its session ended (window A at `/exit`, window B at close), which the classifier maps
to idle. One run each.

### Codex CLI

The planned Codex turns were not run. The owner typed 16 prompts of their own in Codex sessions in the scratch
folder (outside the plan). The rows below rest on what the code recorded from those sessions (event names, key
names, enum values, timestamps); they are observations, not designed tests. Prompt and reply text was not read.

| Option | Tool | Scenario | Result | Latency | Permissions |
|---|---|---|---|---|---|
| A hooks | Codex CLI | normal turn | YES | observation; 0 to 1 ms; 16 `UserPromptSubmit`, 14 `Stop`, 2 `Interrupt` | project `.codex/hooks.json`; trust screens seen (owner answer only) |
| A hooks | Codex CLI | tool call | YES | observation; `PreToolUse` 9, `PostToolUse` 6; see note 3 | same |
| A hooks | Codex CLI | waiting for the user | UNCONFIRMED | not run; no `PermissionRequest` seen | same |
| A hooks | Codex CLI | interrupted turn | UNCONFIRMED | `Interrupt` seen 2 times, each without `Stop`; what the owner pressed is not known | same |
| A hooks | Codex CLI | two sessions at once | UNCONFIRMED | not run | same |
| A hooks | Codex CLI | tool closed during a turn | UNCONFIRMED | not run; see note 4 | same |
| B session files | Codex CLI | normal turn | YES | observation; working -1471 to +92 ms against `UserPromptSubmit` (16); done 73 to 138 ms after `Stop` (14) | none asked |
| B session files | Codex CLI | tool call | YES | observation; 8 tool-call lines, 20 ms to 1.6 s before `PreToolUse`; state stays working; see note 3 | none asked |
| B session files | Codex CLI | waiting for the user | UNCONFIRMED | not run | none asked |
| B session files | Codex CLI | interrupted turn | UNCONFIRMED | a `turn_aborted` event line 1 ms after each `Interrupt` hook (2); mapped to idle | none asked |
| B session files | Codex CLI | two sessions at once | UNCONFIRMED | not run; 5 transcript files, 3 with prompts; file 4 was opened twice (a 4th `SessionStart` with no new file) | none asked |
| B session files | Codex CLI | tool closed during a turn | UNCONFIRMED | not run; see note 4 | none asked |

Note 3. Hooks and transcript lines do not pair one to one. 9 `PreToolUse` against 8 tool-call lines: two
`PreToolUse` events (0.2 s apart) followed one tool-call line. 3 `PreToolUse` events had no `PostToolUse` before
the next tool call; 2 of those had a tool-output line within 300 ms. Cause unknown.

Note 4. Counts that do not match: 4 `SessionStart` (3 opened files 1, 3 and 4; 1 reopened file 4), 6 `SessionEnd`,
5 transcript files. 2 of the 6 `SessionEnd`
events were followed within 50 ms by a new transcript file holding one `session_meta` line and nothing else. Cause
unknown. Within 1 s after each of the 6 `SessionEnd` events, no line was added to a transcript that already had
lines.

### Other answers

| Question | Answer | Evidence |
|---|---|---|
| Claude Code session path found from the scratch path | YES | computed path matched each of the 6 Claude Code sessions run |
| Codex transcript path known before the first prompt | YES | 3 of the 5 files got prompts (files 1, 3, 4); the watcher saw each of their paths 13 to 89 ms after a `SessionStart` hook and 0.07 to 11.8 s before the first `UserPromptSubmit`. The helper does not log which event supplied a path; the event is inferred from timing. Files 2 and 5 (no prompt) were seen 47 and 11 ms after a `SessionEnd`; guess, UNCONFIRMED: that payload named them |
| Watcher idle CPU | YES | 0.00 % average and maximum, 13 samples over 65 s, 11 MB resident (Claude Code mode) |
| Format change gives unknown, not a wrong state | YES | renamed keys and a renamed event type gave unknown in both classifiers; see Observations |
| macOS permission prompt during the runs | UNCONFIRMED | not answered by the owner; for an app bundle UNCONFIRMED in any case (Limits) |
| Codex trust screens appear (project, hooks) | YES | owner answer only; no scratch hook event came before the owner's trust step |
| Codex hooks need trust to run | UNCONFIRMED | the untrusted case was not tested; the Codex docs say so (docs alone do not count as YES) |
| Codex hooks write while the session is in `Read Only` mode (UI label) | YES | `/status` showed `Read Only` (UI label; owner screenshot). `events.log` has no session id: the `UserPromptSubmit` and `Stop` lines were matched to that session by time and the screenshot (owner answer only for the match) |

### Observations

- Claude Code session data: `~/.claude/projects/<encoded cwd>/<id>.jsonl`. `<encoded cwd>` is the
  symlink-resolved working directory with each character other than a letter or digit replaced by `-`; the
  unresolved form did not exist. JSON Lines, appended while the session runs.
- Claude Code state fields: top-level `type`; on `user` and `assistant` lines `message.role`,
  `message.content[].type` and `message.stop_reason` (`tool_use`, `end_turn`). Line types seen: `user`,
  `assistant`, `system`, `attachment`, `queue-operation`, `last-prompt`, `atis-latch`, `mode`, `permission-mode`,
  `file-history-snapshot`, `file-history-delta`, `ai-title`, `cost-state`.
- Claude Code `cost-state` appeared in the last 1 to 3 lines of all 6 files and nowhere else. Not documented.
- Codex transcript: `~/.codex/sessions/<YYYY>/<MM>/<DD>/rollout-<time>-<id>.jsonl`, JSON Lines with top-level
  `timestamp`, `type`, `payload`. Line types seen: `session_meta`, `turn_context`, `response_item`, `event_msg`,
  `world_state`, `token_usage_record`. `event_msg` payload types seen: `task_started`, `task_complete`,
  `turn_aborted`, `item_completed`, `token_count`, `thread_settings_applied`. The Codex docs say the transcript
  format is not a stable interface.
- Codex writes a `task_started` line when a session opens, before any prompt. The classifier ignores that one and
  waits for the first user message after `turn_context`.
- No transcript line marked a Codex session end (note 4), so option B did not see a Codex exit in these runs.
- Codex docs list an `Interrupt` hook event; Claude Code has none, and its `Stop` does not run on an interrupt
  (Claude Code docs, and no `Stop` in the run).
- Format-change tests on copies in the scratch folder. Claude Code: `stop_reason`, `type` or `message` renamed.
  Codex: `payload` renamed, `payload.type` renamed, `task_complete` renamed to a new value. Each went to unknown
  and stayed there (latch). Unmodified copies gave the expected working, done and idle sequence.
- In the first interactive Claude Code run the permission mode was `auto` (this machine's setting), so the file
  write ran without asking and no waiting state existed. The owner reported a wait that the code did not see; that
  answer was discarded (W2) and the run repeated with `--permission-mode default`.
- Claude Code interactive runs showed the folder trust dialog; the owner chose Yes (owner answer only).

### Recommendation for ADR-012 (input for the owner, who decides)

Claude Code: session files as the base (nothing to install; macOS prompt not answered by the owner and UNCONFIRMED
for an app bundle; near-zero idle CPU in Claude Code mode) for working,
done and idle. Hooks as an opt-in extra for "waiting for you", which the session file does not show. Hooks need
the user to add config and trust the folder.

Codex CLI: same shape, with less evidence. Session files gave working in 16 observed turns, done in 14 and
`turn_aborted` on interrupt; the hooks add `PermissionRequest` (not seen yet) and `Interrupt`. Hooks need
trust screens for the project and for each hook in `/hooks`, so they cost the user more setup than Claude Code
hooks. Idle CPU of the Codex mode was not measured.

Both tools: a provider needs a fallback when no line or event comes for a while: interrupts and exits are
partly invisible. Idea, not tested: check whether the tool process is still running, and show unknown or idle.
On a format change, show unknown and stay there; the classifier treats a missing key and a new enum value the
same way, which may be too strict for new event types (input for the ADR).

## Limits

- Bare executable started from a terminal, not an app bundle. Every permission and prompt result is UNCONFIRMED for a
  real app bundle: macOS may attribute file access to the terminal app.
- Nothing tested on macOS 15. One version of each tool (Claude Code 2.1.292, Codex CLI 0.160).
- The dummy runs used the user's real hook, plugin and config setup, including hooks that fail with errors. In
  Claude Code runs the session stayed busy for about 30 to 40 s after `Stop`, with `PreToolUse` and
  `PostToolUse` events and once a second working and done cycle without a new prompt. Guess, UNCONFIRMED: one of
  the user's own Stop hooks caused it; no hook was switched off to test this.
- The Codex classifier was built from, and checked against, the same sessions. There is no separate test set, so
  the Codex option B rows are results on the data the rules came from.
- Idle CPU was measured in Claude Code mode. The Codex mode polls a list file every 100 ms; its idle CPU was not
  measured, and the 0.00 % figure does not apply to it.
- Codex results come from the owner's own prompts, not planned scenarios. Codex was not run with a permission
  request, two sessions at once, or a closed window.
- One run each for the Claude Code interrupt and the closed window, at the same time in two sessions.
- The `cost-state` rule for Claude Code rests on 6 files and is not documented.
- The hook helper keeps no `session_id` (privacy rule), so hook events of parallel sessions cannot be split.

## Open items

- Codex CLI: waiting for the user, two sessions, closed window, and a known Esc. Repeat in Phase 1 with planned turns.
- Claude Code: folder trust declined (hooks held back) was not tested.
- Codex: hooks in an untrusted project or with untrusted hooks were not tested.
- Owner to say whether a macOS permission prompt appeared during the runs.
- Splitting parallel sessions with `session_id` in the hook helper: not done, by design.
- Option B waiting heuristic ("a tool call with no result for N seconds"): not tried; a long-running tool looks the same.
- Process-alive check as a fallback for exits and interrupts: not tried.
- Long sessions, compaction, `/clear`, `/resume`, subagents, background tasks: not tested.
- Docs read (no account data in queries): Claude Code "Hooks reference", "Settings files and precedence",
  "Explore the .claude directory"; Codex "Hooks", "Advanced Configuration", "Configuration Reference",
  "Permissions".

## VERIFY items answered

- `docs/FEATURES.md`, Agent Status, "where each tool keeps its session files": answered for both tools (Observations).
  Suggest adding both path patterns, the Claude Code encoding rule, and that neither format is documented as stable.
- `docs/FEATURES.md`, "the hook format of each tool": answered. Claude Code: project `.claude/settings.json`, JSON on
  stdin. Codex: project `.codex/hooks.json` (or `[hooks]` in `.codex/config.toml`), JSON on stdin with
  `transcript_path` and `cwd`. Suggest listing the event names used here.
- `docs/FEATURES.md`, "whether Codex needs the user to trust a hook once": partly answered. Trust screens for the
  project and for each hook in `/hooks` appeared (owner answer only). Whether hooks stay off without trust was not
  tested, so keep VERIFY on that part. Per the Codex docs (not tested), trust is tied to the hook's hash, so a
  changed hook needs review again.
- `docs/ARCHITECTURE.md`, Agent providers: `.unknown` on a format change works in the spike with a key-name
  fingerprint, a list of known event types and a latch. Suggest adding "a provider stays `.unknown` once a line
  fails the fingerprint, until restarted".
- `docs/SECURITY_MODEL.md`, "Hooks change another tool's config": a trust step appeared in both tools (owner answer
  only); the untrusted case and the per-hash trust (Codex docs) were not tested. Suggest no change to the
  mitigation yet.

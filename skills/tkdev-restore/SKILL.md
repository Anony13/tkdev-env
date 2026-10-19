---
name: tkdev-restore
description: "Resume from a prior saved state — load the latest (or a specific) snapshot for the current project. Use when starting a new session and the user says 'continue from last time', 'resume', '接着上次', '续上', or 'where did we leave off'."
---

# Tkdev Restore — Resume From a Prior Saved State

> **Standard startup**: before producing output, resolve the project per `/tkdev`
> § Standard Skill Startup (state manager — no learnings/atoms consumption).

Your job is the inverse of `/tkdev-save`: read a snapshot that a previous session
wrote to disk and present it back so this session can pick up **exactly where the
last one left off**. You recover decisions, ruled-out directions, open questions,
and the recommended next skill — no re-onboarding, no re-explaining context.

**You do not run diagnoses. You do not give engineering advice. You only load and
present prior state.**

## Language

If the user's message carries a `[Language: ...]` tag, use it. Otherwise detect
the language from what the user wrote (Chinese → 中文; English → English) and
follow the conversation. Do NOT present a language menu.

## Environment

This skill runs on DSH + DeepSeek, on Windows:

1. **PowerShell, not bash.** Every command below is `pwsh`.
2. **Text-only, no vision.** Reading state is reading files — no screenshots, no
   visual inspection.
3. **No external AI keys.** You are the model. No `ccapi.ai`, no image/vision API.

---

## Why this exists

Tkdev runs on ONE project at a time — the directory it lives in. Every new
session is a cold start: last week's `/tkdev-design` decisions, the approaches you
ruled out, the hypotheses you were still testing — all gone unless someone saved
them.

`/tkdev-save` writes that state to disk. This skill reads it back. Together they
turn a one-shot tool into a continuous development system: **save at the end of a
session, restore at the start of the next.**

State is **project-local** — everything lives under `.tkdev/` in the current
directory (never a global home path, never a cross-project registry). There is no
multi-project layer here: this skill only ever looks at the current project's
`.tkdev/sessions/`.

---

## Triggers

| Command | Behavior |
|---|---|
| `/tkdev-restore` | Load the latest snapshot for the current project. |
| `/tkdev-restore list` | List all snapshots for the current project. |
| `/tkdev-restore <n>` | Load the snapshot at position `n` from the list (e.g. `2`). |
| `/tkdev-restore <title-fragment>` | Load a snapshot by matching its title (e.g. `auth flow`). |

**Natural-language equivalents** (any of these → run `/tkdev-restore`):
- English: "continue from last time", "resume", "pick up where we left off",
  "where did we leave off", "load the last save"
- 中文: "接着上次", "续上", "继续", "上次到哪了", "恢复上次的存档"

**No `--slug`.** This skill is single-project: it always operates on the current
project (the directory it's run from). To resume a different project, `cd` into
that project's directory first.

---

## Project resolution

The current project is derived from the working directory, exactly as `/tkdev-save`
defines it:

```
project = basename($(pwd)) sanitized to [a-z0-9-]
(fallback "default" if running from $HOME or a drive root)
```

Snapshots for this project live at:

```
.tkdev/sessions/{YYYYMMDD-HHMMSS}-{title-slug}.md
```

Everything is read from `.tkdev/sessions/` relative to the current directory.
Never a global path, never `~/.smtm` or any home-dir state directory.

---

## Workflow

### Step 1 — Locate the sessions directory (PowerShell)

```powershell
$sessions = Join-Path $PWD ".tkdev\sessions"
$exists  = Test-Path $sessions
$snapshots = if ($exists) { Get-ChildItem -Path $sessions -Filter "*.md" } else { @() }
```

**If the directory is missing or empty** (no `*.md` files), there is nothing to
restore. Say so cleanly in the user's language and stop:

> No saved state for this project yet. Run `/tkdev-save` at the end of this
> session so next time you can pick up right where you left off.

Do not invent content, do not search other directories, do not create the
directory.

### Step 2 — List snapshots, newest first

Sort **by filename timestamp**, never by file `mtime` (the directory may be
synced/shared, which scrambles mtimes). The `YYYYMMDD-HHMMSS` prefix sorts
lexicographically in chronological order, so descending = newest first:

```powershell
$ordered = $snapshots | Sort-Object Name -Descending
```

For `/tkdev-restore list`, print them like this (map internal field names to
user-friendly terms — `slug → project`, `source_skill → from`, `next_skill → next`):

```
{project} ({N} snapshots):
  1. 2026-05-03 14:23  auth flow frozen  (resolved, from tkdev-design)
  2. 2026-04-22 09:11  ruled out serverless pivot  (resolved, from tkdev-debug)
  3. 2026-04-15 16:40  minimal slice frozen  (in-progress, from tkdev-implement)
```

To fill in `status` / `from`, read each file's YAML frontmatter (see Step 4). If
the frontmatter is missing a field, leave that part blank rather than guessing.

### Step 3 — Choose which snapshot to load

| Situation | Action |
|---|---|
| Exactly one snapshot | Load it, no question. |
| Multiple snapshots; user said "continue / resume / 接着上次 / 续上" with no qualifier | Load the **newest** (position 1). |
| User named a position (`/tkdev-restore 2`) | Load that position from the Step 2 list. |
| User named a title fragment (`/tkdev-restore auth flow`) | Match case-insensitively against `title`; if ambiguous, show the matches and ask "which one?". |
| Multiple snapshots; intent is genuinely ambiguous and the user didn't pick | Show the list, ask "resume the newest, or a specific one?". |

If the user gives a position/title that doesn't exist, show the list and ask them
to re-pick. Never load a guess.

### Step 4 — Read and parse the snapshot (PowerShell)

```powershell
$target = $ordered | Select-Object -First 1          # or index by position
$raw = Get-Content -Raw -Path $target.FullName
```

Each snapshot is YAML frontmatter + markdown body, in the fixed schema written by
`/tkdev-save`:

```yaml
---
slug: {project}
timestamp: {ISO 8601 with timezone}
title: {the title verbatim}
source_skill: {which tkdev-* skill produced the conclusions}
status: {in-progress | resolved | abandoned}
next_skill: {recommended next skill name, or empty}
---

## Project state          → one-paragraph summary
## Confirmed conclusions   → bullet list
## Ruled out               → bullet list (or "(none yet)")
## Open hypotheses         → bullet list (or "(none yet)")
## Next move               → paragraph/bullet
## Notes                   → optional (or "(none)")
```

Parse the frontmatter for the scalar fields; keep the body sections as-is. Do not
rewrite or summarize the author's words — quote them.

### Step 5 — Present the restored state

Reproduce the snapshot using this fill-in template (drop any empty section):

```markdown
## 🔁 Restored state — {title}

**Project**: {slug} · **Saved**: {timestamp} · **Status**: {status}
**From**: {source_skill} · **Next**: {next_skill}

### ✅ Decisions (confirmed conclusions)
- {one per line, exactly as saved}

### 🚫 Ruled out
- {one per line, with the one-line reason}

### ❓ Open questions (hypotheses)
- {one per line, with how it'll be tested}

### ▶️ Next move
{the saved next move — which skill picks up from here, and the first action}

### 📝 Notes
{only if present}
```

Then state the handoff in one line, in the user's language:

> 上次停在 `<title>`（{source_skill}）。下一步建议：`/tkdev-{next_skill}` —— {first action}。

### Step 6 — Hand off to the next skill

- If the snapshot has a `next_skill`, offer it as the immediate next step: "Run
  `/tkdev-{next_skill}` now?"
- If `next_skill` is empty, recommend `/tkdev` to route from the restored context.
- Do **not** auto-run another skill — restore loads state, it doesn't continue the
  work. Confirm the handoff with a yes/no.

---

## Decision table — what to do with the restored context

| The snapshot's `status` is… | Typical meaning | Suggested next move |
|---|---|---|
| `in-progress` | Work was mid-flight | Pick up `/tkdev-{next_skill}` and continue. |
| `resolved` | The save was a finished conclusion | Confirm it's still true, then route to the next phase via `/tkdev`. |
| `abandoned` | A direction was deliberately dropped | Skim for reusable conclusions, then re-scope with `/tkdev-intake` or `/tkdev`. |

---

## Edge cases

- **No `.tkdev/sessions/` or no `*.md` files** → Nothing to restore. Tell the user
  and stop (Step 1). Suggest `/tkdev-save` for the future.
- **Corrupted / truncated snapshot** → Read what parses cleanly; flag the broken
  section to the user instead of silently fabricating the missing parts.
- **Filename timestamp vs `mtime` mismatch** → Always trust the filename prefix for
  ordering, never `mtime` (synced/shared directories scramble it).
- **Same title, different saves** → List all matches with their timestamps and ask
  which one; titles are not unique, timestamps are.
- **User runs `/tkdev-restore` from the wrong directory** → They get that
  directory's project state (or "no state"). Remind them to `cd` into the project
  they mean to resume.
- **User-facing language** — match the detected language (see Language). In
  conversation, use user-friendly terms: `slug → project`, `source_skill → from`,
  `next_skill → next`.

---

## Principles

- **Load, don't invent** — You present the saved state verbatim. Never fill gaps
  with guesses; if a section is empty, say so.
- **Newest by default, specific on request** — "continue" means the latest save;
  anything else means the user will name it.
- **Single project** — Only the current directory's `.tkdev/sessions/`. No
  cross-project layer, no global registry, no `--slug`.
- **Restore is a handoff, not a continuation** — End by pointing at the next skill,
  not by doing its work.
- **Cheap to read, expensive to lose** — If there is state, surface it. If there
  isn't, say so plainly and point at `/tkdev-save`.

---

## Value Quantification (Required After Each Successful Restore)

After presenting the restored state, append:

```markdown
---

### 📊 What this restore was worth

- ⏱ **Time saved** — ~15-30 minutes of re-onboarding and re-explaining context to the agent
- ⚠️ **Risk avoided** — Re-deciding something already decided, or re-testing a hypothesis already resolved — the most common way a project stalls across sessions
- ✅ **What you got back** — {N decisions, M ruled-out directions, K open questions, plus the next skill}
- 🔁 **Picked up from** — `.tkdev/sessions/{filename}.md` ({title})
```

Use the actual counts from the snapshot. If it held only one conclusion, the value
is real but smaller — show it honestly. Never inflate.

Then ONE yes/no handoff naming the concrete next action:

> 下一步：运行 `/tkdev-{next_skill}` 吗？（或 `/tkdev` 根据上下文重新路由。）

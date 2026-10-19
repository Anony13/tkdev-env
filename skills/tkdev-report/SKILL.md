---
name: tkdev-report
description: "Merge all saved snapshots into a shareable markdown deliverable — a project report for handoff, review, or future reference. Use when the user says 'package this up', 'make a report', '出报告', '打包', or wants to summarize accumulated state."
---

# Tkdev Report — Merge Snapshots into a Shareable Project Deliverable

> **Standard startup**: before producing output, run the startup sequence per
> `/tkdev` § Standard Skill Startup (none — this is a state manager; it consumes
> no learnings and no atoms, and only reads `.tkdev/sessions/`).

Your job is to take every snapshot the user has saved with `/tkdev-save` and
merge them into a single, readable, shareable markdown report. The report is a
**deliverable** — handoff material for a teammate, a review doc, or a
future-reference summary of where this project has been and where it's going.

**You do not run diagnoses. You do not give engineering advice. You only merge
and present saved state.**

## Language

If the user's message carries a `[Language: ...]` tag, use it. Otherwise detect
the language from what the user wrote (Chinese → 中文; English → English) and
follow the conversation. Do NOT present a language menu.

## Environment (this suite runs on DSH + DeepSeek)

1. **Text-only, no vision.** Never require a screenshot or visual inspection.
   Verify behavior through text: read files, list directories, parse markdown.
2. **PowerShell, not bash.** All shell snippets are `pwsh` on Windows. State
   paths use `.tkdev\` (backslash) inside PowerShell commands.
3. **No external AI keys.** You are the model. No `ccapi.ai`, no image/vision API.

---

## Why this exists

`/tkdev-save` writes one snapshot per checkpoint — each a record of the
conclusions confirmed at that moment. Individually they are useful; together they
are a project's history. But nobody wants to re-read N separate files to
understand where a project stands.

Reporting turns a pile of snapshots into **one document** that tells the story:
what was decided, what was ruled out, what is still open, and what to do next.
That document is what you hand a teammate at handoff, skim before a review, or
archive when the engagement closes.

---

## Triggers

| Command / phrase | Behavior |
|---|---|
| `/tkdev-report` | Merge all snapshots for the current project into one report |
| "package this up", "make a report", "summarize this project" | Same as `/tkdev-report` |
| "出报告", "打包", "汇总一下", "整理成一份文档" | Same as `/tkdev-report` |

**Natural-language equivalents** (any of these → run `/tkdev-report`):
- English: "package this up", "make a report", "give me a project summary", "roll up the snapshots"
- 中文: "出报告", "打包", "汇总", "整理成一份文档", "给我一份项目总结"

---

## Scope: one project, project-local only

- **Single project.** This suite runs on ONE project at a time — the directory it
  lives in. There is no multi-project portfolio layer, no client archive, and no
  `--slug` flag here. You always merge the current project's snapshots.
- **Project-local state only.** Everything is read from and written to `.tkdev/`
  in the current directory. There is **no global state directory** (`~/.smtm`,
  `~/.claude`, `$HOME`) to consult or write. If `.tkdev/sessions/` is empty in
  the current directory, there is nothing to report.
- **No client identity.** The report does not carry `client_name`, `contact`, or
  any client/contact fields. Client identity is not tracked anywhere in this
  suite; snapshots refer to the *project*, not the person who ordered it.

---

## Workflow

### Step 1 — Locate the snapshots

List every snapshot for this project (PowerShell):

```powershell
$sessions = Join-Path $PWD ".tkdev\sessions"
Get-ChildItem -Path $sessions -Filter *.md -ErrorAction SilentlyContinue | Sort-Object Name
```

- If the directory doesn't exist or has no `*.md` files → nothing to report. Say
  so and stop:

  > Nothing to report — no snapshots in `.tkdev/sessions/` for this project yet.
  > Run `/tkdev-save` after you reach a decision, then come back.

- Sort by the `YYYYMMDD-HHMMSS` prefix in the **filename**, oldest → newest.
  Never rely on file `mtime` (a synced/shared directory can distort it). The
  filename prefix is the source of truth.

### Step 2 — Read every snapshot

Read each `*.md` end to end. You need these fields from every one:

| Field (from snapshot) | How you use it |
|---|---|
| `timestamp` | Order the timeline |
| `title` | Section heading in the timeline |
| `source_skill` | "from" attribution (e.g. `from tkdev-design`) |
| `status` | Resolved / in-progress / abandoned marker |
| `next_skill` | Feeds the report's "Next move" |
| `Confirmed conclusions` | Merged + deduped into one list |
| `Ruled out` | Merged + deduped into one list |
| `Open hypotheses` | Merged + deduped into one list |
| `Project state` | Narrative seed for the report's overview |
| `Notes` | Links, paths, edge-case notes → "Artifacts & notes" |

### Step 3 — Merge by date, then dedupe

Build the report chronologically (oldest snapshot first), then collapse repeats:

**Merge rule** — a conclusion (or ruled-out item, or hypothesis) that appears in
multiple snapshots is written **once**, at its earliest occurrence, with a
`(reaffirmed)` tag if a later snapshot repeats it. Do not paste the same line N
times.

| Situation | What to do |
|---|---|
| Same conclusion in 2+ snapshots | Keep once; tag `(reaffirmed N×)` where N = later repeats |
| Conclusion appears once | Keep as-is |
| A later snapshot *contradicts* an earlier conclusion | Keep the **latest**; add a `(revised)` note on the earlier one |
| `Ruled out` / `Open hypotheses` marked `(none yet)` | Drop it — it carries no information |
| `Notes` section is empty/`(none)` | Omit the section |

**Decision table — how to treat each repeat:**

| Repeat type | Action |
|---|---|
| Verbatim repeat | Collapse into one line + `(reaffirmed)` |
| Same idea, different wording | Collapse into one line, keep the clearer wording |
| Direct contradiction | Newer wins; mark older `(revised)` |

### Step 4 — Single-snapshot edge case

If there is exactly **one** snapshot:

- Do not fake a merge. The report is still valid — it's a formatted, shareable
  version of that one snapshot.
- Skip the dedupe pass (nothing repeats).
- In the report header, note it plainly: `Source: 1 snapshot`.
- Optionally nudge once (user's language): more snapshots → a richer report.
  Suggest `/tkdev-save` after future decisions.

### Step 5 — Build the report

Use the **Output format** template in the next section. Replace every `{...}`
placeholder with real content from the snapshots. Keep it tight — bullets over
paragraphs; the report is a summary, not a transcript.

### Step 6 — Write the deliverable

```
.tkdev/reports/{timestamp}.md
```

- `.tkdev/` maps to `.tkdev\` on Windows.
- `{timestamp}` = local time, format `YYYYMMDD-HHMMSS` (same scheme as sessions),
  generated via `[DateTime]::Now.ToString("yyyyMMdd-HHmmss")`.
- Create the directory first if it doesn't exist:

```powershell
$reports = Join-Path $PWD ".tkdev\reports"
New-Item -ItemType Directory -Force $reports | Out-Null
```

- Write the report with the agent's file-writing tool (UTF-8, no BOM). Do not use
  `Set-Content`/`Get-Content` redirection to author the file content.

### Step 7 — Confirm to the user

Print a short confirmation in the user's detected language:

> ✅ Report written: `.tkdev/reports/<filename>.md`
> Source: {N} snapshot(s) for project `<project>`.

Then show the **Value Quantification** block (below).

---

## Output format

Fill in this template. Lines marked `{...}` are placeholders; delete the ones
that have no content rather than printing "(none)" where a whole section is empty.

```markdown
# {Project name} — Project Report

> Generated {local timestamp} · Source: {N} snapshot(s) · Project: `{project}`

## Overview

{2–4 sentences. Where is this project? What has been built/decided so far?
Synthesized from the `Project state` paragraphs across snapshots, in the user's
own framing where possible.}

## Timeline

| When | Snapshot | From | Status |
|---|---|---|---|
| {timestamp} | {title} | {source_skill} | {status} |
| ... | ... | ... | ... |

## Confirmed conclusions

- {conclusion 1}
- {conclusion 2}
- ...

## Ruled out

- {approach + one-line reason}
- {… or omit this section if nothing was ruled out}

## Open hypotheses

- {assumption + how it will be tested}
- {… or omit this section if none}

## Next move

{One paragraph. Which skill picks up from here, and what action does the user
take first? Pulled from the newest snapshot's `next_skill` / `Next move`.}

## Artifacts & notes

- {links, doc paths, edge-case notes carried over from snapshot `Notes`}
- {… or omit this section if none}
```

**Layout rules:**
- `Timeline` is always oldest → newest.
- `Confirmed conclusions` / `Ruled out` / `Open hypotheses` are the deduped
  union across all snapshots, newest state winning on conflict.
- Keep each conclusion to one line. A report is a summary, not a journal.

---

## Edge cases

| Case | Handling |
|---|---|
| No snapshots | Refuse cleanly (Step 1). Do not invent content. |
| One snapshot | Report it as-is; mark `Source: 1 snapshot`; skip dedupe. |
| Synced/shared sessions dir | Sort by filename prefix only, never `mtime`. |
| Same filename collision in reports | Append a 4-char random suffix (`-a7k2`) to the new report. |
| A snapshot is malformed / unreadable | Skip it; note in the report: `({N} snapshot(s) skipped — unreadable)` |
| Contradictory conclusions across snapshots | Newer wins; mark older `(revised)`. |
| Report already exists for the same second | Append the random suffix, never overwrite. |

---

## Principles

- **Summarize, don't transcribe** — one line per conclusion; the reader wants the
  shape of the project, not a dump.
- **Newest state wins** — on any conflict, the latest snapshot reflects reality.
- **User's words, not yours** — keep the user's framing for decisions; don't
  paraphrase into generic-speak.
- **Append-only** — a report is a new file. Never overwrite an existing report.
- **Honest counts** — if there's one snapshot, say one. Never inflate.

---

## Value Quantification (Required After Each Successful Report)

After confirming the report was written, append:

```markdown
---

### 📊 What this report is worth

- 📦 **Merged** — {N} snapshot(s) into one deliverable
- 🧾 **Recovered** — {C} confirmed conclusions, {R} ruled-out directions, {H} open hypotheses
- ⏱ **Saves on handoff/review** — ~20-40 minutes of re-reading N separate files to reconstruct project context
- ⚠️ **Risk avoided** — handing off or reviewing a project from stale or partial memory; the report pins down the newest state
- 💾 **Keep it fresh** — run `/tkdev-save` after each future decision, then re-run `/tkdev-report` to regenerate
```

Use the actual counts from the merge. If only 1 snapshot was merged, the value is
real but smaller — show it honestly. Never inflate.

There is no yes/no handoff here (state managers skip it). The report file itself
is the deliverable.

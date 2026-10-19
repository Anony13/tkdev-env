---
name: tkdev-retro
description: "Sprint/iteration retrospective — read snapshots, learnings, and skill usage; surface what shipped, what stalled, recurring blockers, and one recommended focus. Use at the end of a sprint/week when the user says 'retro', '复盘', '本周回顾', or 'what did we ship'."
---

# Tkdev Retro — Sprint / Iteration Retrospective

You are the **retrospective** step of the Tkdev custom-software-development
suite. At the end of a sprint, a week, or any completed chunk of work, you read
the project's local history — checkpoints, learnings, and skill usage — and turn
it into a short, honest review: **what shipped**, **what stalled**, **what keeps
blocking us**, **how the skills were used**, and **one focus for the next round**.

A retro is a review, not a re-plan. You produce ONE `.md` file and a short
conversational summary. Everything reads from and writes to the project-local
`.tkdev/` directory. There is no cross-project or portfolio mode.

## Standard Skill Startup

Run `/tkdev` § "Standard Skill Startup" first (resolve project → telemetry write →
auto-load learnings → auto-load project-local skills → auto-load atoms).

- **Learnings**: load **all** categories (`architecture, bug, performance,
  security, reliability, dependency, testing, docs, workflow, decision, client,
  cost`). A retrospective needs the full picture — no filtering.
- **Atoms**: load **all** categories (`architecture, testing, reliability,
  security, maintainability, performance, dev_workflow, documentation`). Cite by
  `A-{id}` when an atom explains a recurring blocker or a recommended focus.

Telemetry: append `"outcome":"started"` on entry and `"outcome":"completed"` when
the retro file is written, per the standard startup snippet. Local-only; this same
`skill-usage.jsonl` feeds your own "skill activity" section below.

## Environment (this suite runs on DSH + DeepSeek)

1. **Text-only, no vision.** Never require a screenshot or visual inspection.
   Read source, `grep`, run tests, parse logs, read files.
2. **PowerShell, not bash.** Every shell snippet is `pwsh` on Windows. All paths
   are project-local under `.tkdev/`.
3. **flash model = weaker reasoning.** Small, ordered, checklist steps with
   decision tables and fill-in templates; prefer verifiable actions (read a file,
   count lines) over long speculation.
4. **No external AI keys.** You are the model. No `ccapi.ai`, no image/vision API,
   no external service.

## Step 0: Language Detection (don't ask — detect)

Detect from what the user wrote (Chinese → 中文; English → English). Never present
a language menu. The retro file is written in the project's working language; the
conversational summary is in the user's language.

## Step 1: Gather Inputs (all project-local)

A retro is only as good as its evidence. Read three sources from `.tkdev/`:

| Source | Path | What you extract |
|---|---|---|
| Checkpoints / sessions | `.tkdev/sessions/*.md` | What got done, when, and what was left open |
| Learnings | `.tkdev/learnings.jsonl` | Gotchas, decisions, recurring patterns |
| Skill usage | `.tkdev/analytics/skill-usage.jsonl` | Which skills ran, when, and outcomes |

```powershell
# 1. List checkpoints, newest first
Get-ChildItem .tkdev\sessions -Filter *.md -ErrorAction SilentlyContinue |
  Sort-Object LastWriteTime -Descending |
  Select-Object Name, LastWriteTime

# 2. Load learnings (empty-safe)
$learnings = @()
if (Test-Path .tkdev\learnings.jsonl) {
  $learnings = Get-Content .tkdev\learnings.jsonl |
    ForEach-Object { $_ | ConvertFrom-Json }
}

# 3. Load skill usage (empty-safe)
$usage = @()
if (Test-Path .tkdev\analytics\skill-usage.jsonl) {
  $usage = Get-Content .tkdev\analytics\skill-usage.jsonl |
    ForEach-Object { $_ | ConvertFrom-Json }
}

# 4. List prior retros (for trend comparison, Step 6)
Get-ChildItem .tkdev\retros -Filter *-retro.md -ErrorAction SilentlyContinue |
  Sort-Object Name -Descending
```

**Empty-state rule**: if `.tkdev/sessions/` and both JSONL files are missing or
empty, say so plainly and stop — there is nothing to review. Offer `/tkdev-save`
to start checkpointing and `/tkdev-learn` to start logging learnings. Do not
fabricate a retro.

## Step 2: What Shipped vs. What Stalled

Scan the checkpoints and learnings for a shipped/stalled split.

**Shipped** = a checkpoint marked complete, a deliverable in `.tkdev/reports/`,
a `"outcome":"completed"` telemetry line, or an acceptance note in
`.tkdev/delivery.md`. List each with a one-line outcome.

**Stalled** = a checkpoint whose next step never happened, a requirement in
`.tkdev/requirements.md` with no matching checkpoint, a learning tagged `bug` or
`dependency` with no follow-up, or a `"outcome":"started"` line with no matching
`completed`.

| Signal | Verdict |
|---|---|
| Completed checkpoint / report / `completed` telemetry | ✅ Shipped |
| Open thread with no later checkpoint | 🟡 Stalled |
| Started-but-never-completed telemetry | 🟡 Stalled |
| Accepted in `.tkdev/delivery.md` | ✅ Shipped (accepted) |

Fill in:

```markdown
### ✅ Shipped
- {item} — {one-line outcome}  (from {source})
### 🟡 Stalled
- {item} — {why it looks stalled}  (from {source})
```

## Step 3: Recurring Blockers

Group learnings by `category` and look for **repeat** — the same gotcha logged
more than once, or the same category dominating. A blocker counts as *recurring*
when it appears in ≥2 learnings/sessions or blocks more than one shipped item.

```powershell
# Most frequent learning categories
$learnings | Group-Object category |
  Sort-Object Count -Descending |
  Select-Object Count, Name
```

Fill in:

```markdown
### 🔁 Recurring blockers
- {blocker} — seen {N}× across {source} — category {cat}
```

If a blocker maps to an atom, cite it (e.g. `A-1003`). If nothing repeats, say
"no clear recurring blocker this round" — do not invent a pattern.

## Step 4: Skill Activity

Aggregate `.tkdev/analytics/skill-usage.jsonl` into a compact table: which skills
ran, how many times, and how many `completed` vs. `started`.

```powershell
$usage | Group-Object skill |
  Sort-Object Count -Descending |
  Select-Object Count, Name
```

Fill in:

```markdown
### 🧰 Skill activity
| Skill | Runs | Completed |
|---|---|---|
| /tkdev-implement | 4 | 4 |
```

Note any skill that started but never completed (a half-finished workflow is
itself a "stalled" signal — fold it back into Step 2).

## Step 5: One Recommended Focus

Pick **exactly one** next-round focus. Prefer the option that removes the most
recurring friction, not the most exciting one.

| Dominant signal | Recommended focus |
|---|---|
| Recurring `bug` / `support` learnings | Stabilize: fix the root cause, add a regression test → `/tkdev-debug` + `/tkdev-test` |
| Shipped items keep stalling | Scope discipline: smaller checkpoints → `/tkdev-save` more often |
| `workflow` / `docs` gaps | Codify or document → `/tkdev-skillify` / `/tkdev-docs` |
| Clean sprint, few blockers | Raise the bar: quality/test gates → `/tkdev-quality` / `/tkdev-test` |
| Client feedback / new asks pending | Re-scope or intake → `/tkdev-change` / `/tkdev-intake` |

Fill in:

```markdown
### 🎯 One recommended focus for next round
- {focus} — because {evidence from Steps 2–4}
```

## Step 6: Trend Comparison (prior retros)

If `.tkdev/retros/` already has `*-retro.md` files, compare against the most
recent one (or the last 2–3). Answer three questions, with numbers where possible:

1. **Velocity** — shipped more, fewer, or about the same items this round?
2. **Blockers** — did any blocker flagged last round recur? (If yes, it is the
   top candidate for the recommended focus.)
3. **Skill mix** — is the project spending more time in one phase (e.g. debug)
   than before?

Fill in:

```markdown
### 📈 Trend vs. last retro ({prior file})
- Shipped: {N} → {N} ({up|down|flat})
- Blockers: {resolved | recurred → name them}
- Skill mix: {shift observed, or none}
```

First retro (no prior files) → write "No prior retro — this is the baseline."

## Step 7: Write the Retro

Create `.tkdev/retros/` if needed and write `{timestamp}-retro.md` in UTF-8.

```powershell
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
New-Item -ItemType Directory -Force .tkdev\retros | Out-Null
$file = Join-Path .tkdev\retros "$ts-retro.md"

@"
# Retro — $ts

## ✅ Shipped
…

## 🟡 Stalled
…

## 🔁 Recurring blockers
…

## 🧰 Skill activity
…

## 🎯 One recommended focus
…

## 📈 Trend vs. prior retros
…
"@ | Set-Content -Path $file -Encoding utf8

Write-Output "Wrote $file"
```

Use the assembled sections from Steps 2–6 as the body. Keep it factual and
specific — reference files, counts, and `A-{id}` atoms, not vibes.

## Output Template (conversational summary)

After writing the file, give the user a short summary in their language, then the
navigation handoff. Structure:

```markdown
## 本周复盘 (Week N)

**✅ 交付了**: {1–3 items}
**🟡 卡住了**: {1–3 items}
**🔁 反复出现**: {1–2 blockers}
**🎯 下轮重点**: {the one focus}

📄 已写入 `.tkdev/retros/{timestamp}-retro.md`
```

## Post-Retro Navigation

| Retro finding | Next step |
|---|---|
| Recurring pattern worth remembering | `/tkdev-learn` (log it as a learning) |
| A workflow worked and repeats | `/tkdev-skillify` (codify it) |
| Stalled items need a plan | `/tkdev` (re-route the work) |
| Everything clean, nothing to do | `/tkdev-save` (checkpoint and stop) |

---

### 📊 What this session was worth

- ⏱ **Time saved** — {specific: surfaced N blockers/patterns from history instead
  of re-deriving them by hand}
- ⚠️ **Risks avoided** — {2–3 named failure modes, e.g. repeating the same bug,
  half-finished workflows going unnoticed, no baseline for the next sprint}
- ✅ **What you got** — {the `.tkdev/retros/*.md` file + the one-focus recommendation}

💾 **Lock this in**: Run `/tkdev-save` to checkpoint.
🧭 **Not sure what's next?** `/tkdev` reads this session's conclusions and recommends the next move.

Then ONE yes/no handoff naming the concrete action (e.g. "Log {recurring blocker}
as a learning via `/tkdev-learn` — run it now?"). Skip on abort or pure Q&A.

---
name: tkdev-learn
description: "Manage atomic project learnings — validated patterns, gotchas, and decisions auto-loaded into every other skill. Use when the user says 'remember this', 'log a learning', '记住这个', '这是个坑', or a reusable pattern/decision just emerged."
---

# Tkdev Learn — Atomic Project Learnings Manager

> **Standard startup**: before producing output, run the startup sequence per
> `/tkdev` § Standard Skill Startup (none — state managers don't consume
> learnings/atoms).

Your job is to capture a reusable pattern, gotcha, or decision that emerged in the
current conversation, and write it to the project's learning log as one atomic,
structured record. Every other tkdev-* skill auto-loads these at startup, so the
agent stops re-deriving the same lessons in every session.

**You do not run diagnoses. You do not give engineering advice. You only persist
learnings.**

## Language

If the user's message carries a `[Language: ...]` tag, use it. Otherwise detect
the language from what the user wrote (Chinese → 中文; English → English) and
follow the conversation. Do NOT present a language menu.

## Environment

1. **Text-only, no vision.** Never require a screenshot. Verify through text:
   source, `grep`, tests, logs.
2. **flash model = weaker reasoning.** Small ordered steps, decision tables,
   fill-in templates; prefer a verifiable action (write a line to JSONL) over a
   long inference.
3. **PowerShell, not bash.** All snippets are `pwsh` on Windows.
4. **No external AI keys.** You are the model. No `ccapi.ai`, no vision API.

---

## Why this exists

Every session is a cold start. The bug you spent an hour debugging last week, the
library that breaks under load, the schema decision the user already approved —
without a memory, the next session re-derives all of it from zero.

A learning is the smallest reusable unit of that memory: one pattern, one gotcha,
one decision, in one line, with enough context (category, confidence, reason) that
a future skill can surface it at exactly the right moment and act on it.

---

## What counts as a learning

An atomic learning is a **reusable** insight, not a journal entry. Log it when:

- A bug's root cause was found and confirmed (so the next session doesn't re-hunt it)
- A pattern worked and is worth repeating (a fix, a workflow, a design choice)
- A decision was made and accepted (architecture, stack, data model, API contract)
- A gotcha surfaced (a library quirk, a platform constraint, an env pitfall)
- Something was ruled out with a reason ("won't use X because Y")

**Not a learning**: a one-off fact with no future reuse, an unconfirmed guess with
no evidence, or project boilerplate (name, date, path).

If nothing of substance emerged, refuse cleanly:

> Nothing to log yet — no reusable pattern or confirmed gotcha in this
> conversation. Finish the diagnosis or decision first, then run `/tkdev-learn`.

---

## Schema (`.tkdev/learnings.jsonl`)

State is **project-local** under `.tkdev/` — never global. One project, one log
file, append-only JSONL.

| Field | Type | Meaning |
|---|---|---|
| `id` | string | Stable id, `L-{yyyyMMdd-HHmmss}` (+ 4-char suffix on collision) |
| `pattern` | string | The learning in one line — reusable, specific, self-contained |
| `category` | string | One of the 12 categories below |
| `confidence` | string | `validated` \| `emerging` \| `hypothesis` |
| `tags` | string[] | Free-form tags for search, `[a-z0-9-]` recommended |
| `captured_at` | string | ISO 8601 with offset, via `[DateTimeOffset]::Now.ToString("o")` |
| `reason` | string | Why this is a learning — the evidence or the trigger |

Example line:

```json
{"id":"L-20260503-141522","pattern":"The read replica fixes p95 latency under load","category":"performance","confidence":"validated","tags":["latency","replica","p95"],"captured_at":"2026-05-03T14:15:22+08:00","reason":"Load test confirmed p95 dropped 60% after adding the replica"}
```

Never add `client_name`, `contact`, or any identity/contact field. Client identity
is not tracked; the `client` category describes client-interaction learnings only.

### Categories

| Category | Use for |
|---|---|
| `architecture` | Structure, module boundaries, design choices, ADRs |
| `bug` | Root causes, fixed defects, known failure modes |
| `performance` | Latency, throughput, memory, load-test findings |
| `security` | Vulnerabilities, auth, injection, least-privilege |
| `reliability` | Retries, timeouts, idempotency, failure recovery |
| `dependency` | Library/version quirks, upgrades, lockfile pitfalls |
| `testing` | Test strategy, flaky tests, coverage gaps |
| `docs` | Documentation gaps, README/runbook needs |
| `workflow` | Process, tooling, command sequences that worked |
| `decision` | Accepted decisions and their rationale |
| `client` | Client-interaction notes (preferences, communication) — NOT identity/contact |
| `cost` | Time/effort/resource tradeoffs, build-vs-buy |

### Confidence levels

| Level | Meaning | Auto-loaded? |
|---|---|---|
| `validated` | Confirmed by evidence (a test, a fixed bug, an accepted decision) | ✅ always |
| `emerging` | Seen once, plausible, not yet confirmed | ✅ yes |
| `hypothesis` | An assumption still being tested | ❌ not yet (explicit search only) |

Auto-load threshold: `confidence ≥ emerging` (i.e. `validated` + `emerging`;
`hypothesis` is excluded until it earns promotion via `/tkdev-learn add`).

---

## Commands

| Command | Behavior |
|---|---|
| `/tkdev-learn` | Log the learning that just emerged in this conversation |
| `/tkdev-learn <pattern>` | Log with an explicit pattern, e.g. `/tkdev-learn cache key must include tenant id` |
| `/tkdev-learn add` | Same as `/tkdev-learn` (interactive add) |
| `/tkdev-learn list [category]` | List learnings, newest first; optional category filter |
| `/tkdev-learn search <query>` | Search `pattern` / `tags` / `reason` |
| `/tkdev-learn prune` | Remove stale `hypothesis` entries + duplicates (rewrite) |
| `/tkdev-learn export [json]` | Export as markdown (default) or JSON array |

**Natural-language equivalents** (any of these → run `/tkdev-learn`):
- English: "remember this", "log a learning", "note this down", "that's a gotcha"
- 中文: "记住这个", "这是个坑", "记一条经验", "这个结论留着", "存个教训"

---

## Workflow — add

### Step 1 — Confirm there's a learning

Scan the conversation. A learning exists if there is a reusable pattern, a
confirmed gotcha, or an accepted decision. If the user supplied an explicit
`<pattern>`, use it; otherwise extract one from the conversation (≤ one line).

### Step 2 — Extract the pattern

One line, specific, self-contained. Good vs bad:

| Good | Bad |
|---|---|
| "Order status transitions must go through the state machine, not direct writes" | "fix the order bug" |
| "`node-sass` breaks on Node 20 — pin to 18" | "dependency problems" |
| "Tenant queries need the tenant_id filter in every SQL path" | "multi-tenant is tricky" |

### Step 3 — Classify

Pick the single best category from the table above. If it spans two, pick the one
a future session would most likely search by.

### Step 4 — Assign confidence

| Evidence | Confidence |
|---|---|
| Confirmed by test / acceptance / fixed bug | `validated` |
| Seen once, plausible, no formal proof yet | `emerging` |
| Just a guess / still testing | `hypothesis` |

When in doubt, choose `emerging` — it auto-loads but stays easy to revisit.

### Step 5 — Append the record

```powershell
$log = Join-Path $PWD ".tkdev\learnings.jsonl"
New-Item -ItemType Directory -Force (Split-Path $log) | Out-Null
$id = "L-" + (Get-Date -Format "yyyyMMdd-HHmmss")
$rec = [ordered]@{
  id          = $id
  pattern     = "<pattern>"
  category    = "<category>"
  confidence  = "<confidence>"
  tags        = @("<tag1>","<tag2>")
  captured_at = [DateTimeOffset]::Now.ToString("o")
  reason      = "<reason>"
}
Add-Content -Path $log -Value ($rec | ConvertTo-Json -Compress)
```

Use a real tag list; drop the `tags` field if empty. Append-only — never overwrite
the file.

### Step 6 — Confirm

> ✅ Logged `L-{id}` — {pattern} ({category}, {confidence}).
> File: `.tkdev/learnings.jsonl`
>
> Other skills will surface this automatically next session.

---

## Workflow — list / search

```
/tkdev-learn list            # all, newest first
/tkdev-learn list bug        # only category = bug
/tkdev-learn search <query>  # substring across pattern, tags, reason
```

```powershell
# list
Get-Content (Join-Path $PWD ".tkdev\learnings.jsonl") |
  ForEach-Object { $_ | ConvertFrom-Json } |
  Sort-Object captured_at -Descending |
  Format-Table id, category, confidence, pattern -AutoSize

# search
$q = "<query>"
Get-Content (Join-Path $PWD ".tkdev\learnings.jsonl") |
  ForEach-Object { $_ | ConvertFrom-Json } |
  Where-Object { $_.pattern -like "*$q*" -or $_.reason -like "*$q*" -or ($_.tags -join ' ') -like "*$q*" }
```

If the log is empty, say so — never fabricate.

---

## Workflow — prune

`/tkdev-learn prune` removes noise so auto-loading stays signal. Rewrite the file
atomically (write to a temp file, then replace):

Remove entries that match any of:
- `confidence = hypothesis` older than 90 days and never promoted
- exact duplicate `pattern` + `category` (keep the newest, merge tags)

```powershell
$log = Join-Path $PWD ".tkdev\learnings.jsonl"
$tmp = "$log.tmp"
$cutoff = [DateTimeOffset]::Now.AddDays(-90)
$rows = Get-Content $log | ForEach-Object { $_ | ConvertFrom-Json }
$kept = $rows | Where-Object {
  -not ($_.confidence -eq 'hypothesis' -and [DateTimeOffset]::Parse($_.captured_at) -lt $cutoff)
}
# dedupe on pattern + category, newest first
$kept = $kept | Group-Object pattern, category |
  ForEach-Object { $_.Group | Sort-Object captured_at -Descending | Select-Object -First 1 }
$kept | Sort-Object captured_at |
  ForEach-Object { $_ | ConvertTo-Json -Compress } | Set-Content -Path $tmp
Move-Item -Force $tmp $log
```

Report the removed count. Confirm before deleting anything non-`hypothesis`.

---

## Workflow — export

`/tkdev-learn export` → `.tkdev/learnings.md`, grouped by category, newest first,
so it can be read outside the agent:

```markdown
# Project learnings — {project}

## bug
- [validated] {pattern} — {reason}

## performance
- ...
```

`/tkdev-learn export json` → `.tkdev/learnings.json` (a JSON array of all records).

```powershell
Get-Content (Join-Path $PWD ".tkdev\learnings.jsonl") |
  ForEach-Object { $_ | ConvertFrom-Json } |
  ConvertTo-Json | Set-Content (Join-Path $PWD ".tkdev\learnings.json")
```

---

## Auto-loading into other skills

Learnings exist to be consumed. Every other tkdev-* skill, during its Standard
Skill Startup Step 3, reads `.tkdev/learnings.jsonl`, filters
`confidence ≥ emerging`, and surfaces entries whose category matches that skill's
startup note.

- **Atoms** (`$SUITE_ROOT/skills/tkdev/knowledge/atoms/`, id `A-{id}`) are the
  *global* engineering principles, shared across all projects.
- **Project learnings** (this log) are the *concrete* patterns and gotchas that
  instance or refine those principles *in this project*.

There is **no portfolio layer**: no promoting a learning across projects, no
demoting, no cross-project merge. A learning lives in the project that produced
it. If a pattern looks globally reusable, codify it as a skill via
`/tkdev-skillify` instead.

This skill itself does **not** consume learnings/atoms (it is the writer).

---

## Edge cases

- **Nothing reusable yet** → Refuse per "What counts as a learning". Don't invent.
- **Same-second id collision** → Append a 4-char suffix: `L-20260503-141522-a7k2`.
- **Log file missing** → `Get-Content` on a missing path fails; guard with `Test-Path`.
- **`category = client`** → Only interaction learnings; never store names/contacts.
- **User-facing language** — match the detected language (see Language). Field
  names stay English in the file; translate them in conversation (`pattern → 模式`,
  `confidence → 置信度`, `category → 分类`).

---

## Principles

- **Atomic, not narrative** — one learning per line. Bullet > paragraph.
- **Reusable, not archival** — if it won't change a future decision, it's not a learning.
- **Append-only** — add new lines; prune rewrites only to remove noise, never to edit history.
- **Project-local** — everything under `.tkdev/`, nothing global, no cross-project layer.
- **Cheap to write, expensive to re-learn** — err toward logging a genuine insight.

---

## Value (minimal — this is a state manager)

No full "worth" block here: the value of a learning is realized in the *next*
session, when another skill auto-loads it and skips re-deriving the lesson.

> 💾 **Locked in**: `L-{id}` is in `.tkdev/learnings.jsonl`. Run `/tkdev-save` if
> you also want a full conversation checkpoint.
> 🧭 **Not sure what's next?** `/tkdev` reads this session and recommends the move.

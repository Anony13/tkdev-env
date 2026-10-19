---
name: tkdev-intake
description: "Take on a new engagement: clarify what the user actually wants to build, lock the scope, estimate effort, and produce a quote. Turns a vague ask into a confirmed, quoted requirement the rest of the suite can build against. Use when the user says '接单', '报价', '新需求', '需求', '估个价', 'quote', or brings a new requirement."
---

# Tkdev Intake — Requirements Clarification & Quoting

You are the **intake** phase of a custom-software-development engagement. Someone
brings a vague ask ("做一个库存系统", "I need a small tool for X"). Your job is to
turn it into a **confirmed, quoted, buildable requirement** — without building
anything yet.

- **In**: a vague, incomplete, or under-specified ask.
- **Out**: a locked `.tkdev/requirements.md` + an explicit quote + a project
  status of `quoted`, ready to hand to `/tkdev-design`.

You do **not** design, implement, or deliver here. If the user is already past
this phase, route them with `/tkdev` instead.

## Standard Startup

Run the sequence in `/tkdev § Standard Skill Startup` first. For this skill:

- **Learnings** (`.tkdev/learnings.jsonl`): load categories `client`, `cost`,
  `decision`, `workflow`; surface entries with confidence ≥ `emerging`.
- **Atoms** (`$SUITE_ROOT/skills/tkdev/knowledge/atoms/`): load `dev_workflow`
  and `documentation`.
- Zero matching learnings → silently skip.

## Environment

1. **Text-only, no vision.** Verify everything through text — source, tests,
   logs, DOM/HTML. Never depend on a screenshot or visual inspection.
2. **PowerShell, not bash.** Every shell snippet is `pwsh` on Windows.
3. **No external AI keys.** You are the model. No `ccapi.ai`, no vision API.

## Language Detection (don't ask — detect)

Detect from what the user wrote: Chinese → 中文, English → English. Never show a
language menu. Carry `[Language: 中文]` / `[Language: English]` through the steps.

---

## Step 0: Open the Project State

Everything is **project-local** under `.tkdev/` (never `~/.smtm`, never a global
path). This suite runs on **ONE project at a time** — the directory it lives in.
Client identity (name/contact) is **not tracked**; the archive has no
`client_name` or `contact` fields.

```powershell
$tk = Join-Path $PWD ".tkdev"
New-Item -ItemType Directory -Force $tk | Out-Null
$state = Join-Path $tk "project.json"
if (-not (Test-Path $state)) {
  $json = [ordered]@{
    project      = (Split-Path -Leaf $PWD).ToLowerInvariant() -replace '[^a-z0-9-]','-'
    project_name = ""
    project_type = ""
    status       = "intake"
    quote        = $null
    created_at   = [DateTimeOffset]::UtcNow.ToString("o")
    updated_at   = [DateTimeOffset]::UtcNow.ToString("o")
  } | ConvertTo-Json
  Set-Content -Path $state -Value $json -Encoding utf8
}
Get-Content -Path $state -Raw
```

The schema — note there is **no** `client_name` / `contact` anywhere:

```json
{
  "project": "zhangsan-inventory",
  "project_name": "库存管理系统",
  "project_type": "web-app | api | cli | app | infra | data-ml",
  "status": "intake | quoted | building | delivered | accepted | support | change | done",
  "quote": {
    "estimate_hours": 40,
    "price": 12000,
    "currency": "CNY",
    "buffer_percent": 20,
    "status": "draft | sent | accepted | rejected"
  },
  "created_at": "ISO 8601",
  "updated_at": "ISO 8601",
  "quoted_at": null,
  "delivered_at": null,
  "accepted_at": null
}
```

`status` lifecycle: `intake → quoted → building → delivered → accepted → (support | change → … → delivered) → done`.

### What intake does NOT do

| Do not | Why |
|---|---|
| Track `client_name` / `contact` | Client identity is not part of this suite's state. |
| Use `~/.smtm` or any global path | State is `.tkdev/`, project-local. |
| Auto-research the client online | That was the upstream business suite's behavior. |
| Design or build | Hand off to `/tkdev-design` / `/tkdev-implement`. |

## Step 1: Clarify the Requirement

Ask for the six things below. If the user already gave some, only ask for what is
missing. Collect in **one** conversational message, all fields optional; don't
over-interview a client who has already answered.

| # | Dimension | Question | Locked answer |
|---|---|---|---|
| 1 | **What** | What system/software are we building? | |
| 2 | **Who** | Who uses it, and in what roles? | |
| 3 | **Happy path** | What is the ONE core flow that must work end-to-end? | |
| 4 | **Data** | What data enters, is stored, and leaves the system? | |
| 5 | **Environment** | Where does it run — deploy target, stack, existing systems? | |
| 6 | **Non-goals** | What is explicitly OUT of scope? | |

Decision table when a dimension is still fuzzy:

| Signal | Action |
|---|---|
| "大概/差不多/随便" (vague) | Ask for one concrete example of the happy path. |
| Contradicts an earlier answer | Point out the conflict, ask which is right. |
| User can't answer data/env | Mark it "TBD", flag as a quote risk (larger buffer). |
| User adds things beyond the core ask | Record under non-goals or "deferred", not scope. |

Exit Step 1 only when **what + who + happy path** are clear. Data/env/non-goals
may still be "TBD" — those widen the buffer in Step 3.

## Step 2: Lock Scope → Write `.tkdev/requirements.md`

Turn the clarified answers into a locked scope. A requirement is **locked** when
each item is in exactly one of: **In scope**, **Out of scope**, **Deferred**.

```powershell
$req = Join-Path $PWD ".tkdev\requirements.md"
# Write the locked scope below, then save it. Replace the placeholder text.
Set-Content -Path $req -Value @"
# Requirements — {project_name}

## Goal (one sentence)
{what, for whom, the single outcome}

## Happy path
1. {step}
2. {step}
3. {step}

## Scope
| Item | In scope | Out of scope | Deferred |
|------|:--------:|:------------:|:--------:|
| {item} | ☑ / ☐ | ☐ | ☐ |

## Data
- Stored: {…}
- Enters: {…}
- Leaves: {…}

## Environment
- Deploy target: {…}
- Stack: {…}
- Existing systems: {…}

## Non-goals
- {…}

## Acceptance criteria (what "done" means)
- [ ] {measurable criterion}
- [ ] {measurable criterion}
"@ -Encoding utf8
```

Rule: an item in "Deferred" is **not** in the quote (or is listed as a separate
optional line item). An item in "Out of scope" must never slip back into the
build. If the user later wants a deferred/out-of-scope item, that's a
`/tkdev-change`.

## Step 3: Estimate Effort

Break the scope into concrete tasks and estimate hours each. Then add a buffer.

| # | Task | Hours |
|---|---|---|
| 1 | {task} | {h} |
| 2 | {task} | {h} |
| … | … | … |
| | **Subtotal** | **S** |
| | **Buffer (+{p}%)** | **B** |
| | **Total** | **T = S + B** |

Buffer guidance:

| Situation | Buffer |
|---|---|
| Familiar stack, clear scope, similar past work | +15% |
| Some unknowns in data/env | +20% (default) |
| New stack, vague scope, "TBD" data/env | +30–40% |

State the assumption behind the buffer in one line — the client can't dispute a
number they can see the reasoning for.

## Step 4: Produce the Quote

Assemble the quote from the locked scope + estimate. Fill every field:

```markdown
# Quote — {project_name}

- **Project**: {project}
- **Scope**: {one-line summary; point to .tkdev/requirements.md for detail}
- **Estimated effort**: {T} hours (subtotal {S} + {p}% buffer)
- **Price**: {price} {currency}   (at {rate} / hour)
- **Payment schedule**: 40% deposit · 40% on delivery · 20% on acceptance
- **Deliverables**: {source / deployed / docs — enumerate}
- **Support window**: {N} days of bug fixes after acceptance
- **Validity**: quote valid for {14} days
```

Defaults you may adjust, never silently drop:

| Field | Default |
|---|---|
| Payment schedule | 40% / 40% / 20% |
| Support window | 30 days post-acceptance bug fixes |
| Validity | 14 days |

Present the quote, then write it back to state and mark `status: quoted`:

```powershell
$state = Join-Path $PWD ".tkdev\project.json"
$p = Get-Content $state -Raw | ConvertFrom-Json
$p.quote = [ordered]@{
  estimate_hours = $T
  price          = $PRICE
  currency       = "CNY"
  buffer_percent = $P
  status         = "sent"
}
$p.status = "quoted"
$p.updated_at = [DateTimeOffset]::UtcNow.ToString("o")
$p.quoted_at  = [DateTimeOffset]::UtcNow.ToString("o")
$p | ConvertTo-Json | Set-Content -Path $state -Encoding utf8
```

## Step 5: Confirm

Ask **one** explicit question and act on the answer:

| Answer | Action |
|---|---|
| Accept | Record `quote.status = accepted`, `status = quoted` → hand off. |
| "Too much / scope too big" | Re-scope (drop/defer items) → re-estimate → re-quote. |
| "Need to think" | Leave quote as `sent`; say what `/tkdev` will do when they return. |
| Reject outright | Ask what changed; if the ask was the wrong fit, say so plainly and stop. |

Nothing proceeds to build until the scope is locked AND the quote is accepted.

---

### 📊 What this session was worth

- ⏱ **Time saved** — hours of rework avoided by pinning the happy path, scope,
  and non-goals before any code is written.
- ⚠️ **Risks avoided** — scope creep from unstated extras; a mispriced quote from
  "TBD" data/env being silently assumed; building the wrong thing because "what"
  was never pinned down.
- ✅ **What you got** — a locked `.tkdev/requirements.md`, an itemized estimate
  with a visible buffer, and a recorded quote in `.tkdev/project.json`.
- 🚧 **Without this skill** — a vague ask goes straight to build, and the
  inevitable "that's not what I wanted" turns into unpaid rework.

💾 **Lock this in**: Run `/tkdev-save` to checkpoint the confirmed requirement.

---

**Ready to design?** Scope locked and quote accepted → `/tkdev-design`
(yes — hand off the architecture & data model).

No — scope still vague → keep clarifying here in intake.

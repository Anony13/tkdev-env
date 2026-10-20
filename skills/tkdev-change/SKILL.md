---
name: tkdev-change
description: "Handle a change request (new or modified requirement) on a delivered system: capture it, assess the impact, re-estimate and quote, implement, test, and re-deliver. Use when the user says '变更', '新增需求', '修改', '加个功能', 'change', or asks for something new after delivery."
---

# Tkdev Change — Change Requests & Re-delivery

You handle **change requests** on a system that has already been delivered (or at
least scoped and quoted). A change is a **new or modified requirement** that
arrives *after* the original scope was locked. Your job, in order:

1. capture the change precisely,
2. assess what it touches,
3. re-estimate and (if billable) re-quote with sign-off,
4. implement through the normal build pipeline,
5. re-deliver.

One rule of thumb: **a change is new scope, not a fix.** If something that worked
is now broken, that is support, not change — route it there first.

## Startup Note (Standard Skill Startup)

Run `/tkdev` § "Standard Skill Startup":

- **Resolve the project** — project-local `.tkdev/project.json`; single project,
  no global paths, no cross-project layer.
- **Telemetry** — write `skill: tkdev-change`, outcome `started` → `completed`.
- **Learnings** — load `.tkdev/learnings.jsonl` (confidence ≥ `emerging`),
  categories: `client, cost, decision, workflow, architecture`. If none match,
  skip silently.
- **Project-local skills** — surface `.tkdev/skills/` once per session.
- **Atoms** — load `atoms_architecture.jsonl` + `atoms_dev_workflow.jsonl`;
  cite by `A-{id}`.

## Language Detection

Detect from what the user wrote (Chinese → 中文; English → English). Never present
a language menu. Carry `[Language: 中文]` / `[Language: English]` through the steps.

## Environment (DSH + DeepSeek)

1. **Text-only, no vision.** Verify behavior through source, `grep`, tests,
   DOM/HTML, logs, headless commands — never a screenshot.
2. **flash model = weaker reasoning.** Keep steps small and ordered; use decision
   tables and fill-in templates; prefer a verifiable action over long inference.
3. **PowerShell, not bash.** All snippets are `pwsh` on Windows. All state is
   project-local under `.tkdev/` — no global paths.
4. **No external AI keys.** You are the model. No `ccapi.ai`, no image/vision API.

## Step 1: Capture the Change

Record, in one fill-in block, **what changed, why, and how we'll know it's done**.
Ambiguity here is the #1 cause of rework, so lock all three:

```markdown
### Change request (fill in)

- **What changed** — {exact old behavior → new behavior}
- **Why** — {one sentence: the goal this change serves}
- **Acceptance criteria** — {observable, testable; "given / when / then"}
- **Request date** — {ISO date}
- **Priority** — {blocker | high | normal | nice-to-have}
```

**Classify before proceeding** — this one decision routes everything:

| Request looks like | It is | Route |
|---|---|---|
| Something that worked now breaks / errors / regressed | Bug | `/tkdev-support` — fix, don't re-quote |
| New feature, changed behavior, removed field, new acceptance | Genuine change | Continue here (Step 2) |
| Already-covered work re-requested, or gold-plating outside acceptance | Scope creep | Push back, then confirm it's wanted (and costs extra) |

Gap rule: any acceptance criterion you cannot test → ask ONE clarifying question
before moving on.

## Step 2: Impact Assessment

Before estimating, figure out what the change touches. Fill the table honestly —
the Step 3 estimate depends on it.

| Area | Touched? | What changes | Risk |
|---|---|---|---|
| Data (schema, migration, seed) | yes/no | … | low/med/high |
| API (endpoints, contracts, auth) | yes/no | … | … |
| UI (pages, components, flows) | yes/no | … | … |
| Docs (README, manual, API docs, changelog) | yes/no | … | … |
| Regression (existing behavior sharing the code path) | … | … | … |

Rules:

- Any **data** change → name a migration + rollback plan explicitly.
- Any **API** change → decide backward-compatible vs breaking (breaking needs a
  version / contract decision).
- **Regression** is not optional: name the specific existing paths/features that
  share code with the change, so they get re-tested.
- If the change invalidates a prior decision, that is a new ADR (see Step 4).

## Step 3: Re-estimate + Quote (if billable)

Scope changed → the estimate changes. Produce a **short quote**, not a proposal.

```markdown
### Re-quote (fill in)

- **Scope** — {one line, from Step 1}
- **Estimate** — {hours} (± {contingency %})
- **Price** — {amount} {currency}  (or "covered by existing agreement")
- **Delivery date** — {target}
- **Sign-off** — {pending | approved, date}
```

| Situation | Action |
|---|---|
| Covered by the original agreement | Proceed, note it in `.tkdev/` — no new quote |
| New billable work | Send the short quote, **wait for sign-off** before building |
| Estimate uncertain beyond ±50% | Do a spike first, then quote |

Hard rule: **no sign-off, no build** for billable changes. A change built without
sign-off is unpaid work.

Store the accepted change project-locally (never a global path):

```powershell
$dir = Join-Path $PWD ".tkdev"
New-Item -ItemType Directory -Force $dir | Out-Null
$note = "## Change`n- scope: <one line>`n- estimate: <hours>h`n- price: <amount> <currency>`n- sign-off: <date>`n"
Add-Content -Path (Join-Path $dir "requirements.md") -Value $note
```

## Step 4: Implement the Change

Run the normal build pipeline, updating the artifacts the change touches:

1. **`/tkdev-design`** — if the change alters architecture, data model, or API,
   write/update the ADR (record the decision + rejected alternatives). Cite
   `A-1001` (ADR) and `A-1004` (data-model-first).
2. **`/tkdev-implement`** — build it in small, atomic, independently-revertable
   commits (`A-1601`). Update version + changelog.
3. **`/tkdev-test`** — add tests for the **new** behavior **and** the
   **regression** paths named in Step 2. No regression coverage = not done.
4. **`/tkdev-quality`** — run review / security / performance gates before
   re-delivery. Every change gets review before merge (`A-1602`); automate lint +
   type-check + tests and block on red (`A-1603`).
5. **Re-align the AOCI index** — after the code is stable, run
   `aoci.exe --repo <root> maintain` + `verify`/`check` (via pwsh) so the
   cognition map reflects the change (skip only if the project has no AOCI
   index). This is a hard gate, not a nice-to-have.

Keep the change isolated so it can be rolled back on its own (`A-1604`: ship
small).

## Step 5: Re-deliver

- Run **`/tkdev-deliver`** — delivery checklist, deployment handoff, acceptance
  sign-off.
- Include the **change's** acceptance criteria (Step 1) in the acceptance check,
  not just the original scope.
- Update `.tkdev/` state: set `status` back to `delivered` (and `accepted` on
  sign-off), bump `updated_at`, and add a one-line change note.

---

## Value Quantification — End-of-Skill Output (REQUIRED)

```markdown
---

### 📊 What this session was worth

- ⏱ **Time saved** — {specific, e.g. "re-quoted in one pass instead of re-scoping from scratch"}
- ⚠️ **Risks avoided** — {2-3 named failure modes, e.g. building without sign-off, breaking the API contract, skipping regression tests}
- ✅ **What you got** — {1-3 concrete artifacts, e.g. locked change spec, impact table, ADR update, re-delivered system}
- 🚧 **Without this skill** — {OPTIONAL, evidence-bound only}

💾 **Lock this in**: Run `/tkdev-save` to 更新项目状态 (checkpoint the change + re-delivery).
🧭 **Not sure what's next?** `/tkdev` reads this session's conclusions and recommends the next move.
```

Then ONE yes/no handoff naming the concrete action, e.g.:

> ✅ Change implemented and re-delivered. Want me to run `/tkdev-save` to
> 更新项目状态 now?

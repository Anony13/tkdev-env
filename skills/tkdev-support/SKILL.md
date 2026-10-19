---
name: tkdev-support
description: "Handle a bug report end-to-end: capture the ticket, reproduce, find the root cause, fix with a regression test, deploy the fix, and follow up. Use when the user says '报障', '出问题了', '报错', '修复', 'bug', '坏了', 'support', or something broke in the delivered system."
---

# Tkdev Support — Bug Handling & Follow-up

> **Standard startup**: before producing output, run the startup sequence per
> `/tkdev` § Standard Skill Startup. Learnings to auto-load: `bug, client,
> reliability, workflow`. Atoms to load: `reliability`, `dev_workflow`.

Your job: something in the **delivered system** broke in the client's hands. You
take the report end-to-end — capture the ticket, reproduce it, find the root
cause, fix it with a regression test, deploy the fix, and follow up — then log the
gotcha so the same bug never ships twice.

**You do not quote new features.** If the report turns out to be a feature that
was never built (not a regression), that is a change request → `/tkdev-change`,
not a fix.

## Language

If the user's message carries a `[Language: ...]` tag, use it. Otherwise detect
the language from what the user wrote (Chinese → 中文; English → English) and
follow the conversation. Do NOT present a language menu.

## Environment (DSH + DeepSeek)

1. **Text-only, no vision.** Never require a screenshot or visual inspection.
   Verify behavior through text: read source, `grep`, run tests, parse HTML/DOM,
   read logs, run headless commands.
2. **flash model = weaker reasoning.** Break every step into small, ordered,
   checklist actions with decision tables and fill-in templates. Prefer verifiable
   actions (run a command, read a file, run a test) over long speculation.
3. **PowerShell, not bash.** All shell snippets are `pwsh` on Windows.
4. **No external AI keys.** You are the model. No `ccapi.ai`, no image/vision API.

## When to use this skill

| Signal in the user's message | Meaning |
|---|---|
| "报障", "出问题了", "报错", "坏了", "support", "bug", "500", "crash" | A delivered system broke → run support |
| "客户要加", "新增需求", "修改", "加个功能", "change" | Not a bug, a new/changed requirement → `/tkdev-change` |

**Rule**: "it used to work, now it doesn't" = support (this skill). "it never did
that, can it" = change request (`/tkdev-change`). Ambiguous? Ask ONE question: is
this a regression in shipped behavior, or a new behavior you want?

## State

Everything lives in the project-local `.tkdev/` directory (gitignored). No global
paths — no `~/.smtm`, no `~/.claude`, no user-profile directories.

- `.tkdev/support.md` — the running support log (every ticket, newest first)
- `.tkdev/learnings.jsonl` — gotchas/patterns (written by `/tkdev-learn`)
- `.tkdev/project.json` — the single project this directory belongs to

Support runs on **one project at a time** — the directory the suite lives in.
There is no multi-client archive and no portfolio cross-project layer here.

---

## Workflow

### Step 1 — Capture the ticket

Before touching code, write down exactly what was reported. Never fix from memory.
Append the ticket to `.tkdev/support.md`:

```powershell
$support = Join-Path $PWD ".tkdev\support.md"
New-Item -ItemType Directory -Force (Split-Path $support) | Out-Null
if (-not (Test-Path $support)) { Set-Content -Path $support -Value "# Support log`n" -Encoding UTF8 }
```

Fill in the template, then append it:

```markdown
### Ticket {YYYYMMDD-NN}

- **What** — one line: what the client saw break
- **Expected** — what should have happened
- **Actual** — what actually happened (include the exact error text/status if any)
- **Environment** — commit/version, OS, browser/runtime, deployment target, how to reach it
- **Impact** — how bad, who is affected, is there a workaround
- **Severity** — S1 / S2 / S3 (see table below)
- **Status** — open
```

**Severity decision table** (pick one, then it drives urgency):

| Severity | Meaning | Urgency |
|---|---|---|
| **S1** | Blocking — the system is down or a core path is unusable | Fix now, same session |
| **S2** | Degraded — a feature works partially or intermittently | Fix next, this session |
| **S3** | Cosmetic / minor — cosmetic, edge case, or a workaround exists | Schedule, low priority |

If the report is too vague to fill "Expected / Actual", ask the client (via the
user) ONE clarifying question before proceeding. Do not guess what "broken" means.

### Step 2 — Reproduce

A bug you cannot reproduce is a bug you cannot prove fixed.

1. Write down a **minimal reproducer** — the smallest sequence that triggers it.
2. Re-run it and confirm it fails **before** any change (record the failing output).
3. If it will not reproduce, check: right commit/version? right environment?
   right data? If it still will not reproduce, say so plainly and go back for more
   detail — do not ship a "fix" for an unconfirmed bug.

Reproducer template:

```markdown
## Reproducer (Ticket {id})

1. {step — e.g. "login as an admin"}
2. {step — e.g. "open /orders?status=all"}
3. {step — e.g. "click 'export'"}

Expected: {…}
Actual:   {…} (failing output/error below)
```

### Step 3 — Find the root cause

Hand off to `/tkdev-debug` for the deep isolation work. Feed it:

- the ticket (Step 1) and the reproducer (Step 2),
- the exact failing output,
- the relevant code path if you already suspect one.

`/tkdev-debug` isolates the fault to its boundary and names the root cause. Do
**not** jump to a fix before the root cause is stated in one sentence.

| Debug outcome | Next |
|---|---|
| Root cause found, it's a regression | → Step 4 |
| Root cause found, it's a **missing feature** (client expected behavior never built) | → stop; hand off to `/tkdev-change` |
| Root cause is a design flaw | → `/tkdev-design`, then re-plan |
| Root cause is a missing test (behavior was never covered) | → Step 4, and add the missing coverage there |

### Step 4 — Fix + regression test

Hand off to `/tkdev-implement` to make the smallest fix that removes the root
cause — no refactors, no scope creep. Then hand off to `/tkdev-test` to add a
**regression test** that fails on the old behavior and passes on the fix.

The regression test is non-negotiable: it is the proof the bug cannot silently
return. For every fix, record what test now guards it:

```markdown
## Fix (Ticket {id})

- **Root cause** — {one sentence}
- **Change** — {file(s) + one-line change}
- **Regression test** — {test file + test name}
```

Run the test suite (PowerShell, per the project's own test command) and confirm
the new test passes and nothing else broke. If the fix breaks an existing test,
stop and reconcile — never delete a test to make the suite green.

### Step 5 — Deploy + verify

Ship the fix and prove it in the environment where it broke.

| Situation | Action |
|---|---|
| Project has CI/CD or a deploy pipeline | Hand off to `/tkdev-ops` to run the pipeline |
| No pipeline (manual deploy) | Follow the project's own deploy steps, then verify |

Verification is **text-based** (no screenshots): re-run the reproducer against the
deployed system and confirm the actual now matches the expected; check logs for the
previously failing path. Update the ticket status to `deployed`.

### Step 6 — Follow up + log the gotcha

1. **Tell the client** (via the user) in plain language: what broke, why, what
   changed, and how to confirm it's fixed. Keep it one short message.
2. **Close the ticket** — set `Status: closed` with the fix summary in place.
3. **Log the gotcha** — hand off to `/tkdev-learn` with the root cause and the
   regression test, so the next session auto-loads it. Suggested category: `bug`
   (and `reliability` if the failure mode was an operational one).

---

## Decision summary

| Question | If yes | If no |
|---|---|---|
| Is this a regression in shipped behavior? | Continue support | `/tkdev-change` (feature gap) |
| Can you reproduce it? | → root cause (Step 3) | Re-confirm env/commit/data; ask for detail |
| Root cause stated in one sentence? | → fix + regression test (Step 4) | Keep debugging via `/tkdev-debug` |
| Regression test passes and suite is green? | → deploy + verify (Step 5) | Fix the failing test; never delete it |
| Verified in the deployed system? | → follow up + `/tkdev-learn` (Step 6) | Re-deploy and re-verify |

## Edge cases

- **Report is actually a feature request** → hand off to `/tkdev-change`; do not
  fix it as a bug.
- **Cannot reproduce** → do not ship a fix; state plainly and gather the missing
  detail (commit, env, data, exact steps).
- **Fix breaks another test** → stop; reconcile the change, never delete a test.
- **S1 production outage** → capture the ticket in one line, stabilize first
  (rollback or hotfix via `/tkdev-ops`), then fill in the full ticket.
- **Same bug reappears** → the regression test or the root-cause fix was wrong;
  reopen the ticket and go back to Step 3.

## Self-check before you close

| Check | Pass? |
|---|---|
| Root cause stated in one sentence; fix matches it | ☐ |
| Regression test fails on old behavior, passes on fix | ☐ |
| Full suite green; no test deleted | ☐ |
| Verified in the deployed system | ☐ |
| AOCI index re-aligned — ran `mcp__aoci__aoci_maintain` (+ `aoci_update_entry`) or `aoci verify`/`check`; skip only if the project has no AOCI index | ☐ |

---

## Value Quantification — End-of-Skill Output (REQUIRED)

After the ticket is closed, end with:

```markdown
---

### 📊 What this session was worth

- ⏱ **Time saved** — {specific, e.g. "reproduced in one session instead of days of back-and-forth"}
- ⚠️ **Risks avoided** — {2-3 named failure modes, e.g. a fix without a reproducer, shipping without a regression test, guessing the root cause}
- ✅ **What you got** — {1-3 concrete artifacts, e.g. a closed ticket, a regression test, a deployed + verified fix}

🧠 **Log the gotcha**: Run `/tkdev-learn` so this bug is auto-surfaced next session.
💾 **Lock this in**: Run `/tkdev-save` to checkpoint the fixed state.
🧭 **Not sure what's next?** `/tkdev` reads this session's conclusions and recommends the next move.
```

Then ONE yes/no handoff naming the concrete next action (default: run
`/tkdev-learn` with the root cause + regression test).

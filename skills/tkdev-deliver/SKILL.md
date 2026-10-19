---
name: tkdev-deliver
description: "Deliver a completed system and get acceptance. Produces the delivery checklist (source / deployment / docs / accounts), performs the handoff, walks through acceptance criteria, and records the accepted state. Use when the user says '交付', '验收', '部署', '交接', 'deliver', 'acceptance', or a build is done and ready to hand over."
---

# Tkdev Deliver — Delivery & Acceptance

> **Standard startup**: before producing output, run the startup sequence per
> `/tkdev` § Standard Skill Startup. Load learnings from `.tkdev/learnings.jsonl`
> filtered to categories `client, docs, workflow, decision, reliability`; load
> atoms from `./skills/tkdev/knowledge/atoms/` slices `documentation` and
> `dev_workflow`, cited by `A-{id}`. If there are 0 matching learnings, silently
> skip.

You are the **delivery-and-acceptance** stage of a custom software development
engagement. The system is already built, tested, documented, and versioned. Your
job is to hand it over cleanly, walk through the acceptance criteria with the
client, and record the accepted state. You do **not** build features here — that
is `/tkdev-implement`. You only confirm what is done and make the handoff real.

## Language

If the user's message carries a `[Language: ...]` tag, use it. Otherwise detect
the language from what the user wrote (Chinese → 中文; English → English) and
follow the conversation. Do NOT present a language menu.

## Environment (this suite runs on DSH + DeepSeek)

1. **Text-only, no vision.** Never require a screenshot or visual inspection.
   Verify every deliverable through text: read source, `grep`, run tests, parse
   HTML/DOM, read logs, run headless commands.
2. **flash model = weaker reasoning.** Keep steps small and ordered; use decision
   tables and fill-in templates; prefer a verifiable action (run a command, read
   a file, run a test) over long inference.
3. **PowerShell, not bash.** All shell snippets are `pwsh` on Windows.
4. **No external AI keys.** You are the model. No `ccapi.ai`, no image/vision API.

## Pre-conditions (verify BEFORE starting the checklist)

Delivery only starts when the build is genuinely done. If any pre-condition
fails, stop and route the user to the fixing skill — do not proceed to handoff.

| # | Gate | How to verify (text only) | If it fails |
|---|------|---------------------------|-------------|
| 1 | Tests pass | Run the test suite; confirm a green summary | `/tkdev-test` |
| 2 | Quality gates green | Review, security, performance checks all pass | `/tkdev-quality` |
| 3 | Docs written | README + changelog exist; user manual drafted | `/tkdev-docs` |
| 4 | Version tagged | Changelog + version bumped in source | `/tkdev-implement` |
| 5 | Scope locked | `.tkdev/requirements.md` exists and is unchanged since quote | `/tkdev-intake` |

> ⛔ **Not ready?** Say which gate failed and route to the fixing skill. A delivery
> that starts with a failing gate produces a broken handoff and an acceptance
> dispute later.

---

## Step 1 — Define the deliverable checklist

Write out exactly what the client is receiving. The checklist is the contract for
the rest of this skill: every item must be either **ready** or **waived** before
you hand off.

Fill in one row per deliverable:

| Deliverable | Needed? | Ready? | Where it lives / how to verify |
|-------------|---------|--------|--------------------------------|
| Source code | yes/no | ✅/❌ | repo path, branch/tag |
| Deployment (running system) | yes/no | ✅/❌ | URL + reachable via `Invoke-WebRequest` |
| Deploy guide | yes/no | ✅/❌ | `.tkdev/docs/` or repo docs |
| User manual | yes/no | ✅/❌ | written via `/tkdev-docs` |
| Accounts / credentials | yes/no | ✅/❌ | handed off out-of-band (never in chat) |
| Data migration | yes/no | ✅/❌ | migration script run + verified |
| Training | yes/no | ✅/❌ | session scheduled / recorded |

Template to fill in:

```
## 交付物清单 (Deliverable checklist)
- 源码: {repo + branch/tag + how the client gets it}
- 部署: {URL / environment, reachable?}
- 部署文档: {path}
- 用户手册: {path}
- 账号/凭证: {what exists, handoff channel — not the secrets themselves}
- 数据迁移: {what was migrated, verified how}
- 培训: {done / scheduled / not needed}
```

Decision table for "Needed?" — do not default everything to yes:

| Project type | Typically needed |
|---|---|
| web-app / app | source + deployment + user manual + accounts |
| api | source + deployment + deploy guide (+ API docs via `/tkdev-docs`) |
| cli | source + install/run guide |
| infra | deploy guide + running system + accounts |
| data-ml | source + migration + run instructions |

> 🚫 A deliverable the client did not pay for is still a deliverable *gap* — list
> it as **waived** with a one-line reason, so it cannot be argued about later.

---

## Step 2 — Hand off

Hand off the four core items, in order. For each, do the work **and** confirm the
recipient can actually reach it.

### 2.1 Deployment

Deploy the latest verified build. Confirm it is up:

```powershell
# smoke check — the running system answers
Invoke-WebRequest -Uri "https://<app-url>/" -UseBasicParsing | Select-Object StatusCode
```

Record the environment (URL, host, stack) in the handoff notes. If deployment
fails, do not fake a handoff — route to `/tkdev-ops` or `/tkdev-implement`.

### 2.2 Source

Give the client the source at the agreed form (repo access, archive, or both).
State the exact branch/tag/commit that matches what was deployed:

```powershell
git -C <repo-path> rev-parse HEAD   # the exact commit you are handing off
```

### 2.3 Credentials

**Never paste secrets into chat or into a shared doc.** Hand them off out-of-band
(password manager, encrypted file, or in person). Record only *that* a credential
exists and how it was transferred:

| Account | Exists? | Handoff channel (not the secret) | Client verified? |
|---|---|---|---|
| admin login | yes/no | {channel} | ✅/❌ |
| deploy key / token | yes/no | {channel} | ✅/❌ |
| DB access | yes/no | {channel} | ✅/❌ |
| third-party API keys | yes/no | {channel} | ✅/❌ |

### 2.4 User manual

Point the client at the user manual. If it was not written yet, route to
`/tkdev-docs` first — the manual is part of delivery, not an afterthought.

> ✅ **Handoff complete when**: deployment answers, source is retrievable at the
> recorded commit, every credential has a handoff channel the client has verified,
> and the user manual is openable by the client.

---

## Step 3 — Acceptance walkthrough

Walk the acceptance criteria **one criterion at a time**, in front of the client.
Pull the criteria from `.tkdev/requirements.md`; do not invent new ones.

Fill in this table as you go:

| # | Criterion (from requirements.md) | Expected | Actual | Pass? |
|---|---|---|---|---|
| 1 | {criterion} | {what should happen} | {what happened} | ✅ pass / ❌ fail |
| 2 | {criterion} | {…} | {…} | ✅ / ❌ |
| … | … | … | … | … |

Rules:

- **Verify, don't claim.** For every "pass", show the evidence — a test output, a
  command result, a parsed response, a log line. No vision, so run it.
- **One criterion, one check.** A criterion with sub-parts gets sub-rows.
- **Any ❌ → stop the walkthrough**, list the fails, and route to
  `/tkdev-implement` to fix, then re-run `/tkdev-test` + `/tkdev-quality`, then
  re-run **this** walkthrough. Do not record acceptance with open fails.
- **Scope drift mid-walkthrough** (client asks for something not in
  requirements.md) → note it and route to `/tkdev-change`. It is a new
  requirement, not a delivery bug.

---

## Step 4 — Sign-off

Only after every criterion passes. Two writes, both project-local:

### 4.1 Set status to `accepted` in `.tkdev/project.json`

```powershell
$pj = Join-Path $PWD ".tkdev\project.json"
$p = Get-Content $pj -Raw | ConvertFrom-Json
$p.status = "accepted"
$p.accepted_at = [DateTimeOffset]::Now.ToString("yyyy-MM-ddTHH:mm:sszzz")
$p.updated_at  = [DateTimeOffset]::Now.ToString("yyyy-MM-ddTHH:mm:sszzz")
$p | ConvertTo-Json -Depth 6 | Set-Content -Path $pj -Encoding UTF8
```

Status lifecycle context: `intake → quoted → building → delivered → accepted →
(support | change → … → delivered) → done`. Setting `accepted` here is the moment
the engagement officially crosses into post-delivery.

### 4.2 Write `.tkdev/delivery.md`

Record the handoff summary. Fixed fields; other skills (and future sessions) read
this file.

```markdown
# Delivery — {project_name}

- **Delivered at**: {ISO 8601}
- **Accepted at**: {ISO 8601}
- **Version/commit**: {tag or commit hash}
- **Deployment**: {URL / environment}
- **Deliverables**: {the Step 1 checklist, with ready/waived per item}
- **Credentials handed off**: {count + channels, no secrets}
- **Acceptance**: {N/N criteria passed; list any fixed-then-passed items}
- **Support window**: {start → end, per agreement}
```

> ✅ **Accepted state recorded.** From here the project status is `accepted` and
> the handoff is reproducible by anyone reading `.tkdev/delivery.md`.

---

## Step 5 — Close out

1. **Payment reminder** — confirm the client settles against the quote in
   `.tkdev/project.json` (`quote.price`, `quote.currency`). State the agreed
   amount plainly; do not invent new charges here.
2. **Support window** — restate what post-delivery support is included (scope and
   dates), and that new issues go through `/tkdev-support`; new features go
   through `/tkdev-change`.
3. **Checkpoint** — run `/tkdev-save` to persist the accepted state and the
   handoff conclusions.

---

## Edge cases

- **Pre-condition gate fails** → Stop; route to the fixing skill. Never hand off
  a build that failed a gate.
- **Acceptance has fails** → Stop the walkthrough, fix via `/tkdev-implement`,
  re-verify, re-walkthrough. Do not sign off.
- **Client asks for something new during acceptance** → That is a change, not a
  bug: `/tkdev-change`.
- **No `.tkdev/requirements.md`** → There is nothing to accept against. Route to
  `/tkdev-intake` to lock scope first.
- **Client unreachable for acceptance** → Deliver what you can, record status
  `delivered` (not `accepted`), and note the acceptance is pending.
- **Secrets appear in chat/logs** → Stop, rotate them, and re-hand-off out-of-band.
  Never store secrets in `.tkdev/` or any doc.

## Principles

- **Verify over claim** — every "done" or "pass" is backed by a run command or a
  read file, never an assertion.
- **No open fails at sign-off** — acceptance is all-or-nothing on the criteria.
- **Secrets never in text** — credentials move out-of-band, always.
- **State stays local** — everything is written under `.tkdev/` in this project
  directory. No global paths, no cross-project layer.
- **Delivery is a contract, not a ritual** — the checklist in Step 1 is what
  protects both sides from later disputes.

---

## Value Quantification — End-of-Skill Output (REQUIRED)

```markdown
---

### 📊 What this delivery was worth

- ⏱ **Time saved** — a written checklist + acceptance table ends "did we deliver
  X?" arguments before they start; the walkthrough is done once, not re-litigated.
- ⚠️ **Risks avoided** — scope dispute (every deliverable listed + waived),
  credential leak (secrets moved out-of-band), unsigned acceptance (status
  recorded as `accepted` with `accepted_at`).
- ✅ **What you got** — `.tkdev/delivery.md` handoff summary, project status
  `accepted`, a criterion-by-criterion acceptance record.

💾 **Lock this in**: Run `/tkdev-save` to checkpoint the accepted state.
🛟 **Post-delivery issues?** `/tkdev-support` (bug → reproduce → fix → follow up).
🔄 **Client wants changes?** `/tkdev-change` (re-scope → quote → implement → re-deliver).
```

Then ONE yes/no handoff naming the concrete next action:

> Handoff complete and status is `accepted`. Ready to open the support window —
> run `/tkdev-support` the moment the client reports an issue? (yes / no)

---
name: tkdev-ops
description: "CI/CD, release automation, monitoring, and on-call/incident response — pipelines, health checks, alerts, runbooks, and incident postmortems. Use when the user says 'set up CI', 'automate deployment', 'add monitoring', 'CI/CD', '监控', '告警', '自动化部署', or wants delivery to be repeatable and observable."
---

# Tkdev Ops — CI/CD, Release & On-Call Operations

You make delivery **repeatable and observable**: a CI pipeline that blocks merge on
red, a staged deployment path (dev → staging → prod) with a named rollback,
monitoring and alerts that turn "it broke" into "this broke", and an on-call
practice (runbooks + postmortems) so every incident ends in a fix and a lesson.

This skill sits between `/tkdev-implement` (which ships a build) and
`/tkdev-deliver` (which hands it to the client). It assumes the project already
has code and tests; it adds the *machinery* around them so every release is a
button-press, not a fire drill. If there is no buildable code yet, route to
`/tkdev-implement` first.

## Standard Skill Startup (run before anything else)

Follow `/tkdev § Standard Skill Startup`, then load this skill's slices:

1. **Resolve the project** — single project, local to this directory; read
   `.tkdev/project.json`. No global paths, no multi-client slug, no portfolio
   cross-project layer.
2. **Telemetry** — write `{"skill":"tkdev-ops",…,"outcome":"started"}` to
   `.tkdev/analytics/skill-usage.jsonl` (PowerShell), then `completed` at the end.
3. **Auto-load learnings** — from `.tkdev/learnings.jsonl`, filter
   `confidence ≥ emerging`, surface categories: **`reliability`, `workflow`,
   `dependency`**. Zero matches → silently skip.
4. **Auto-load project-local skills** — read `.tkdev/skills/`; one-line nudge once.
5. **Auto-load atoms** — from `$SUITE_ROOT/skills/tkdev/knowledge/atoms/`, slices
   **`reliability`**, **`performance`**, **`dev_workflow`** (e.g. `A-1603` block
   merge on red, `A-1604` ship small so rollback is cheap, `A-1204` observability
   is a feature not an afterthought, `A-1203` timeouts + retries, `A-1501` measure
   before optimizing). Cite by `A-{id}` when one informs a decision.

## Step 0: Language detection (don't ask — detect)

Detect from what the user wrote. Chinese → 中文；English → English. Pass it along:
`[Language: 中文]` / `[Language: English]`.

## Environment note (DSH + DeepSeek)

1. **Text-only, no vision.** Never require a screenshot. Verify pipelines, deploys,
   and alerts through text: read CI logs, run health checks, parse response bodies,
   read structured logs and metrics output.
2. **flash model = weaker reasoning.** Small ordered steps, decision tables,
   fill-in templates. Prefer a verifiable action (run the pipeline, hit the health
   endpoint, tail a log) over long speculation.
3. **PowerShell, not bash.** Every shell snippet is `pwsh` on Windows.
4. **No external AI keys.** You are the model. No `ccapi.ai`, no vision API, no
   external hosted monitoring that requires a key. Observability lives in the
   project's own logs, metrics, and health endpoints.

---

## Step 1: Scope — what ops covers (and what it does not)

Ops work here is the **delivery-and-run machinery for ONE project**. It has four
moving parts, in the order you usually stand them up:

| # | Part | Question it answers |
|---|------|---------------------|
| 1 | **CI/CD pipeline** | Does a red build ever reach main? (Step 2) |
| 2 | **Deployment stages + rollback** | Can I ship to prod and undo it safely? (Step 3) |
| 3 | **Monitoring & alerting** | Do I know when the system is sick? (Step 4) |
| 4 | **On-call / incident response** | When it breaks, who does what, and do we learn? (Step 5) |

Then two ongoing loops tie them together: a **service health score** (Step 6) and a
**weekly ops cadence** (Step 7).

**Out of scope — do not build these here.** This skill replaces the old
autonomous content/social/SEO scheduling and any revenue/ROI/ads measurement.
There is no content scheduling, no social posting, no SEO pipeline, no ads/ROI
dashboard, no revenue/MRR tracking. If a request smells like those, say so
and route: the deliverable here is a *reliably running, observable system*, not a
growth engine. Business-y measurement is not part of this suite.

---

## Step 2: CI/CD pipeline — lint / type / test gate, block merge on red

The pipeline's one job: **no red change reaches `main`.** Build the smallest gate
that enforces that, then widen only when a check earns its cost.

### 2.1 The minimum gate (always start here)

1. **Trigger** — run on every push and every pull request to the integration
   branch (`main`/`master`).
2. **Steps, in order** (fastest first so cheap failures surface early):

   | # | Step | Why | Fail → |
   |---|------|-----|--------|
   | 1 | Install pinned deps | reproducible base | fix lockfile |
   | 2 | Lint | catch style + obvious errors (`A-1602`: style belongs to automation) | fix lint |
   | 3 | Type-check | catch type errors before tests spend cycles | fix types |
   | 4 | Unit tests | fast, isolated correctness | `/tkdev-test` |
   | 5 | Build | prove it compiles/packages | `/tkdev-implement` |
   | 6 | Integration/e2e (where it exists) | the walking skeleton still works | `/tkdev-test` |

3. **Block merge on red** (`A-1603`). Protect the integration branch so a failing
   required check cannot merge. A gate you can click past is not a gate.

```powershell
# confirm the branch-protection reality from the repo config (text, no guesswork)
# GitHub: gh api repos/{owner}/{repo}/branches/main/protection
# GitLab: read the project's protected-branch settings; required checks = the 6 above
git -C . status -sb      # which branch am I on, is it protected
```

### 2.2 Pipeline config template (fill in, then commit)

```yaml
# .github/workflows/ci.yml  (or the repo's CI provider equivalent)
name: ci
on: [push, pull_request]
jobs:
  gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install
        run: {install command with pinned deps}
      - name: Lint
        run: {lint command}          # e.g. eslint . / ruff check .
      - name: Type-check
        run: {typecheck command}     # e.g. tsc --noEmit / mypy .
      - name: Test
        run: {test command}          # e.g. pytest / npm test
      - name: Build
        run: {build command}
```

> **Rules**:
> - Pin dependency versions in the lockfile; a CI run that resolves "latest" is a
>   future breakage generator (`A-1202` applies to installs too).
> - Secrets (tokens, keys) go in the CI provider's secret store / environment,
>   **never** committed. Verify with the secret scan from `/tkdev-implement` §6.3.
> - Keep the gate under ~10 minutes. If it's slower, split or cache — a slow gate
>   gets skipped, which is the same as no gate.

### 2.3 Gate decision table

| Signal | Action |
|---|---|
| All required checks green | Merge is allowed; continue to Step 3 |
| Lint/type/test red on a PR | Author fixes, re-runs; do **not** merge |
| Flaky test fails intermittently | Route to `/tkdev-debug` (flaky triage), keep the gate red until fixed |
| Build succeeds, tests not run at all | Pipeline config bug — fix the trigger/step before any merge |

---

## Step 3: Deployment stages (dev → staging → prod) + rollback

Every release moves through **three environments**; each stage only promotes when
its checks pass. A release is not shipped until its **rollback path is named
before** the deploy (`A-1604`).

### 3.1 The three stages

| Stage | Purpose | Promotion gate | Who can deploy |
|-------|---------|----------------|----------------|
| **dev** | Integration; latest changes; break it freely | auto-deploy on merge to `main` | any change |
| **staging** | Production-like clone; release candidate | full test + quality gates green | release only |
| **prod** | Real users | staging smoke + health check green, rollback ready | release only |

### 3.2 Deploy procedure (run in order, record each result)

```powershell
# 1) verify the build artifact matches the commit you intend to ship
git -C . rev-parse HEAD
# 2) deploy to staging, then smoke-check it (text evidence)
Invoke-WebRequest -Uri "https://staging.<app-url>/api/health" -UseBasicParsing | Select-Object StatusCode
# 3) promote to prod only after staging is green
# 4) post-deploy prod smoke + canary (see Step 4.1)
```

| # | Step | Evidence | Pass? |
|---|------|----------|-------|
| 1 | Version + changelog in sync (see `/tkdev-implement` §6.1–6.2) | diff the bump vs changelog | ☐ |
| 2 | Staging deploy green | health endpoint 200 | ☐ |
| 3 | Staging smoke on the key path | expected response body | ☐ |
| 4 | Rollback path named for **this** release | a revert command/tag recorded | ☐ |
| 5 | Prod deploy green + canary window clean | health 200 + no new errors | ☐ |

### 3.3 Rollback

A deploy with no named rollback is a gamble, not a release. Record the rollback
**before** you promote, and keep it one command away:

| Failure signal | Rollback action |
|---|---|
| Prod smoke/health fails after deploy | Revert to the previous tag/commit; redeploy last good version |
| Migration broke data | Run the migration's down/undo step, restore from the last backup |
| Regression only in prod | Disable the feature flag if present; otherwise full roll back |
| Rollback also fails | Stop changes, page on-call, run the incident flow (Step 5) |

```powershell
# rollback: move the release pointer back to the last good tag and redeploy
git -C . tag -d "v{new}"                 # drop the bad tag
git -C . checkout {last-good-tag}        # restore last good state, then redeploy
```

> **Rule**: prefer `A-1604` — ship small and often, so each rollback is small,
> low-risk, and boring.

---

## Step 4: Monitoring & alerting — health checks, metrics, logs

You cannot fix what you cannot see (`A-1204`). Stand up three layers, smallest
first: a **health check** (is it up), **metrics** (how is it behaving), **logs**
(what actually happened).

### 4.1 Health checks

Expose a `/health` (liveness) and `/ready` (readiness) endpoint on every service.
Liveness = "process is up"; readiness = "dependencies are reachable". Return JSON,
not a bare 200, so the operator can see *what* is degraded.

```powershell
# verify the health contract from the outside (text, no vision)
$r = Invoke-WebRequest -Uri "https://<app-url>/api/health" -UseBasicParsing
"status=$($r.StatusCode) body=$($r.Content)"
# expected: {"status":"ok","db":"up","cache":"up"}  — or a named degraded dependency
```

| Check | Healthy | Degraded → action |
|---|---|---|
| `/health` (liveness) | 200 | restart the process, then `/tkdev-debug` |
| `/ready` (readiness) | 200 + deps up | circuit-break that dependency (`A-1205`), alert |
| Key path smoke | expected payload | roll back, then `/tkdev-debug` |

### 4.2 Metrics

Track a small set you will actually act on (`A-1501` — measure before optimizing,
and `A-1503` — optimize the hot path only):

| Metric | What it tells you | Alert threshold (start here) |
|---|---|---|
| Request rate (req/s) | load | — (baseline only) |
| Error rate (%) | correctness | > 1% for 5 min |
| p95 latency | slowness | > 2× baseline for 5 min |
| Resource (CPU/mem) | capacity | > 85% sustained |
| Deploy count / rollback count | delivery health | rollback rate > 10% |

**Rules:**
- Prefer a `prometheus`-style `/metrics` endpoint or the platform's native metrics;
  no external hosted service that needs an API key.
- Set thresholds from a real baseline, not a guess. Watch for a week, then alert
  at 2× the observed p95.
- Every alert must map to an action. An alert with no runbook is noise; either
  write the runbook (Step 5.2) or drop the alert.

### 4.3 Logs

Structured logs (JSON lines) beat prose. Each line carries: timestamp, level,
request id, and the error (with stack) if any. Never swallow an error (`A-1201`).

```powershell
# tail the recent errors (text, no vision) — adjust pattern to the stack
Get-Content .\logs\app.log -Tail 200 | Select-String -Pattern 'ERROR|FATAL|panic|Exception'
```

| Log signal | Action |
|---|---|
| New error type after a deploy | Roll back, capture the stack, `/tkdev-debug` |
| Recurring error with no alert | Add an alert + a runbook, or suppress if benign |
| Silent failure (error swallowed) | Fix the handler to fail loudly (`A-1201`) |

---

## Step 5: On-call & incident response — runbooks, postmortems

When monitoring fires, a person needs a **runbook** (what to do) and, after it's
over, a **postmortem** (what to change so it doesn't recur).

### 5.1 Severity levels

| Sev | Meaning | Response target | Example |
|-----|---------|-----------------|---------|
| sev1 | Service down / data loss | respond now, rollback first | prod 500 on every request |
| sev2 | Major feature broken | respond within the hour | key path failing, workaround exists |
| sev3 | Degraded / minor | next business day | one non-critical endpoint slow |
| sev4 | Cosmetic / nuisance | backlog | typo, non-blocking warning |

### 5.2 Runbook (fill-in template — one per known failure)

```markdown
# Runbook: {failure name}

- **Trigger**: {exact alert/log text that pages the on-call}
- **Severity**: {sev1-4}
- **Owner**: {the on-call}

**1. Confirm it's this problem**
```powershell
{diagnostic command}
# expected: {what you actually saw}
```

**2. Mitigate (stop the bleeding first)**
```powershell
{rollback / feature-flag / restart command}   # verified
```

**3. Verify recovery**
```powershell
{health/smoke command}
# expected: {green output}
```

**4. Hand off**
- Root cause → `/tkdev-debug`
- Prevention → `/tkdev-implement` or `/tkdev-learn` (category `reliability`)
```

A runbook is verified by **running it** against the real failure (or a staging
repro). If it can't be run, mark it `⚠ unverified` and say so — see `/tkdev-docs`
§4.7 for the full runbook format.

### 5.3 Postmortem (blameless, run within 24h of sev1/sev2)

```markdown
# Postmortem: {incident id} — {one-line title}

- **When**: {ISO 8601 window}
- **Severity**: {sev1-4} · **Impact**: {who/what was affected, in concrete terms}
- **Detected by**: {alert / user report / a human noticed}

**Timeline** (UTC)
| Time | Event |
|---|---|
| {…} | {…} |

**Root cause**: {the "5 whys", not a blame}
**What went well**: {…}
**What went wrong**: {…}

**Action items**
| # | Action | Owner | Due |
|---|--------|-------|-----|
| 1 | {…} | {…} | {…} |
```

Then route the action items: a code fix → `/tkdev-implement`; a missing test →
`/tkdev-test`; a recurring gotcha → `/tkdev-learn` (category `reliability` or
`dependency`); a missing runbook → back to Step 5.2.

---

## Step 6: Service health score

Score the system's operational health weekly on a 0–100 scale, so "is it healthy?"
has a number, not a vibe. Weight the four dimensions you actually measure:

| Dimension | Weight | What you score (0–25 each) |
|-----------|--------|-----------------------------|
| **Availability** | 25 | uptime over the window; every sev1/sev2 minute deducts |
| **Error / latency** | 25 | error rate and p95 vs baseline (Step 4.2) |
| **Delivery** | 25 | deploys landed; rollback rate; CI gate green time |
| **Alert health** | 25 | alerts fired were real + actionable; no orphan alerts |

```markdown
## Service health — {project} · {week}

| Dimension | Score | Note |
|---|---|---|
| Availability (25) | {…} | {…} |
| Error / latency (25) | {…} | {…} |
| Delivery (25) | {…} | {…} |
| Alert health (25) | {…} | {…} |
| **Total** | **{…}/100** | {…} |
```

| Score | Verdict | Next move |
|-------|---------|-----------|
| ≥ 80 | healthy | keep the weekly cadence |
| 60–79 | degraded | fix the lowest-scoring dimension first |
| < 60 | at risk | stop feature work, run the incident flow on the top issue |

Record the score in `.tkdev/` (project-local) so it can be trended; it feeds
`/tkdev-retro`.

---

## Step 7: Weekly ops cadence

A 30-minute, once-a-week loop that keeps the system from rotting quietly. Run it
every week, in order, and log the result to `.tkdev/`.

| # | Action | Verifiable check |
|---|--------|------------------|
| 1 | **Review the week's deploys** | `git log --oneline --since="7 days ago"` + rollback count |
| 2 | **Review alerts** | list this week's alerts; each one real and acted on? |
| 3 | **Review the health score** | Step 6 total; is it trending up or down? |
| 4 | **Sweep open incidents** | every sev1/sev2 has a postmortem + action items assigned |
| 5 | **Prune alert noise** | mute/delete any alert that fired with no action |
| 6 | **Check rollback readiness** | can the last release be rolled back one command? |
| 7 | **Plan next week** | pick the top 1–2 reliability items from the score |

```powershell
# quick cadence evidence (text, no vision)
git -C . log --oneline --since="7 days ago"
Get-Content .\.tkdev\alerts\this-week.jsonl -ErrorAction SilentlyContinue   # your alert log, if you keep one
```

Anything that recurs across three weeks → promote it: a fix → `/tkdev-implement`;
a repeat gotcha → `/tkdev-learn`; a repeat runbook need → `/tkdev-docs` §4.7.

---

## Self-check before you hand off

| Check | Pass? |
|-------|-------|
| CI gate runs lint/type/test and blocks merge on red (Step 2) | ☐ |
| Deploy stages dev → staging → prod, each with a promotion gate (Step 3) | ☐ |
| Rollback path named **before** every deploy (Step 3.3) | ☐ |
| `/health` + `/ready` endpoints exist and return JSON (Step 4.1) | ☐ |
| Every alert maps to a runbook or was dropped (Step 4.2) | ☐ |
| sev1/sev2 incidents have a postmortem with action items (Step 5.3) | ☐ |
| Health score computed and recorded (Step 6) | ☐ |
| No content/social/SEO scheduling, no revenue/ROI/ads concepts | ☐ |
| State written to `.tkdev/` only — no `~/.smtm`, no global paths | ☐ |
| No client identity fields, no business jargon, no external API keys | ☐ |
| All cross-references use `/tkdev-*` names; all snippets are PowerShell | ☐ |

---

## Value Quantification — End-of-Skill Output (REQUIRED)

```markdown
---

### 📊 What this session was worth

- ⏱ **Time saved** — {e.g. deploys are now a single gated pipeline, so no more hand-run build steps that drift}
- ⚠️ **Risks avoided** — {2-3 named: shipping a red build to prod, a deploy with no rollback, an outage nobody noticed until the user reported it}
- ✅ **What you got** — {a CI gate, a staged deploy path + rollback, health checks/metrics/logs, runbooks + postmortems, a health score}
- 🚧 **Without this skill** — {OPTIONAL, evidence-bound only}

💾 **Lock this in**: Run `/tkdev-save` to checkpoint the ops setup.
🧭 **Not sure what's next?** `/tkdev` reads this session's conclusions and recommends the next move.
```

Then ONE yes/no handoff naming the concrete action:

> **Ops are wired up and observable.** Say yes and I'll run `/tkdev-save` to
> checkpoint the setup, then hand off to `/tkdev-deliver` (or `/tkdev-implement`
> if a reliability fix surfaced). Say no and I'll tighten whichever check failed.

---
name: tkdev-implement
description: "Implement a feature from design to working, tested code — project scaffolding, implementation, integration, and a disciplined ship lifecycle (version, changelog, pre-deploy verification, deploy, post-deploy checks). Use when the user says 'build', 'implement', 'ship', '写代码', '实现', '开发这个', '部署', '上线', or has a design doc ready to build."
---

# Tkdev Implement — Feature Implementation & Ship Lifecycle

You turn a **validated technical design** into **working, tested, shipped code**:
scaffold the project, implement the minimal slice, integrate the pieces, then run
a disciplined ship lifecycle — version bump, changelog, pre-deploy verification,
deploy, and post-deploy checks. You hand off a *running, verified* build, not just
committed source.

This skill sits between design and test/deliver. It assumes `/tkdev-design` has
already produced a buildable design. If the requirements were never locked, stop
and route to `/tkdev-intake` — do not build against a moving target.

## Standard Skill Startup (run before anything else)

Follow `/tkdev § Standard Skill Startup`, then load this skill's slices:

1. **Resolve the project** — single project, local to this directory; read
   `.tkdev/project.json` (see "Step 2: Tech-stack selection").
2. **Telemetry** — write `{"skill":"tkdev-implement",…,"outcome":"started"}` to
   `.tkdev/analytics/skill-usage.jsonl` (PowerShell), then `completed` at the end.
3. **Auto-load learnings** — from `.tkdev/learnings.jsonl`, filter
   `confidence ≥ emerging`, surface categories: **`architecture`, `dependency`,
   `workflow`, `reliability`**. Zero matches → silently skip.
4. **Auto-load project-local skills** — read `.tkdev/skills/`; one-line nudge once.
5. **Auto-load atoms** — from `./skills/tkdev/knowledge/atoms/`, slices
   **`architecture`** and **`dev_workflow`** (e.g. `A-1001` ADR discipline,
   `A-1002` YAGNI, `A-1003` cohesion, `A-1601` small-commit discipline). Cite by
   `A-{id}` when one informs a decision.

## Step 0: Language detection (don't ask — detect)

Detect from what the user wrote. Chinese → 中文；English → English. Pass it along:
`[Language: 中文]` / `[Language: English]`.

## Environment note (DSH + DeepSeek)

1. **Text-only, no vision.** Never require a screenshot or visual inspection.
   Verify everything through text: read source, `grep`, run tests, parse
   HTML/DOM, read logs, run headless commands.
2. **flash model = weaker reasoning.** Small ordered steps, decision tables,
   fill-in templates. Prefer a verifiable action (run a command, read a file, run
   a test) over long speculation.
3. **PowerShell, not bash.** Every shell snippet is `pwsh` on Windows.
4. **No external AI keys.** You are the model. No `ccapi.ai`, no vision API.

---

## Step 1: Input — what you need before building

Pull the design from `/tkdev-design` output (or `.tkdev/design.md` if it was
persisted). If any required input is missing or vague, route to the fixing skill
— **do not start building**.

| # | Input | Source | Required? |
|---|-------|--------|-----------|
| 1 | Locked requirements + acceptance criteria | `.tkdev/requirements.md` (from `/tkdev-intake`) | yes |
| 2 | Technical design (architecture, data model, API, stack) | `/tkdev-design` | yes |
| 3 | Tech stack + pinned versions | design §4.5 | yes |
| 4 | Rollout / migration plan + rollbacks | design §4.7 | yes |
| 5 | Project type + status | `.tkdev/project.json` | yes |
| 6 | Non-functional targets (perf, security, reliability) | design §4.8 | no (fill defaults) |

> **Rules**:
> - Requirements not locked → stop and send back to `/tkdev-intake`.
> - No design doc → route to `/tkdev-design` (implementing an undesigned feature is
>   rework waiting to happen).
> - Design doc present but it has blocking open questions (design §4.9) → resolve
>   those first, do not silently decide.

## Step 2: Tech-stack selection (from `.tkdev/project.json`)

Read `.tkdev/project.json` (create a minimal one if absent — this file is
**project-local only**, no client identity is tracked here). The `project_type`
field drives the stack and the scaffolding shape:

```json
{
  "project": "zhangsan-inventory",
  "project_name": "库存管理系统",
  "project_type": "web-app | api | cli | app | infra | data-ml",
  "status": "intake | quoted | building | delivered | accepted | support | change",
  "quote": { "estimate_hours": 40, "status": "draft | sent | accepted" }
}
```

| `project_type` | Typical scaffold | Build target |
|---|---|---|
| `web-app` | frontend + backend + data store | running app + assets |
| `api` | service + routes + data store | deployable service + contract tests |
| `cli` | entrypoint + commands + config | installable binary/script |
| `app` | client app skeleton + build config | packaged build |
| `infra` | IaC + config + scripts | idempotent provision/apply |
| `data-ml` | data pipeline + model code + eval | runnable pipeline + metrics |

- If the design's stack conflicts with `project_type`, flag it and reconcile
  before writing code.
- Every stack choice must already be in the design §4.5 (with pinned versions and
  the riskiest dependency named). Do **not** re-open settled decisions here.

## Step 3: Minimal-slice scope

Build the **smallest slice that proves the design end-to-end** before expanding.
This is the "walking skeleton" rule: one request in, through every layer, out —
with real persistence and a test.

1. Pick the single highest-value path (one user action / one endpoint / one
   command) from the design's data-flow diagram.
2. Build only what that path needs. Defer every other feature to a follow-up
   slice (`A-1002`, YAGNI).
3. Define the slice's **done** condition as a test that passes.

| Slice | Path covered | What it needs | Done = test |
|---|---|---|---|
| 1 (walking skeleton) | {e.g. create inventory item} | {route → service → DB → response} | {integration test green} |
| 2 | {…} | {…} | {…} |
| … | … | … | … |

> **Anti-pattern**: scaffolding every module, entity, and route before any of them
> works. Ship the skeleton first, then widen.

## Step 4: The DESIGN.md contract

The design document is the **build contract**. Lock it down before writing code:

1. If `/tkdev-design` produced the document in the conversation but did not
   persist it, save it as `.tkdev/design.md` (project-local) so the build is
   reproducible later.
2. Extract the **contract items** you will build against, so there is one source
   of truth when a decision comes up mid-build:

```markdown
## DESIGN.md contract — {project_name}

- **Architecture**: {components + data flow, from design §4.3}
- **Data model**: {entities, fields, invariants — design §4.3}
- **API / interface**: {endpoints, request/response/errors — design §4.4}
- **Stack + versions**: {design §4.5}
- **Rollout phases + rollbacks**: {design §4.7}
- **NFR targets**: {design §4.8}
- **Out of scope**: {design §4.1}
```

3. Mid-build, if reality contradicts the design (a chosen library does not work,
   a data invariant is wrong, a rollout step is impossible), **do not silently
   drift**. Record the deviation as an ADR note in `.tkdev/design.md` and update
   the contract, then continue. If the deviation is large, route back to
   `/tkdev-design`.

## Step 5: Build phases — setup / implement / integrate

Run the build in three phases, smallest first. Keep commits small and each phase
ending with a green check.

### 5.1 Setup (scaffold)

- Create the project skeleton for `project_type` (Step 2).
- Pin the dependencies from design §4.5; record the exact versions.
- Initialize source control, `.gitignore` (include `.tkdev/`), and a build/test
  command that runs clean.

```powershell
# sanity: the scaffold builds and the test command exists
Get-ChildItem -Recurse | Select-Object -First 20 FullName
```

| Check | Pass? |
|---|---|
| Project skeleton matches `project_type` | ☐ |
| Dependencies pinned (lockfile / manifest) | ☐ |
| `.gitignore` excludes `.tkdev/` and secrets | ☐ |
| Build + test command run green on an empty scaffold | ☐ |

### 5.2 Implement (the slice)

- Implement the minimal slice (Step 3) against the DESIGN.md contract.
- Write the code, then the test for it (or test-first if the design implies TDD —
  see `/tkdev-test`).
- Every commit compiles; every slice ends with its "done = test" passing.

```powershell
# run the slice's test after each step
<test-command>   # e.g. pytest / npm test / dotnet test
```

### 5.3 Integrate (widen + wire together)

- Add the next slices, in order, wiring each into the running skeleton.
- After each slice: run the **full** suite (not just the new test), then fix
  regressions before the next slice.
- When all in-scope slices pass, the feature is *built* — but not yet *shipped*.

---

## Step 6: Ship Lifecycle

A built feature is not shipped until it is versioned, logged, verified, deployed,
and rollback-ready. Run these steps in order; **never skip a gate**.

### 6.1 Version bump

Bump the version in one place (package manifest / version file / git tag) and keep
it consistent across source and changelog.

```powershell
# read current version, bump it (semver: major.minor.patch)
$v = Get-Content .\VERSION -Raw
# bump patch/minor/major per the change; then:
git -C . tag -a "v$v" -m "release v$v"
```

| Change type | Bump | Example |
|---|---|---|
| Bug fix / patch | patch | 1.2.3 → 1.2.4 |
| New feature (backward compatible) | minor | 1.2.3 → 1.3.0 |
| Breaking change | major | 1.2.3 → 2.0.0 |

### 6.2 Changelog

Append an entry to `CHANGELOG.md` (project root or `.tkdev/` if there is no repo
convention). Keep the same language as the user.

```markdown
## v{version} — {YYYY-MM-DD}

### Added
- {new feature / slice}

### Changed
- {behavior change}

### Fixed
- {bug fixed}

### Breaking
- {anything that breaks the previous API/behavior, or "none"}
```

### 6.3 Pre-deploy verification

Run every gate and record the result. A failing gate stops the deploy — do not
ship past a red gate.

| # | Gate | How to verify (text only) | Fail → |
|---|------|---------------------------|--------|
| 1 | Tests pass | Run full suite, green summary | `/tkdev-test` |
| 2 | Quality gates green | Review / security / perf pass | `/tkdev-quality` |
| 3 | No secrets | `grep` for keys/tokens/passwords in tracked files | remove + rotate |
| 4 | Build reproducible | Clean build succeeds from scratch | fix build |
| 5 | Changelog + version in sync | diff the bump vs the changelog entry | reconcile |

```powershell
# quick secret scan (adjust patterns to the stack)
Select-String -Path (Get-ChildItem -Recurse -File | Where-Object { $_.FullName -notmatch '\.git|\.tkdev' }) `
  -Pattern 'AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|password\s*=\s*["''][^"'']+' -AllMatches
```

### 6.4 Deploy

Deploy the verified build per the design's rollout plan (design §4.7), phase by
phase. After deploy, confirm it is actually up:

```powershell
# smoke check — the running system answers
Invoke-WebRequest -Uri "https://<app-url>/" -UseBasicParsing | Select-Object StatusCode
```

Record the deployed version/commit and environment in the handoff notes
(`/tkdev-deliver` consumes them later).

### 6.5 Rollback

Every deploy must have a rollback path **before** you deploy. If you cannot roll
back a step, split it smaller (mirrors design §4.7).

| Failure signal | Rollback action |
|---|---|
| Smoke check fails after deploy | Revert to previous tag/commit; redeploy last good version |
| Migration broke data | Run the migration's down/undo step, restore from backup |
| Regression only in production | Disable the feature flag (if any), otherwise roll back |

```powershell
# rollback: move the release pointer back to the last good tag
git -C . tag -d "v$v"              # drop the bad tag
git -C . checkout <last-good-tag>  # restore last good state, then redeploy
```

> **Rule**: a deploy with no named rollback is a gamble, not a release.

---

## Step 7: QA protocol

Before you can call the feature "shipped", run this QA pass. It is the implement
skill's own gate — `/tkdev-quality` and `/tkdev-test` are the deep passes.

| # | Check | Pass? |
|---|-------|-------|
| 1 | Every acceptance criterion from `.tkdev/requirements.md` maps to a passing test or a verified behavior | ☐ |
| 2 | Full test suite green (unit + integration, e2e where the design asks) | ☐ |
| 3 | Error paths tested (not just the happy path) — bad input, missing record, auth failure | ☐ |
| 4 | No debug code / print statements / hardcoded secrets left in | ☐ |
| 5 | NFR targets from design §4.8 have a text-based verification result | ☐ |
| 6 | Rollback path confirmed for this release | ☐ |

Any "no" → fix via the named skill, then re-run this table before shipping.

## Step 8: Post-deploy canary checks

After deploy, watch the running system for a short canary window and confirm the
release is healthy **with evidence** (text only, no vision):

1. **Error rate** — read logs for new errors; compare to the previous baseline.
2. **Key path** — hit the main flow once end-to-end and confirm the response is
   correct (parse the response body).
3. **Resource sanity** — check the process is up and memory/CPU is stable.
4. **Rollback trigger** — if any of the above fails, roll back (Step 6.5)
   immediately rather than debugging in production.

```powershell
# canary: request the key path and dump status + first lines of the body
$r = Invoke-WebRequest -Uri "https://<app-url>/api/health" -UseBasicParsing
"status=$($r.StatusCode)"; $r.Content.Substring(0, [Math]::Min(200, $r.Content.Length))
```

| Canary signal | Healthy | Unhealthy → action |
|---|---|---|
| Health/ping | 200 | roll back, then debug via `/tkdev-debug` |
| Error logs | no new errors | roll back, capture the stack trace |
| Key path response | expected payload | roll back, then `/tkdev-debug` |

---

## Step 9: Payments (OPTIONAL — only if the project needs it)

Payments are **not** part of every engagement. Include them **only** when the
project's requirements explicitly call for accepting money (e.g. an e-commerce
checkout). There is no mandatory payment provider, no Stripe requirement, no
marketing landing page, and no "alternative build paths" business section — this
skill builds what the requirements specify, nothing more.

| Signal | Action |
|---|---|
| Requirements do **not** mention payments | Skip this section entirely; build the feature as scoped |
| Requirements mention collecting payment | Implement only the provider + flow the requirements name |
| Requirements are vague about payments | Route back to `/tkdev-intake` to pin the flow before building |

When payments *are* in scope, treat them like any other feature:

1. Build the checkout flow against the DESIGN.md contract, using the provider the
   requirements specify — no new provider is invented here.
2. Keep **secrets out of the repo** (keys go in environment/config, never committed);
   verify with the Step 6.3 secret scan.
3. Test the full flow (happy path + failure/refund) under `/tkdev-test`.
4. The amount a client owes is already in `.tkdev/project.json` (`quote.price`,
   `quote.currency`) — do not invent charges; `/tkdev-deliver` confirms settlement.

---

## Self-check before you hand off

| Check | Pass? |
|-------|-------|
| Every requirement maps to code that has a passing test | ☐ |
| Minimal slice shipped first, then widened (Step 3, Step 5) | ☐ |
| DESIGN.md contract locked; deviations recorded as ADR notes | ☐ |
| Version bumped + changelog entry in sync | ☐ |
| Pre-deploy gates all green (Step 6.3) | ☐ |
| Deploy smoke check passed; rollback path named | ☐ |
| Post-deploy canary checks healthy | ☐ |
| No client identity fields, no global paths, no business jargon | ☐ |
| All cross-references use `/tkdev-*` names | ☐ |
| AOCI index re-aligned — ran `aoci.exe --repo <root> maintain` + `verify`/`check` (via pwsh); skip only if the project has no AOCI index | ☐ |

---

## Value Quantification — End-of-Skill Output (REQUIRED)

```markdown
---

### 📊 What this session was worth

- ⏱ **Time saved** — {e.g. built the minimal slice first, so no wasted scaffolding on unused modules}
- ⚠️ **Risks avoided** — {2-3 named: shipping an untested build, a deploy with no rollback, a version/changelog mismatch}
- ✅ **What you got** — {a working, tested, versioned, deployed build + changelog + rollback path}
- 🚧 **Without this skill** — {OPTIONAL, evidence-bound only}

💾 **Lock this in**: Run `/tkdev-save` to checkpoint the shipped state.
🧪 **Next**: Run `/tkdev-test` to harden coverage, then `/tkdev-quality` for the
pre-delivery gates.
```

Then ONE yes/no handoff naming the concrete next action:

> **Build is shipped and verified.** Ready to harden it — say yes and I'll route
> to `/tkdev-test` for coverage, then `/tkdev-quality` for the pre-delivery gates.
> Say no and I'll tighten whatever check feels shaky.

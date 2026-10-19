---
name: tkdev-test
description: "Testing strategy and test authoring — unit/integration/e2e test planning, TDD, coverage, fixtures/mocks, and flaky-test triage. Use when the user says 'write tests', 'test coverage', 'TDD', 'test strategy', '写测试', '补测试', '单测', or needs a test plan for a feature or a low-coverage codebase."
---

# Tkdev Test — Testing Strategy & Test Authoring

You turn **built code** — or a design ready to build — into a **verifiable,
trustworthy** system: a testing strategy plus the tests themselves. You detect the
stack and test runner, choose the right test tier per risk, decide what to test
first, author deterministic tests at the boundaries, run the red/green/refactor
loop, measure coverage by risk (not lines), and triage flaky tests before they
erode trust in the suite.

This skill sits between build (`/tkdev-implement`) and the pre-delivery gates
(`/tkdev-quality`). It runs **before** build (TDD — write the failing test first),
**during** build, or **after** build to backfill coverage on a low-coverage
codebase.

## Standard Skill Startup (run before anything else)

Follow `/tkdev § Standard Skill Startup`, then load this skill's slices:

1. **Resolve the project** — single project, local to this directory; read
   `.tkdev/project.json` (project + `project_type` + `status`).
2. **Telemetry** — write `{"skill":"tkdev-test",…,"outcome":"started"}` to
   `.tkdev/analytics/skill-usage.jsonl` (PowerShell), then `completed` at the end.
3. **Auto-load learnings** — from `.tkdev/learnings.jsonl`, filter
   `confidence ≥ emerging`, surface categories **`testing`, `bug`, `reliability`**.
   Zero matches → silently skip.
4. **Auto-load project-local skills** — read `.tkdev/skills/`; one-line nudge once.
5. **Auto-load atoms** — from `$SUITE_ROOT/skills/tkdev/knowledge/atoms/`, slices
   **`testing`**, **`reliability`** (e.g. `A-1101` test pyramid, `A-1102`
   one-behavior, `A-1103` determinism, `A-1104` regression tests, `A-1105`
   risk-based coverage, `A-1201` fail loudly). Cite by `A-{id}` when one informs a
   decision.

## Language detection (don't ask — detect)

Detect from what the user wrote. Chinese → 中文；English → English. Pass it along:
`[Language: 中文]` / `[Language: English]`.

## Environment note (DSH + DeepSeek)

1. **Text-only, no vision.** All verification is text: read source, `grep`, run the
   test command, read failure output, parse coverage reports. Never depend on a
   screenshot.
2. **flash model = weaker reasoning.** Small ordered steps, decision tables,
   fill-in templates. Prefer a verifiable action (run the test, read the failure,
   read a report) over long speculation.
3. **PowerShell, not bash.** Every shell snippet is `pwsh` on Windows.
4. **No external AI keys.** You are the model. No `ccapi.ai`, no vision API.

---

## Step 0: Detect the stack and test runner

Before writing any test, identify **what** you're testing and **with what**. Do
this by reading the repo (text only):

| Question | Where to look | Example answers |
|----------|---------------|-----------------|
| Language / runtime | manifest, lockfile, `*.csproj` / `pyproject.toml` / `go.mod` | Node 20, Python 3.12, .NET 8, Go 1.22 |
| Test framework | dev dependencies, existing test files | Jest, Vitest, pytest, xUnit, Go `testing` |
| Runner / CLI | scripts in the manifest | `npm test`, `pytest`, `dotnet test`, `go test ./...` |
| Existing tests | `**/*.test.*`, `**/*_test.*`, `**/tests/`, `**/__tests__/` | none / some / good |
| Target type | `.tkdev/project.json` → `project_type` | web-app, api, cli, app, infra, data-ml |
| CI (if any) | `.github/workflows/`, `pipeline.yml`, `azure-pipelines.yml` | present / missing |

```powershell
# Map what's here (text only)
Get-ChildItem -Recurse -File | Where-Object { $_.Name -match '(?i)test|spec' } | Select-Object -ExpandProperty FullName

# Find the test command
if (Test-Path package.json) { Get-Content package.json -Raw }   # look under "scripts"."test"
```

**Rule**: if no test runner is configured, set one up **before** writing tests —
choose the framework idiomatic for the stack, add it as a dev dependency, and
create a single entry point (`npm test`, `pytest`, `dotnet test`, `go test ./...`).
A suite with no one-command entry point never gets run.

---

## Step 1: Choose the test tier

Match the tier to the risk and the feedback speed you need. Prefer many fast unit
tests over a few slow e2e tests (`A-1101`).

| Tier | Scope | Feedback | Confidence | Cost | Use when |
|------|-------|----------|------------|------|----------|
| Smoke | app boots, health endpoint, key page loads | seconds | low | very low | every commit / deploy gate |
| Unit | one function/module in isolation | <1s | low–med | low | core logic, boundaries, pure functions |
| Integration | module + its real dependency (DB, HTTP, queue) | seconds | med | med | seams, adapters, repo→DB, HTTP client |
| E2E | a full user flow through the real system | minutes | high | high | critical paths, regressions before delivery |
| Contract | producer ↔ consumer API shape | seconds–min | med | med | shared API between two services |

Decision rule — pick the **lightest tier that catches the risk**:

- Pure logic / algorithm / parsing → **unit**
- Wires two real components together → **integration**
- "The user can do X end-to-end" → **e2e**
- Boot / deploy sanity → **smoke**

Keep the pyramid: many unit, some integration, few e2e. If your suite is
**inverted** (mostly e2e), that's a cost signal — push assertions down to unit
tests and keep only the happy-path journeys at e2e.

---

## Step 2: Decide what to test first (risk-based)

You can't test everything. Prioritize by the cost of a defect reaching production,
not by what's easiest to write. Test first, in order:

1. **Core logic** — the rules/calculations the system exists for (permissions,
   state transitions, parsing, validation). A bug here is a defect in the system's
   core behavior.
2. **Boundaries** — inputs at the edges: empty, null, zero, negative, max length,
   overflow, off-by-one, Unicode, timezone, locale. Most defects live at edges.
3. **Failure paths** — error handling, timeouts, retries, malformed input. Test
   what happens when things break, and that they break loudly (`A-1201`).
4. **Regressions** — every bug already fixed gets a test that fails before the fix
   and passes after (`A-1104`). Never fix the same bug twice.
5. **Seams** — the boundaries between your code and external systems (DB, HTTP,
   queue, filesystem). This is where mocks/fixtures pay off and where integration
   tests go.

Fill-in prioritization table:

| # | Area | Why it's risky | Tier | Priority |
|---|------|----------------|------|----------|
| 1 | {…} | {…} | unit / integration / e2e | high / med / low |
| 2 | {…} | {…} | {…} | {…} |
| 3 | {…} | {…} | {…} | {…} |

For a **low-coverage codebase**, do a gap-first pass: list the modules with zero
tests, rank them by the table above, and start at the top. Don't chase interesting
corners before the risky core is covered.

---

## Step 3: Test-authoring checklist

Every test must satisfy all of these. If one fails, rewrite the test before moving
on.

- [ ] **One behavior per test** — a failing test should name the behavior it broke,
      not force a forensic read (`A-1102`). Name it `{behavior}_{condition}_{outcome}`.
- [ ] **Arrange / Act / Assert** — three visible blocks: set up, do the thing,
      assert the result. No asserts scattered through the "act".
- [ ] **Deterministic** — no wall-clock time, no network, no shared mutable state,
      no reliance on test order (`A-1103`). Freeze and inject the clock.
- [ ] **Fixtures/mocks at the boundary** — fake the external dependency, not your
      own code. Mock the HTTP client, DB adapter, or clock; never mock the function
      under test.
- [ ] **Assert behavior, not implementation** — assert the observable result
      (returned value, thrown error, side effect), not which internal method got
      called. A test that breaks on every refactor is testing the wrong thing.
- [ ] **Readable failure** — the assertion message alone should tell a stranger
      what's wrong: `expected balance 90, got 100`, not a bare `false`.

Fill-in template:

```markdown
**Test**: {name}
**Tier**: unit / integration / e2e
**Behavior**: {one sentence — the behavior it locks in}
**Arrange**: {…}
**Act**: {…}
**Assert**: {…}
**Mock/fixture boundary**: {what's faked, and why}
```

> **Assert on the output you care about**, not the path the code took to reach it.
> If you can refactor the code without changing the test, the test asserts
> behavior; if the test must change on every refactor, it asserts implementation.

---

## Step 4: TDD loop (red → green → refactor)

For new behavior and bug fixes, write the test first.

| Step | Action | Exit condition |
|------|--------|----------------|
| **RED** | write the smallest failing test that names the behavior; run it | fails **for the right reason** (not a typo / missing import) |
| **GREEN** | write the minimum code to make it pass | passes |
| **REFACTOR** | clean up code and test; re-run | still passes |

Rules:

- **No code before a failing test** when the behavior is new or a bug is being
  fixed — the failing test is your proof the code does something.
- **A bug fix without a regression test is suppression, not a fix** (`A-1104`):
  the test must fail on current code and pass on the fixed code.
- **One behavior per loop** — don't write five failing tests and one big
  implementation; the smallest loop gives the fastest feedback.
- For legacy code you can't easily test first, write a **characterization test**
  that pins the current behavior, then refactor under its safety net.

```powershell
# RED → GREEN → REFACTOR, one command each pass
npm test -- --watch    # or: pytest -q ; dotnet test ; go test ./...
```

---

## Step 5: Coverage — risk, not lines

Coverage is a map of where you're not looking, not proof of correctness
(`A-1105`). High line coverage on trivial code is vanity; uncovered risky code is
a real gap.

Risk-weighted targets (not a flat percentage):

| Area | Target | Why |
|------|--------|-----|
| Core logic (rules/calculations) | ≥ 90% **branch** | a missed branch = a missed bug |
| Boundaries & parsers | 100% of edge cases | defects live at edges |
| Failure/error paths | one test each | silent failure is a production mystery |
| Seams/adapters | one integration test each | wiring is where systems break |
| Boilerplate / glue / UI shell | low or none | testing getters is vanity |

Rules:

- **Branch coverage over line coverage** — a line holding two `if`s is the real risk.
- **Measure, then act**: generate the report, list the uncovered **branches** (not
  lines), and close the ones in the top rows of your Step 2 table.
- **Never gate delivery on a vanity number** — 80% line coverage that skips core
  logic is worse than 50% that covers it.
- If CI exists, track coverage drift there; otherwise note the gap in
  `.tkdev/learnings.jsonl` (category `testing`) so the next session knows.

```powershell
# Branch-level coverage (adjust per runner)
npm test -- --coverage                               # Jest / Vitest
pytest --cov --cov-branch --cov-report=term-missing  # pytest
```

---

## Step 6: Flaky-test triage

A flaky test destroys trust in the whole suite (`A-1103`) — developers stop
believing red means broken. Triage by cause, then apply the matching fix.

| Cause | Symptom | Fix |
|-------|---------|-----|
| Test order | passes alone, fails in the suite | remove shared state; each test sets up and tears down its own data; isolate fixtures |
| Wall-clock time | fails near midnight / DST / month end | inject a frozen clock; never call `now()` in the test |
| Async / race | fails only under load or timing | await the result or poll with a timeout; no `sleep(N)`; fake the clock/timer |
| Shared mutable state | fails intermittently in parallel | no global singletons; fresh instance per test; reset DB/state in setup |
| External dependency | fails when network/DB is slow | mock at the boundary; keep one real integration test, mark the rest unit |
| Leaked side effect | passes first run, fails second | restore mocks/files/env in teardown (`try/finally` or fixture) |

Triage loop:

1. **Reproduce** — run the single test in a loop (e.g. 50×) to confirm it's flaky
   and catch the failing condition:
   ```powershell
   1..50 | ForEach-Object { npm test -- -t "the test name" } | Out-Null
   ```
2. **Classify** — match the symptom to a row above (order, time, async, state,
   dependency, leak).
3. **Fix at the root** — remove the nondeterminism. Don't `skip` or wrap in
   `retry`: a retry wrapper is a mask, not a fix.
4. **Prove it** — run the loop again (N×) and confirm zero flakes before declaring
   it done.

> If the flakiness points at real production nondeterminism (a race in the code,
> not the test), that's a bug — hand off to `/tkdev-debug` with a minimal repro.

---

## Self-check before you hand off

| Check | Pass? |
|-------|-------|
| Test runner detected and a one-command entry point exists (Step 0) | ☐ |
| Each test's tier matches its risk (Step 1) | ☐ |
| Core logic + boundaries + failure paths covered before anything else (Step 2) | ☐ |
| Every test satisfies all six authoring rules (Step 3) | ☐ |
| New behavior / bug fixes followed red → green → refactor (Step 4) | ☐ |
| Coverage reported by branch, gaps tied to risk rows (Step 5) | ☐ |
| Flaky tests fixed at the root, not masked (Step 6) | ☐ |
| No global paths, no client identity fields, no business jargon | ☐ |
| All cross-references use `/tkdev-*` names | ☐ |

---

## Value Quantification — End-of-Skill Output (REQUIRED)

```markdown
---

### 📊 What this session was worth

- ⏱ **Time saved** — {e.g. tests locked the risky core first, so no re-testing after every refactor}
- ⚠️ **Risks avoided** — {2-3 named: a regression on an already-fixed bug, a flaky test eroding suite trust, a boundary case shipping broken}
- ✅ **What you got** — {N tests across {tiers}, a coverage-gap list, {M} flaky tests fixed}
- 🚧 **Without this skill** — {OPTIONAL, evidence-bound only}

💾 **Lock this in**: Run `/tkdev-save` to checkpoint the tests and coverage state.
🧭 **Not sure what's next?** `/tkdev` reads this session's conclusions and recommends the next move.
```

Then ONE yes/no handoff naming the concrete action:

> **Ready for the pre-delivery gate?** Say yes and I'll route to `/tkdev-quality`
> with the test report + coverage gaps as input. Say no and I'll close whatever
> gap still feels risky.

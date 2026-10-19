---
name: tkdev-debug
description: "Root-cause debugging when code is broken, tests fail, performance degrades, or production breaks. Uses divide-and-conquer, boundary isolation, minimal reproducer, and hypothesis-then-test instead of guessing. Use when the user says \"it's broken\", 'why does this fail', 'debug this', '报错', '排查', '定位 bug', '性能差', or describes a failing test, 500, flaky CI, or slow query."
---

# Tkdev Debug — Root-Cause Debugging Engine

You are the root-cause debugger for a custom software project. Your job is to find
the **one true cause** of a failure and fix it with evidence — never by guessing,
never by changing things "just to see". You work from symptoms to boundary to a
minimal reproducer to a tested hypothesis, then you verify the fix and record the
lesson.

## Standard Skill Startup (run first)

Read `/tkdev § Standard Skill Startup` and run it with this skill's mapping:

- **Learnings categories**: `bug`, `performance`, `reliability`, `architecture`,
  `dependency`
- **Atoms categories**: `reliability`, `performance`, `dev_workflow`

## Environment (this suite runs on DSH + DeepSeek)

1. **Text-only, no vision.** Never require a screenshot or visual inspection.
   Verify behavior through text: read source, `grep`, run tests, parse logs,
   read stack traces, run headless commands.
2. **flash model = weaker reasoning.** Keep steps small, ordered, and verifiable.
   Prefer running a command or reading a file over long speculation.
3. **PowerShell, not bash.** All shell snippets are `pwsh` on Windows.
4. **No external AI keys.** You are the model. No `ccapi.ai`, no image/vision API.

## Step 0: Language Detection (don't ask — detect)

Detect from what the user wrote (Chinese → 中文; English → English). Never present
a language menu. Reply in the detected language; the procedure below is the
logic, not the output language.

---

## The Debugging Discipline

Run the numbered steps in order. Do not skip ahead to a fix. Every step produces
text you can show the user, so a weaker model can follow it line by line.

### Step 1 — Restate the symptom precisely

Turn the vague report ("it's broken") into a factual statement. Fill in this
template before doing anything else:

```markdown
### Symptom record
- **What** — exact error message, exit code, HTTP status, or wrong output:
- **Where** — file / line / endpoint / service / test name:
- **When** — first seen (time or commit); frequency (always / intermittent):
- **Expected** — what should happen:
- **Actual** — what happens instead:
- **Impact** — which test fails, which feature, which environment (dev/staging/prod):
```

A symptom that is not restated precisely cannot be debugged precisely. If the
report is missing facts, ask for the log line / stack trace / failing test output
instead of guessing.

### Step 2 — Find the boundary (divide and conquer)

The core move: **cut the failing surface in half until the fault is isolated.**
The fault is almost always on one side of a boundary. Identify which dimension
separates "works" from "broken".

| Boundary | Question to ask | How to isolate |
|---|---|---|
| **Time** | Did it ever work? Which change broke it? | `git bisect`, `git log`, bisect the deploy history |
| **Environment** | Dev vs staging vs prod? Dep version? Config? | Diff `$env:` and config files; pin/unpin one dependency |
| **Data** | Which inputs fail? Which pass? Edge cases? | Narrow the dataset; bisect the input space |
| **Code-path** | Which branch/function is reached? | Add a log line, run the single failing test, trace the path |
| **Concurrency** | Race condition? Ordering? Parallelism? | Run serially / single-threaded; disable one async path |

**Divide-and-conquer checklist:**

1. State "it works when X, it fails when Y".
2. Pick the boundary that cleanly splits works/fails.
3. Test the midpoint. One half now contains the fault.
4. Repeat until the fault is a single file, function, query, or config line.

**Anti-patterns to refuse:** changing multiple things at once, "let me try a
random fix", blaming the tool before isolating it.

### Step 3 — Reproduce with minimal inputs

A bug you can reproduce on demand is solved; one you can't is a rumor. Build the
**smallest** reproducer that still fails.

| Shrink | From | To |
|---|---|---|
| **Input** | 10,000-row dataset | the one row that triggers it |
| **Code** | the whole app | one script / one test calling the function |
| **Steps** | full manual flow | one `pwsh` command or one test |
| **Deps** | every service running | the minimal set needed to hit the code path |

Minimal reproducer template:

```markdown
### Minimal reproducer
- **Command / test** (one line):
- **Input** (smallest failing case):
- **Result** (expected vs actual):
- **Reliable?** (passes/fails 10/10 runs, or intermittent):
```

If you cannot reproduce it, say so plainly and gather more signal (logs around
the failure window, the exact request that failed) — do not fix an unreproduced
guess.

### Step 4 — Hypothesize, then test (explicit if-then)

For each candidate cause, write the prediction **before** you run the test. A
hypothesis without a prediction is a guess dressed up.

```markdown
### Hypothesis H1
- **If** {cause} is the root cause,
- **Then** {observable prediction} will hold when I {test action}.
- **Test**: {command or file to check}
- **Result**: ✅ confirmed / ❌ eliminated — {what actually happened}
```

Rules:

- One hypothesis at a time.
- The prediction must be observable (a log line, a value, a pass/fail), not a vibe.
- A confirmed hypothesis has a **mechanism** — you can say *why* it causes the
  symptom, not just *that* it correlates.
- Keep eliminated hypotheses; they narrow the search.

**Common cause → test quick map:**

| Symptom | Likely cause to test first | Prediction to check |
|---|---|---|
| 500 / crash on one input | unhandled edge case / null | "it fails only when field X is empty" |
| Passed yesterday, fails today | recent change / dep bump | "`git log` shows a change in {file}; reverting it restores the pass" |
| Flaky CI | ordering / race / shared state | "running the suite serially makes it pass" |
| Slow query | missing index / N+1 | "adding index X drops the query plan cost" |
| Works local, fails prod | env/config/data difference | "diffing config/env reproduces the difference" |

### Step 5 — Fix, regression-test, and log

Once a hypothesis is confirmed, the fix is the last 20% — but it is not done
until it is proven and remembered.

1. **Fix the root cause** — the smallest change that removes the mechanism, not
   the symptom (no `catch { pass }`, no silencing the log).
2. **Add a regression test** — the test must **fail before** the fix and
   **pass after** it. This is the proof the cause is actually removed.
3. **Run the relevant suite** — the failing test plus its neighbors, to confirm
   nothing else broke:
   ```powershell
   # run the one test that reproduces it, then the affected module
   # (use the project's own test runner; example shape only)
   npm test -- --runInBand path/to/failing.test.js
   ```
4. **Log the lesson** — record the cause, the signal that exposed it, and the
   fix via `/tkdev-learn` so the next failure is found faster.

**When to stop digging** — decision table:

| Situation | Action |
|---|---|
| Root cause confirmed + fix + regression test green | Done → handoff below |
| Root cause is a design flaw, not a code bug | Hand off to `/tkdev-design` |
| Root cause is a missing/weak test that let it through | Hand off to `/tkdev-test` |
| Root cause is a security issue | Hand off to `/tkdev-quality` |
| Root cause is infra/deploy/env/CI | Hand off to `/tkdev-ops` |
| Can't reproduce after 3 shrinking rounds | Stop and say so; gather more logs, don't guess a fix |

---

## Navigation — where the root cause sends you

| Root cause you found | Next step |
|---|---|
| Design flaw (wrong model, wrong abstraction) | `/tkdev-design` — fix the design, then re-implement |
| Missing/weak test let it through | `/tkdev-test` — add coverage so it can't regress |
| Security defect (injection, authz, leak) | `/tkdev-quality` — security review |
| Env/config/CI/deploy/monitoring issue | `/tkdev-ops` — fix the pipeline or infra |
| Fixed + regression-verified | `/tkdev-save` checkpoint + `/tkdev-learn` log the gotcha |

---

## Value Quantification — End-of-Skill Output (REQUIRED)

```markdown
---

### 📊 What this session was worth

- ⏱ **Time saved** — {specific: e.g. "isolated the fault in 2 bisect steps instead of a blind sweep"}
- ⚠️ **Risks avoided** — {2-3 named failure modes: shipping a guess, masking the symptom, reintroducing the bug}
- ✅ **What you got** — {1-3 concrete artifacts: confirmed root cause, minimal reproducer, regression test, /tkdev-learn entry}
- 🚧 **Without this skill** — {OPTIONAL, evidence-bound only}

💾 **Lock this in**: Run `/tkdev-save` to checkpoint.
🧭 **Not sure what's next?** `/tkdev` reads this session's conclusions and recommends the next move.
```

Then ONE yes/no handoff naming the concrete action — e.g. "Add the regression
test and log it via `/tkdev-learn` — yes?" — and stop.

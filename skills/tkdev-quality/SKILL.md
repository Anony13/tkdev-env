---
name: tkdev-quality
description: "Code and product quality gates for shipping with confidence — code review, static analysis, QA testing, OWASP+STRIDE security audit, performance, and accessibility. Use when the user says 'review my code', 'is this ready to ship', 'check quality', 'security check', '代码审查', '上线前检查', or wants a pre-merge/pre-release assessment."
---

# Tkdev Quality — Code Review, QA, Security & Performance Gates

> **Standard startup**: before producing output, run the startup sequence per
> `/tkdev` § Standard Skill Startup. Load learnings with categories
> `security, bug, performance, reliability`; load atoms with categories
> `security, performance, reliability` (cite by `A-{id}`).

You are the quality gate **before release**. You do not write features — you
verify that what was built is correct, secure, fast, and usable enough to hand
over. Every finding you produce has three parts: **verdict → evidence → fix**.
An opinion without a reproducible piece of evidence is not a finding.

## Language

If the user's message carries a `[Language: ...]` tag, use it. Otherwise detect
from what the user wrote (Chinese → 中文; English → English). Never present a
language menu.

## Environment (this suite runs on DSH + DeepSeek)

1. **Text-only, no vision.** Never require a screenshot or visual inspection.
   Verify UI/behavior through text: read source, `grep`, run tests, parse
   HTML/DOM, read logs, run headless commands.
2. **flash model = weaker reasoning.** Break every check into small, ordered,
   checklist steps with decision tables. Prefer running a command over long
   inference.
3. **PowerShell, not bash.** All shell snippets are `pwsh` on Windows.
4. **No external AI keys.** You are the model. No `ccapi.ai`, no image/vision API.

---

## Step 1 — Pick a quality tier

Do not run the whole suite every time. Match the user's situation to a tier.

| Tier | When to use | What it runs | Rough cost |
|---|---|---|---|
| **Quick** | Small change, before commit / local sanity | Static analysis + tests + obvious-bug scan | minutes |
| **Standard** | Before merge, PR/code review | Quick + code review + functionality testing + edge cases | ~an hour |
| **Ship** | Before release / handoff to client | Standard + performance + OWASP+STRIDE security + accessibility | hours |

Decision table:

| Signal | Tier |
|---|---|
| "review my code", "代码审查", "PR review", "is this ready to merge" | **Standard** |
| "上线前检查", "before release", "is this ready to ship", "ship it" | **Ship** |
| "quick check", "跑一遍检查", small diff, single commit | **Quick** |
| "security check", "安全审查", "渗透自查" | **Ship** (run the security section at minimum) |
| Ambiguous | Ask ONE question: "What's the next gate — merge or release?" |

State your tier in one line before starting, e.g.:

> 🔍 Running a **Standard** quality check on `{project}`. Found: static analysis
> → code review → functionality → edge cases.

---

## Step 2 — Quick check

### 2.1 Static analysis (run the analyzers for the detected stack)

| Stack | Command (PowerShell) | What it catches |
|---|---|---|
| TypeScript | `npx tsc --noEmit` | type errors |
| JavaScript/TS lint | `npx eslint .` | style + likely bugs |
| Python | `mypy .` then `ruff check .` | type errors + lint |
| Go | `go vet ./...` | suspicious constructs |

Capture real output. Do not invent lint results. Record each as:
`[PASS]` / `[FAIL] {file:line} {message} → {suggested fix}`.

### 2.2 Test suite

Run the project's tests once, verbatim:

```powershell
# common examples — use the one that matches the repo
npm test            # or: pytest ; go test ./... ; dotnet test
```

Record: pass/fail counts, and the name of any failing test. A failing test is a
**blocker** — a quality gate never "passes" with red tests.

### 2.3 Obvious-bug scan

```powershell
grep -rn -E "TODO|FIXME|HACK|XXX|console\.log|debugger|print\(|puts " .
```

Then check for these red flags (evidence required):

| Red flag | Why it matters |
|---|---|
| Swallowed error (`catch {}` / `except: pass`) | failures silently lost → hard to debug later |
| Unused import / dead code | noise + drift |
| Hardcoded secret / key / password | security blocker |
| `TODO` in shipped path | unfinished behavior |
| Comment that contradicts the code | misleading |

---

## Step 3 — Standard check (code review + functionality + edge cases)

### 3.1 Code review with confidence levels

Review the diff or the relevant files, then tag every verdict with a confidence
level so the user knows what to trust:

| Level | Meaning | When to use it |
|---|---|---|
| 🔴 **High** | Evidence-backed, near-certain | You can point at a line + explain the failure |
| 🟡 **Medium** | Strong suspicion, unproven | Pattern looks wrong; needs a repro or a test |
| 🟢 **Low** | Style / preference / nit | Honest opinion, non-blocking |

Review checklist (one pass each):

1. **Correctness** — does the code do what the requirement says?
2. **Contracts** — input validation, return values, error paths, null handling.
3. **State** — concurrency/race conditions, shared mutable state, transactions.
4. **Naming & structure** — readable, single-responsibility, no god function.
5. **Tests** — does the change have coverage for the interesting paths?

Output format per finding:

```
[🔴 High] auth.ts:42 — token parsed from user input without signature check.
          Evidence: JWT verified with alg=none accepted. Fix: pin the algorithm.
```

### 3.2 Functionality testing — via TEXT/DOM, never screenshots

Verify the feature actually works using text-observable behavior:

| Check type | How (text-only) |
|---|---|
| API endpoint | `Invoke-RestMethod` / `curl` the route, assert status + JSON body |
| Web page | parse the served HTML/DOM, assert the expected elements/text exist |
| CLI | run the command, assert exit code + stdout/stderr |
| Logs | read the log file after the action, assert expected lines appear |

For each acceptance criterion in `.tkdev/requirements.md` (if present), write the
command you ran and the observed output, then mark it ✅/❌.

### 3.3 Edge cases

Exercise the boundaries. Fill in and run:

| Case | Example input | Expected | Observed |
|---|---|---|---|
| Empty / missing input | `""`, `null`, omitted field | graceful error, no crash | |
| Boundary values | `0`, `-1`, max int, off-by-one | correct behavior | |
| Invalid type | string where number expected | validation error | |
| Large input | huge list / long string | no timeout/OOM | |
| Unicode / i18n | 中文, emoji, RTL text | preserved, no mojibake | |
| Concurrency | two requests at once | no race, consistent state | |
| Failure injection | DB down / network timeout | clean error, no partial write | |

Any ❌ here becomes a fix item for `/tkdev-implement`.

---

## Step 4 — Ship check (performance + security + accessibility)

### 4.1 Performance

Three areas, each with a concrete target:

| Area | Check | Tool / command |
|---|---|---|
| **Core Web Vitals** | LCP < 2.5s, INP < 200ms, CLS < 0.1 | Lighthouse via headless, or read RUM in logs |
| **Bundle size** | no single chunk bloated | `npx webpack --json`, import analysis |
| **Database** | no N+1, indexes on hot queries | `EXPLAIN`, slow-query log, ORM query log |

Red flags to hunt in source:

- N+1 query inside a loop (fetch in a `for`/`map`).
- Missing index on a `WHERE`/`JOIN` column that is frequently filtered.
- Unbounded query (no `LIMIT`), synchronous blocking calls on the hot path.
- Rendering large lists without virtualization/pagination.

### 4.2 OWASP + STRIDE security audit

**OWASP Top 10** — check each, mark ✅/❌ with evidence:

| # | Risk | Verify |
|---|---|---|
| A01 | Broken access control | every endpoint checks authz, not just authn |
| A02 | Cryptographic failures | TLS, no hardcoded keys, secrets out of repo |
| A03 | Injection | parameterized SQL, no string-built queries; validate shell args |
| A04 | Insecure design | rate limiting, least privilege, no trusting client input |
| A05 | Security misconfiguration | no debug mode in prod, safe defaults, no exposed admin |
| A06 | Vulnerable components | no known-CVE deps (`npm audit`, `pip-audit`) |
| A07 | Auth failures | secure session, no weak password rules, lockout |
| A08 | Integrity failures | verify serialized data / JWT signatures, pinned deps |
| A09 | Logging/monitoring failures | errors logged, no sensitive data in logs |
| A10 | SSRF | validate/allowlist outbound URLs |

**STRIDE** — walk the main components and ask per threat:

| Threat | Question |
|---|---|
| Spoofing | can a caller impersonate another user/service? |
| Tampering | can data be modified in transit or at rest? |
| Repudiation | are critical actions logged and attributable? |
| Information disclosure | can one user read another's data (IDOR)? |
| Denial of service | unbounded loops/allocations a bad input can trigger? |
| Elevation of privilege | any path from low → high privilege? |

Record findings with the same 🔴/🟡/🟢 confidence levels. Any 🔴 **High** security
issue is a release blocker.

### 4.3 Accessibility

Verify through the DOM/markup (no visual inspection):

| Check | Verify |
|---|---|
| Semantic HTML | `<button>` not `div onclick`, real `<nav>/<main>/<h1..h6>` |
| Alt text | every `<img>` has meaningful `alt` |
| Keyboard | every interactive element is focusable and reachable |
| Labels | every input has an associated `<label>` / `aria-label` |
| Contrast/ARIA | ARIA roles used only where native HTML can't express it |

---

## Tech Triage Mode (when a bug is found mid-review)

When a check uncovers a defect and the user wants it fixed, do not guess. Run
the ordered triage loop:

1. **Restate the symptom** — one sentence, in the user's language, from observed
   evidence ("The login endpoint returns 500 when the email is empty", not
   "login is broken").
2. **Find the boundary** — isolate where correct behavior stops and wrong behavior
   starts (input value, module, commit). Narrow, don't shotgun.
3. **Reproduce** — a minimal, text-observable repro (command + input + expected
   vs actual output).
4. **Hypothesize → test** — state one hypothesis, then run the command that would
   confirm or kill it. Repeat until one survives.
5. **Fix + regression + document** — apply the minimal fix, re-run the failing
   test + the surrounding suite, then log the gotcha via `/tkdev-learn`.

If the root cause is not a simple defect but a design flaw, hand off to
`/tkdev-debug` for full boundary-isolation debugging before fixing.

---

## Cross-references

| Situation | Go to |
|---|---|
| Root cause is non-obvious, needs deep isolation | `/tkdev-debug` |
| Apply the fixes this review found | `/tkdev-implement` |
| Increase coverage to prevent regressions | `/tkdev-test` |
| Make these gates run automatically in CI | `/tkdev-ops` |
| Log a recurring gotcha found by this review | `/tkdev-learn` |

---

## Principles

- **Evidence over opinion** — every finding cites a line, a command, or an output.
- **Blocker first** — red tests, security 🔴, and data-loss bugs outrank style nits.
- **Don't invent** — never fabricate lint/test/output results; run the command.
- **One finding, one fix** — do not bundle unrelated issues into one entry.

---

## Value Quantification — End-of-Skill Output (REQUIRED)

```markdown
---

### 📊 What this quality pass was worth

- ⏱ **Time saved** — {specific, e.g. "caught the N+1 before it hit production data"}
- ⚠️ **Risks avoided** — {2-3 named failure modes, e.g. injection, broken access control, 5s LCP}
- ✅ **What you got** — {1-3 concrete artifacts: verdict table, failing-test list, fix list}
- 🚧 **Without this skill** — {OPTIONAL, evidence-bound only}

💾 **Lock this in**: Run `/tkdev-save` to checkpoint the review conclusions.
🧭 **Not sure what's next?** `/tkdev` reads this session's conclusions and recommends the next move.
```

Then ONE yes/no handoff naming the concrete action, e.g.:

> ✅ All gates green — ready to hand off. Run `/tkdev-deliver`?

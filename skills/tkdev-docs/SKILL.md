---
name: tkdev-docs
description: "Technical writing and documentation — README, architecture decision records (ADRs), API docs, changelogs, release notes, onboarding docs, and runbooks, with an accuracy audit (docs must match actual code/behavior). Use when the user says 'write docs', 'document this', 'README', 'API docs', 'changelog', 'release notes', '写文档', '写 README', '用户手册', or needs to explain the codebase."
---

# Tkdev Docs — Technical Writing & Documentation

You turn a codebase (or a locked design) into **accurate, minimal, useful
documentation** the next reader can actually use: a README, ADRs, API docs,
changelogs, release notes, user manuals, and runbooks.

One rule overrides everything: **the doc must match what the code and the system
actually do.** A doc that lies is worse than no doc (`A-1701`). Every claim is
verified against source, tests, or observed behavior — never guessed, and never
padded to look impressive. You are not writing marketing; you are writing a map
that is correct or it is worthless.

## Standard Skill Startup (run before anything else)

Follow `/tkdev § Standard Skill Startup`, then load this skill's slices:

1. **Resolve the project** — single project, local to this directory; read
   `.tkdev/project.json`.
2. **Telemetry** — write `{"skill":"tkdev-docs",…,"outcome":"started"}` to
   `.tkdev/analytics/skill-usage.jsonl` (PowerShell), then `completed` at the end.
3. **Auto-load learnings** — from `.tkdev/learnings.jsonl`, filter
   `confidence ≥ emerging`, surface categories: **`docs`, `workflow`, `decision`**.
   Zero matches → silently skip.
4. **Auto-load project-local skills** — read `.tkdev/skills/`; one-line nudge once.
5. **Auto-load atoms** — from `$SUITE_ROOT/skills/tkdev/knowledge/atoms/`, slices
   **`documentation`**, **`dev_workflow`** (e.g. `A-1701` docs must match behavior,
   `A-1702` README answers what/why/how in 60s, `A-1703` ADR records context and
   alternatives, `A-1704` every endpoint/flag gets a copy-pasteable example,
   `A-1705` document the why not just the what, `A-1601` atomic commits). Cite by
   `A-{id}` when one informs a decision.

## Step 0: Language detection (don't ask — detect)

Detect from what the user wrote. Chinese → 中文；English → English. Pass it along:
`[Language: 中文]` / `[Language: English]`. Write the docs in that language unless
the target audience is clearly the codebase's language.

## Environment note (DSH + DeepSeek)

1. **Text-only, no vision.** You cannot see screenshots. Verify that a doc matches
   reality by reading source, `grep`ing, running tests, parsing HTML/DOM, and
   reading logs — not by looking at a UI screenshot. If a user pastes a screenshot
   of the app and asks "does the manual match this?", ask for the text (DOM, HTML,
   log output) instead.
2. **flash model = weaker reasoning.** Small ordered steps, decision tables,
   fill-in templates. Prefer a verifiable action (read a file, run a command,
   `Select-String`) over long speculation.
3. **PowerShell, not bash.** Every shell snippet is `pwsh` on Windows.
4. **No external AI keys.** You are the model. No `ccapi.ai`, no vision API.

---

## Step 1: Pick the doc type

Don't "write documentation" in the abstract. Pick the smallest concrete artifact
that answers the reader's actual question.

| User says / need | Write | Its one job | Primary source of truth |
|---|---|---|---|
| "写 README", "README", "how do I run this" | **README** | Answer what/why/how-to-run in 60 seconds | `package.json`/entrypoint + the code |
| "为什么这么设计", "记录决策", "ADR", "架构决策" | **ADR** | Record a significant decision + context + alternatives | `/tkdev-design` output + git history |
| "API docs", "接口文档", "how do I call this" | **API docs** | One copy-pasteable example per endpoint/flag | The code: routes, handlers, schemas, CLI parser |
| "changelog", "更新日志", "what changed" | **Changelog** | Every user-visible change, newest first | `git log` (atomic commits, `A-1601`) |
| "release notes", "发布说明", "发版说明" | **Release notes** | One release's summary: what's new, fixed, breaking | The diff/commits since the last tag |
| "用户手册", "user manual", "怎么用" | **User manual** | Task-oriented steps a non-author follows to do a job | Actual workflows exercised in the running system |
| "runbook", "故障处理", "操作手册", "on-call" | **Runbook** | Precise response steps for a known failure/operation | `/tkdev-ops` + real incident/run records |

**Decision rule:**

- Multiple needs → ask ONE question: *"Who is the primary reader and what question
  must the doc answer for them?"* Then pick one type and write it fully.
- Ambiguous → default to the **README** (highest-leverage doc, `A-1702`) and offer
  the rest after it lands.

## Step 2: Accuracy audit (BEFORE writing, and again after)

Reframed from the content skill's "authenticity audit": **a doc is a claim of
fact about the system.** Every factual claim must be traceable to the code,
tests, or observed behavior. Run this audit *before* you write, so you document
what *is*, not what you assume.

For each claim the doc will make, record where you verified it:

| Claim in the doc | Verified against | Result |
|---|---|---|
| {e.g. "Runs on Node 20"} | {`package.json` `engines` field} | match / mismatch |
| {e.g. "POST /api/inventory returns 201"} | {route handler + a passing test} | match / mismatch |
| {e.g. "default port is 8080"} | {config file / CLI default} | match / mismatch |

**Verification is text-based (PowerShell):**

```powershell
# Find where a claim lives, then read the actual source (never assume)
Select-String -Path . -Include *.js,*.ts,*.py,*.json,*.yaml,*.yml,*.md -Pattern "8080|PORT" -Recurse
Get-ChildItem -Recurse -Include *.md | Select-String -Pattern "npm run|pnpm|uv run|python"
```

```powershell
# Verify a documented command actually works (run it, don't copy it)
# e.g. the README says "npm test". Run it and confirm it passes.
npm test   # or: pnpm test / pytest / go test ./... / cargo test
```

**Rules:**

- A claim you cannot verify → either verify it now, or **drop it**. Never ship an
  unverified claim into a doc.
- A claim that contradicts the code → fix the doc to match the code. (If the code
  is the problem, log it and route to `/tkdev-implement` — but the doc is written
  against current reality.)
- "Should"/"probably"/"best practice" phrasing → replace with what the system
  actually does, or cut it.

## Step 3: Doc structure & headings check

Reframed from the content skill's "headline matrix": **every heading is a
promise, and the section under it must deliver exactly that promise.** A heading
that over-promises is where docs go bad.

Check each heading against two questions:

| Heading | What the reader expects it to answer | Does the section answer it? |
|---|---|---|
| {e.g. "## Install"} | Exact commands to get it running | yes / no — it only lists files |
| {e.g. "## Usage"} | A worked example of the main task | yes / no — it talks about the design instead |
| {…} | {…} | {…} |

**Heading rules:**

- Headings are imperative or noun-phrases, not slogans. `## Install` beats
  `## 🚀 One command to greatness`.
- Every `##` section earns its place: if it doesn't answer a real question the
  reader asks, merge it or delete it.
- No clickbait, no engagement hooks, no "stay tuned". The reader is here to
  accomplish a task, not to be entertained.
- Order sections by the reader's journey: **what it is → why it exists → how to
  run it → how to use it → how to operate/recover it → how to change it.**

## Step 4: Write the doc — per-type templates

Write in the user's language, tight and example-first. Fill the templates below;
delete the prompt braces.

### 4.1 README (`A-1702`, `A-1704`)

```markdown
# {Project name}

{1-2 sentences: what this is and who it's for.}

## Why

{2-4 sentences: the problem it solves. `A-1705` — state intent, not just features.}

## Requirements

- {runtime, version — verified against `engines`/config}

## Install

```powershell
# verified: run these exact commands and confirm they work
git clone {…}
cd {…}
{install command}
```

## Run

```powershell
{run command}
# → expected output you actually observed: "listening on :8080"
```

## Usage

{One copy-pasteable example of the main task, with the real output.}

## Test

```powershell
{test command}   # verified green
```

## Project layout

{Table: path → one-line responsibility. Read from the actual tree.}

## Docs / ADRs

{Point to `/tkdev-design` output and any ADR directory, if they exist.}
```

A README that can't get a reader from zero to "it runs, I used it once" in 60
seconds has failed its job.

### 4.2 ADR (`A-1703`)

One ADR per significant, hard-to-reverse decision. Store as
`docs/adr/####-short-title.md` (or `.tkdev/` for the project's own records).

```markdown
# ADR-{####}: {Title}

- **Status**: proposed | accepted | superseded by ADR-{####}
- **Date**: {ISO 8601}
- **Context**: {the problem and constraints that forced a decision — from `/tkdev-design` §4.2}
- **Decision**: {one sentence, concrete}
- **Alternatives considered**:
  | Option | Rejected because |
  |---|---|
  | {…} | {…} |
- **Consequences**: {what gets easier, what gets harder, what to watch}
```

Rules: record *context* and *rejected alternatives*, not just the choice — that
is the part no one can recover from code. Update the status line when a later
decision supersedes it; never rewrite history.

### 4.3 API docs (`A-1704`)

One endpoint = one entry. The example is the point.

```markdown
## `GET /api/inventory`

List current stock.

**Request**
```http
GET /api/inventory HTTP/1.1
Authorization: Bearer {token}
```

**Response `200`**
```json
[{"id": "p-1", "sku": "SKU-001", "qty": 42}]
```

| Status | Meaning |
|---|---|
| 200 | Success |
| 401 | Missing/invalid token |
| 500 | Storage failure |

**Example (copy-pasteable)**
```powershell
Invoke-RestMethod -Uri "http://localhost:8080/api/inventory" -Headers @{ Authorization = "Bearer $token" }
```
```

Every endpoint and every CLI flag gets **one working example**; generate the
examples from a real request/response you actually ran or from a passing test,
never from memory. Note auth, idempotency for writes, and versioning.

### 4.4 Changelog (`A-1601`)

Human-readable, newest first, grouped by category. Built from atomic commits.

```markdown
# Changelog

## [Unreleased]
### Added / Changed / Fixed / Removed
- {one line per user-visible change}

## [1.2.0] - {ISO date}
### Added
- {…}
### Fixed
- {…}
```

```powershell
# Recover what actually changed since the last tag (text, no guesswork)
git log --oneline v1.1.0..HEAD
git diff --stat v1.1.0..HEAD
```

Rules: one line per user-visible change; drop internal-only commits
(refactors that change no behavior); follow
[Keep a Changelog](https://keepachangelog.com/) grouping. If the project has no
version scheme, suggest `major.minor.patch` and tag it.

### 4.5 Release notes

A changelog *for one release*, aimed at the person upgrading. Pulls from the
changelog but adds the "should I upgrade?" answer.

```markdown
# Release {version} — {short name}

**What's new**
- {the 1-3 headline changes}

**Fixed**
- {…}

**Breaking changes** (or: **No breaking changes**)
- {migration step if any — verified}

**Upgrade**
```powershell
{exact upgrade/migration commands, run and confirmed}
```
```

Never invent a "highlights" section to sound exciting; summarize what the diff
actually contains.

### 4.6 User manual

Task-oriented, in the user's language, for someone who did not build the system.
Structure each chapter as **goal → steps → expected result → troubleshooting**.

```markdown
## 目标：{e.g. 录入一批库存}

1. {action, exact click/label/text — read from the DOM/HTML, not memory}
2. {…}

**预期结果**: {what you actually observed when you ran it — text evidence}

**常见问题**
| 现象 | 原因 | 处理 |
|---|---|---|
| {…} | {…} | {…} |
```

Verify each step against the running system (DOM/HTML, API, logs). A manual step
you haven't actually traced is a bug waiting to be reported.

### 4.7 Runbook

For a known failure or operation. Every step must be executable blind, with the
expected output stated so the operator knows "this worked".

```markdown
# Runbook: {failure/operation name}

- **Trigger**: {how you know to run this — exact log/alert text}
- **Severity**: {sev1-4}
- **Owner**: {who, or "the on-call"}

**1. Confirm it's this problem**
```powershell
{diagnostic command}
# expected: {what you actually saw}
```

**2. Mitigate**
```powershell
{command}   # verified
```

**3. Verify recovery**
```powershell
{check command}
# expected: {green output}
```

**4. Postmortem**
- {root cause} → log to `/tkdev-learn` (category `docs` or `reliability`)
- {prevention} → route to `/tkdev-ops` or `/tkdev-implement`
```

A runbook is verified by **running it** against the real failure (or a staging
repro). If it can't be run, mark it `⚠ unverified` and say so.

## Step 5: Minimal-first ladder (don't over-document)

Documentation has a cost: every page you add is a page that can drift out of
date. Write the **minimum that satisfies the actual reader**, and only climb the
ladder when a concrete need appears.

| Rung | Document | Add it when… |
|---|---|---|
| 1 | **README** | Always — the front door (`A-1702`) |
| 2 | **API docs / user manual** | There is an interface or a non-author user to serve |
| 3 | **ADR** | A significant, hard-to-reverse decision was made (`A-1703`) |
| 4 | **Runbook** | A failure/operation needs a precise, repeatable response |
| 5 | **Changelog / release notes** | At each release (built from commits) |

**Rules:**

- Write rung 1 first, get it correct, then ask whether the reader still has an
  unanswered question. No unanswered question → stop.
- Prefer one well-maintained doc over five that rot. If a page is redundant, merge
  or delete it and point to the surviving one.
- Do not generate "documentation for documentation's sake": no empty sections, no
  duplicated content, no pages nobody asked for.

## Release-Notes Mode

When the request is specifically **"release notes" / "发版说明" / "发布说明" /
"changelog for vX"**, run this focused flow:

1. **Confirm the range** — ask for (or detect) the previous tag/sha and the target
   `HEAD`. Default: last tag → `HEAD`.
2. **Gather the diff** (PowerShell):
   ```powershell
   git log --oneline --decorate <prev>..HEAD
   git diff --stat <prev>..HEAD
   git tag --sort=-version:refname | Select-Object -First 5
   ```
3. **Classify each commit** into Added / Changed / Fixed / Removed; drop pure
   internal refactors.
4. **Flag breaking changes** — any commit touching public API, config, or schema
   gets a migration note (verify the migration actually runs).
5. **Write** the release-notes template (§4.5) in the user's language.
6. **Hand off**: bump the version + update the changelog, then route to
   `/tkdev-implement` for the ship lifecycle, or `/tkdev-deliver` if the release is
   part of delivery.

## Step 6: Self-check before you hand off

Run this gate on the finished doc. Fix anything that fails before routing.

| Check | Pass? |
|---|---|
| Every factual claim was verified against source/tests/behavior (Step 2) | ☐ |
| No claim contradicts the code; unverifiable claims were dropped | ☐ |
| Every heading delivers exactly what it promises (Step 3) | ☐ |
| Every endpoint/flag/command has one working, copy-pasteable example | ☐ |
| Docs are minimal — no redundant or unasked-for pages (Step 5) | ☐ |
| No marketing language (no hooks, no "engagement", no "audience", no social/video) | ☐ |
| No client identity fields, no global paths, no business jargon | ☐ |
| State written to `.tkdev/` only — no `~/.smtm`, no external keys | ☐ |
| All cross-references use `/tkdev-*` names | ☐ |

## Handoff

- Design decisions behind the docs → they came from `/tkdev-design`; if a decision
  is undocumented, write the ADR there first.
- Docs expose a code/behavior mismatch → route to `/tkdev-implement` to fix the
  code, or `/tkdev-debug` if it's a bug.
- Docs expose missing test coverage (a claim only a test proves) → route to
  `/tkdev-test`.
- A runbook/ops procedure needs wiring into alerts/CI → route to `/tkdev-ops`.
- A gotcha discovered while writing docs → log it with `/tkdev-learn` (category
  `docs`, `workflow`, or `decision`).

---

## Value Quantification — End-of-Skill Output (REQUIRED)

```markdown
---

### 📊 What this session was worth

- ⏱ **Time saved** — {e.g. the next developer onboards in 60s from the README instead of spelunking the code}
- ⚠️ **Risks avoided** — {2-3 named: stale/lying docs, a support ticket for an undocumented command, a re-litigated design decision}
- ✅ **What you got** — {the doc(s) written: README, ADR, API docs, changelog, runbook — each verified against the code}
- 🚧 **Without this skill** — {OPTIONAL, evidence-bound only}

💾 **Lock this in**: Run `/tkdev-save` to checkpoint.
🧭 **Not sure what's next?** `/tkdev` reads this session's conclusions and recommends the next move.
```

Then ONE yes/no handoff naming the concrete action:

> **Docs ready to ship?** Say yes and I'll route to `/tkdev-deliver` (a user
> manual is part of delivery) — or to `/tkdev-implement` if the docs surfaced a
> code change. Say no and I'll tighten whichever check failed.

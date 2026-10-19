---
name: tkdev-design
description: "Turn validated requirements into a concrete technical design — architecture, tech-stack selection, system design, data model, API design, and a design document with alternatives and tradeoffs. Runs a requirements deconstruction and risk audit before designing. Use when the user says 'design', 'architecture', 'system design', 'tech stack', 'API design', '架构', '技术方案', '数据模型', or has requirements ready to turn into a build plan."
---

# Tkdev Design — Architecture & Technical Design

You turn **validated requirements** into a **concrete technical design**: the
architecture, tech stack, system structure, data model, and API surface — with the
alternatives you considered and why you rejected them, written up as a design
document the next phase (`/tkdev-implement`) can build from without re-deciding
anything.

This skill sits between intake and build. It assumes the requirements are already
locked (scope, acceptance criteria, constraints). If they are not, hand back to
`/tkdev-intake` — do not design against a moving target.

## Standard Skill Startup (run before anything else)

Follow `/tkdev § Standard Skill Startup`, then load this skill's slices:

1. **Resolve the project** — single project, local to this directory; read
   `.tkdev/project.json` (see "Mode selection").
2. **Telemetry** — write `{"skill":"tkdev-design",…,"outcome":"started"}` to
   `.tkdev/analytics/skill-usage.jsonl` (PowerShell), then `completed` at the end.
3. **Auto-load learnings** — from `.tkdev/learnings.jsonl`, filter
   `confidence ≥ emerging`, surface categories: **`architecture`, `dependency`,
   `performance`, `security`**. Zero matches → silently skip.
4. **Auto-load project-local skills** — read `.tkdev/skills/`; one-line nudge once.
5. **Auto-load atoms** — from `$SUITE_ROOT/skills/tkdev/knowledge/atoms/`, slices
   **`architecture`**, **`maintainability`**, **`performance`** (e.g. `A-1001`
   ADR discipline, `A-1002` YAGNI, `A-1004` data-model-first, `A-1005` tradeoffs,
   `A-1402` tech-debt tracking, `A-1501` measure-before-optimizing). Cite by
   `A-{id}` when one informs a decision.

## Step 0: Language detection (don't ask — detect)

Detect from what the user wrote. Chinese → 中文；English → English. Pass it along:
`[Language: 中文]` / `[Language: English]`.

## Environment note (DSH + DeepSeek)

1. **Text-only, no vision.** All diagrams are **text diagrams** (ASCII component /
   data-flow / sequence sketches). Never depend on a screenshot or an image; verify
   structure by reading source and tracing data flow in text.
2. **flash model = weaker reasoning.** Small ordered steps, decision tables,
   fill-in templates. Prefer a verifiable action (read a file, run a command, grep)
   over long speculation.
3. **PowerShell, not bash.** Every shell snippet is `pwsh` on Windows.
4. **No external AI keys.** You are the model. No `ccapi.ai`, no vision API.

---

## Step 1: Input — what you need before designing

Pull from the intake output (or `.tkdev/requirements.md` if `/tkdev-intake`
already locked it). If any of these is missing or vague, route back to
`/tkdev-intake` with exactly what to clarify:

| # | Input | Source | Required? |
|---|-------|--------|-----------|
| 1 | Requirements recap (what the system does, who uses it) | `/tkdev-intake` | yes |
| 2 | Locked scope + acceptance criteria | `.tkdev/requirements.md` | yes |
| 3 | Constraints: time, budget, platform, existing stack | intake | yes |
| 4 | Delivery form (source / deployed / source+deploy+docs) | intake | yes |
| 5 | Existing codebase, if this is an iteration | repo + `.tkdev/project.json` | only for Mode B |
| 6 | Non-functional targets (perf, security, scale) | intake or defaults | no (fill with defaults) |

> **Rule**: requirements not locked → stop and send back to `/tkdev-intake`.
> Design decisions made on unconfirmed scope are rework.

## Step 2: Mode selection

Read `.tkdev/project.json` (create a minimal one if absent). This file holds
**project-level** state only — no client identity is tracked here.

```json
{
  "project": "zhangsan-inventory",
  "project_name": "库存管理系统",
  "project_type": "web-app | api | cli | app | infra | data-ml",
  "status": "intake | quoted | building | delivered | accepted | support | change",
  "quote": { "estimate_hours": 40, "status": "draft | sent | accepted" }
}
```

| Signal | Mode | What to do |
|--------|------|------------|
| No code yet, `status` is `intake`/`quoted` | **A: Fresh design** | Full design document from §4 onward |
| Existing code, `status` is `building`/`support`/`change` | **B: Iterate** | Read the code first, then do a delta design |
| Existing code but no design record | **B+**: backfill | Do §3, then write the design doc for what exists |

**Mode A — Fresh design**: greenfield. Produce the full Technical Design Document
(§4) from requirements alone.

**Mode B — Iterate on an existing codebase**: before designing, do a short
**read-first pass** (text only):

1. `grep`/`read` the entrypoint, package manifest, and module layout to map what
   exists (PowerShell: `Get-ChildItem -Recurse`, `Select-String`).
2. Identify what the change touches: new module, changed module, or rip-and-replace.
3. Produce a **delta design** — only the affected components/data/API, plus the
   migration steps to get from current state to target state (§4.7).

---

## Step 3: Requirements deconstruction & risk audit (BEFORE designing)

Run this audit and surface the results before writing the design. It catches the
defects that make a design collapse later.

### 3.1 Definition clarity

For every noun and verb in the requirements, check it has a concrete, testable
definition.

| Term | Is it unambiguous? | Concrete definition (fill in) |
|------|--------------------|-------------------------------|
| {e.g. "库存预警"} | yes/no | {threshold, trigger, action} |
| {…} | | |

- Any term with no agreed definition → ask ONE clarifying question, then continue.
- Any "quality" word ("快", "稳定", "易用") with no number → downgrade to an
  explicit assumption in §4.6.

### 3.2 Assumption audit

List every assumption you are about to build on, and mark it **safe / needs check**.

| # | Assumption | Risk if wrong | Safe / needs check |
|---|-----------|---------------|--------------------|
| 1 | {…} | {…} | {…} |

### 3.3 Causal logic check

For each requirement, state the causal chain: **input → processing → output**, and
flag where the chain is broken or implicit.

| Requirement | Input → Process → Output | Broken link? |
|-------------|--------------------------|--------------|
| {…} | {…} | {…} |

### 3.4 Decision readiness

Only proceed to §4 if **all four** hold:

- [ ] Definitions are concrete (3.1 has no "no" rows unresolved).
- [ ] Assumptions are listed and the risky ones flagged (3.2).
- [ ] Causal chains are complete (3.3 has no unresolved broken link).
- [ ] Constraints (time/budget/platform) are explicit.

Anything unchecked → fix in `/tkdev-intake` or resolve with the user before
designing.

---

## Step 4: The Technical Design Document

Write one document, in the user's language, with these 10 sections in order.
Keep it tight: a good design is **complete enough to build from, short enough to
re-read**. Use text diagrams — no images.

### 4.1 Problem & requirements recap

- One paragraph: what the system does and who uses it.
- A numbered list of the locked requirements (scope + acceptance criteria).
- The hard constraints (time, budget, platform, existing stack).
- Explicitly name what is **out of scope**.

```markdown
**Goal**: {one sentence}
**Users**: {who + what they do}
**Locked requirements**:
1. {…}
2. {…}
**Out of scope**: {…}
```

### 4.2 Alternatives considered (tradeoff matrix)

For each major decision (data store, framework, hosting, architecture style, API
style), show at least 2 alternatives and the one you chose. A design with no
rejected alternatives is a sketch, not a design (`A-1005`).

```markdown
**Decision D1: {e.g. data store}**

| Criterion | Option A: {…} | Option B: {…} | Option C: {…} |
|-----------|---------------|---------------|---------------|
| Build cost | {…} | {…} | {…} |
| Maintenance | {…} | {…} | {…} |
| Performance | {…} | {…} | {…} |
| Fit to constraints | {…} | {…} | {…} |
| Risk | {…} | {…} | {…} |
| **Chosen** | | | ✅ {A/B/C} |

**Why not the others**: {one line each}.
```

Prefer the simplest option that meets requirements (`A-1002`, YAGNI); add
abstraction only when a second concrete use case demands it.

### 4.3 Proposed architecture

- **Components**: name each component and its single responsibility (cohesion,
  `A-1003`).
- **Data flow**: a text diagram tracing one key request end-to-end.
- **Data model**: entities, fields, relationships, and **invariants** — model the
  data before the API (`A-1004`).

```markdown
**Components**
| Component | Responsibility | Tech | Depends on |
|-----------|----------------|------|------------|
| {…} | {…} | {…} | {…} |

**Data flow (text diagram)**
  User → [Web] → [API] → [Service] → [DB]
                          └→ [Queue] → [Worker] → [DB]

**Data model**
| Entity | Key fields | Relationships | Invariants |
|--------|-----------|---------------|------------|
| {…} | {…} | {…} | {e.g. "stock ≥ 0", "id unique"} |
```

### 4.4 API / interface design

For each surface (REST, gRPC, CLI flags, library functions), list the endpoints or
entry points with request/response/errors.

```markdown
**REST API (v1)**
| Method | Path | Request | Response | Errors |
|--------|------|---------|----------|--------|
| GET | /api/inventory | — | `[{id, sku, qty}]` | 401, 500 |
| POST | /api/inventory | `{sku, qty}` | `201 {id}` | 400, 409, 500 |
| … | | | | |
```

Include auth/authorization boundary, idempotency for writes, and versioning.

### 4.5 Tech stack & dependencies

```markdown
| Layer | Choice | Version | Why | Dependency risk |
|-------|--------|---------|-----|-----------------|
| Language | {…} | {…} | {…} | {…} |
| Framework | {…} | {…} | {…} | {…} |
| Data store | {…} | {…} | {…} | {…} |
| Hosting | {…} | {…} | {…} | {…} |
```

- Pin versions; name the **riskiest dependency** and its fallback.
- Record dependency decisions in the learnings log (`/tkdev-learn`, category
  `dependency`) if one surprised you.

### 4.6 Risks & mitigations

A risk register, seeded by the §3 audit. Each risk gets a mitigation and a trigger
that tells you when to act.

```markdown
| # | Risk | Likelihood | Impact | Mitigation | Trigger to act |
|---|------|-----------|--------|------------|----------------|
| 1 | {…} | high/med/low | high/med/low | {…} | {…} |
```

- Include the **riskiest assumption** from §3.2 explicitly.
- For security risks, mark the trust boundary and least-privilege posture.

### 4.7 Rollout / migration plan

How the design becomes reality without breaking what exists (or nothing, if greenfield).

```markdown
| Phase | What ships | Who/what it affects | Rollback |
|-------|-----------|---------------------|----------|
| 1 | {…} | {…} | {…} |
| 2 | {…} | {…} | {…} |
```

- Mode B: include a data migration step and a "keep old path working" step.
- Every phase names its rollback — if you can't roll it back, split it smaller.

### 4.8 Non-functional requirements

Give each NFR a **target** and a **text-based verification** (no vision).

| NFR | Target | How to verify (text) |
|-----|--------|----------------------|
| Performance | {e.g. p95 < 200ms on hot path} | {profiler output, load-test report} |
| Security | {e.g. no secrets in repo} | {grep, dependency scan, OWASP checklist} |
| Reliability | {e.g. idempotent writes} | {integration test, retry test} |
| Maintainability | {e.g. documented module boundaries} | {ADR present, lint clean} |
| Observability | {e.g. structured logs + metrics} | {log schema, metric names} |
| Accessibility | {e.g. keyboard-navigable} | {DOM/a11y checks in text} |

If the intake gave no targets, state the default and flag it as an assumption.

### 4.9 Open questions

Anything left intentionally undecided, with an owner and a deadline to decide.

| # | Question | Blocking? | Owner | Decide by |
|---|----------|-----------|-------|-----------|
| 1 | {…} | yes/no | {…} | {…} |

- Blocking questions → resolve before `/tkdev-implement`.
- Non-blocking → carry as a note, decide during build.

### 4.10 Next steps

- Hand off to `/tkdev-implement` with the design doc as the build contract.
- Recommend a review pass (`/tkdev-quality`) if the design has high-risk or
  security-sensitive choices.
- `💾 /tkdev-save` to checkpoint the design.

---

## Step 5: Self-check before you hand off

Run this gate on the finished design. Fix anything that fails before routing.

| Check | Pass? |
|-------|-------|
| Every requirement maps to a component and an acceptance criterion | ☐ |
| Every major decision has ≥2 alternatives and a "why not" (4.2) | ☐ |
| Data model precedes API, invariants stated (4.3) | ☐ |
| API lists request/response/errors, auth boundary named (4.4) | ☐ |
| Risk register includes the riskiest assumption (4.6) | ☐ |
| Every rollout phase has a rollback (4.7) | ☐ |
| NFRs have targets and text-based verification (4.8) | ☐ |
| No client identity fields, no global paths, no business jargon | ☐ |
| All cross-references use `/tkdev-*` names | ☐ |

---

## Value Quantification — End-of-Skill Output (REQUIRED)

```markdown
---

### 📊 What this session was worth

- ⏱ **Time saved** — {e.g. settled data-model + API shape before any code, so no rework}
- ⚠️ **Risks avoided** — {2-3 named: wrong data model, unpinned dependency, un-rollbackable migration}
- ✅ **What you got** — {a design doc: architecture, tradeoff matrix, data model, API, risk register}
- 🚧 **Without this skill** — {OPTIONAL, evidence-bound only}

💾 **Lock this in**: Run `/tkdev-save` to checkpoint the design.
🧭 **Not sure what's next?** `/tkdev` reads this session's conclusions and recommends the next move.
```

Then ONE yes/no handoff naming the concrete action:

> **Ready to build?** Say yes and I'll route to `/tkdev-implement` with this design
> as the build contract. Say no and I'll tighten whatever section feels shaky.

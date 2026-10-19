# Atoms — Engineering Knowledge Base

Atomic, reusable engineering principles that a tkdev-* skill can cite when
reasoning about a project. Each atom is one declarative principle, distilled from
battle-tested software practice.

## Why atoms?

Skills routinely re-derive the same conclusions every session: "measure before
optimizing," "make side effects idempotent," "one test asserts one behavior."
Atoms encode these so every skill run starts with that compounded judgement
instead of cold reasoning.

## Files

| File | Contents |
|---|---|
| `atoms.jsonl` | Full atom corpus (union of every category) |
| `atoms_architecture.jsonl` | Design docs, module boundaries, data modeling, tradeoffs |
| `atoms_testing.jsonl` | Test pyramid, determinism, regression tests, coverage |
| `atoms_reliability.jsonl` | Error handling, idempotency, timeouts, observability |
| `atoms_security.jsonl` | Trust boundaries, least privilege, secrets, CVEs |
| `atoms_maintainability.jsonl` | Readability, tech debt, conventions, refactoring |
| `atoms_performance.jsonl` | Profiling, N+1, hot paths, caching |
| `atoms_dev_workflow.jsonl` | Commits, review, CI gates, shipping, reproducers |
| `atoms_documentation.jsonl` | Accuracy, README, ADRs, examples, intent |

## Atom schema

```json
{
  "id": "A-1001",
  "captured_at": "ISO 8601",
  "source": "curated",
  "source_text": "One declarative sentence.",
  "source_created_at": "ISO 8601",
  "category": "architecture",
  "pattern": "One declarative sentence.",
  "confidence": "validated | emerging | hypothesis",
  "tags": ["1-3", "short", "keywords"],
  "distill_model": "tkdev-curated",
  "reason": "1-sentence rationale."
}
```

`confidence`:
- **validated** — widely accepted engineering practice
- **emerging** — strong practice, context-dependent
- **hypothesis** — speculative, untested

## How skills consume atoms

Every tkdev-* skill loads the relevant slice at startup (see Standard Skill
Startup in `skills/tkdev/SKILL.md`). Atoms are read-only; skills cite them by
`id` when an atom directly informs a recommendation, so any conclusion can be
traced back to its principle.

## Adding more atoms

Append a line to the relevant `atoms_<category>.jsonl` and to `atoms.jsonl`.
ID format `A-{4 hex chars}`. Atoms are append-only; to deprecate one, set
`confidence: "deprecated"` and add a `superseded_by` field — never delete
history.

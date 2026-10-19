---
name: tkdev-save
description: "Checkpoint the current project state to disk so future sessions can resume exactly where this one left off — decisions, ruled-out options, open questions, and the next skill. Use when the user says 'save this', 'checkpoint', '记下来', '存档', or has just reached a decision worth persisting."
---

# Tkdev Save — Project State Checkpoint

> **Standard startup**: before producing output, run the startup sequence per
> `/tkdev` § Standard Skill Startup (none — state managers don't consume learnings/atoms).

Your job is to take the conclusions reached in the current conversation and write
them to disk in a structured, recoverable format. Future sessions can
`/tkdev-restore` to pick up exactly where this one left off.

**You do not run diagnoses. You do not give engineering advice. You only persist
state.**

## Language

If the user's message carries a `[Language: ...]` tag, use it. Otherwise detect
the language from what the user wrote (Chinese → 中文; English → English) and
follow the conversation. Do NOT present a language menu.

---

## Why this exists

Tkdev's pipeline is supposed to operate like an engineering partner that knows
your project's context. But every new session is a cold start — last week's
`/tkdev-design` decisions, the approaches you ruled out, the hypotheses you're
still testing — all gone.

Saving turns a one-shot tool into a continuous development system. The state you
write here is the only thing that lets the next session skip the re-onboarding
ritual and continue real work.

---

## Triggers

| Command | Behavior |
|---|---|
| `/tkdev-save` | Save what's been decided in the current conversation. Title auto-extracted. |
| `/tkdev-save <title>` | Save with an explicit title, e.g. `/tkdev-save auth flow frozen` |
| `/tkdev-save list` | List all snapshots for the current project |
| `/tkdev-save list <project>` | List snapshots for a specific project |
| `/tkdev-save --slug <project>` | Save under a non-default project name |

**Natural-language equivalents** (any of these → run `/tkdev-save`):
- English: "save this", "checkpoint this", "lock it in", "snapshot before we continue"
- 中文: "保存", "存档", "记下来", "这个结论留着", "存一份"

---

## Project isolation

Every snapshot belongs to a **project**. A project separates one codebase from
another — what you decide for `MusicAPI` should never bleed into `KolFind`'s
debug history.

**Default project name**: `basename($(pwd))` with non-`[a-z0-9-]` characters
replaced by `-`. If the user runs `/tkdev-save` from `~/Dev/musicapi`, the
project becomes `musicapi`.

**Explicit override**: `--slug my-project`.

**Fallback**: if you're in `$HOME` or somewhere generic, the project is `default`.

In conversation, refer to it as **project** — never "slug" (that's the internal
identifier).

---

## Workflow

### Step 1 — Decide if there's anything worth saving

Before writing anything, scan the conversation for actual decisions. A snapshot
is not a journal entry — it's a record of judgments the user has confirmed.

Worth saving if the conversation contains any of:
- A technical decision the user accepted (architecture choice, API contract,
  data model, stack selection, dependency choice)
- An approach or design the user explicitly ruled out
- A hypothesis the user wants to test next iteration
- A clear "next-skill" handoff (e.g., "do `/tkdev-implement` next")
- A root cause from debugging that the user agreed with

**If nothing of substance happened**, refuse cleanly:

> Nothing to save yet — no decisions confirmed in this conversation. Run
> `/tkdev-intake`, `/tkdev-design`, `/tkdev-debug`, or another skill first,
> then come back.

Never write empty or filler snapshots.

### Step 2 — Extract or confirm a title

Pull a noun-phrase title from the conversation, ≤ 24 characters. Examples:
- `auth flow frozen`
- `ruled out serverless pivot`
- `minimal slice frozen`
- `根因是并发锁竞争`
- `从 REST 迁到 gRPC`

If the user gave an explicit title via `/tkdev-save <title>`, use theirs verbatim.

### Step 3 — Build the path

```
.tkdev/sessions/{YYYYMMDD-HHMMSS}-{title-slug}.md
```

- `.tkdev/` maps to `.tkdev\` on Windows.
- Timestamp: local time, format `20260503-141522`
- title-slug: lowercase, spaces → `-`, punctuation stripped, CJK characters preserved
- If a same-second collision somehow occurs, append a 4-char random suffix: `-a7k2`

Create the directory first if it doesn't exist (PowerShell):

```powershell
$sessions = Join-Path $PWD ".tkdev\sessions"
New-Item -ItemType Directory -Force $sessions | Out-Null
```

### Step 4 — Write the snapshot

YAML frontmatter + markdown body. Both fixed-format. Other skills will parse
this — do not improvise the schema.

```yaml
---
slug: {project}
timestamp: {ISO 8601 with timezone, e.g. 2026-05-03T14:23:15+08:00 — generate via `[DateTimeOffset]::Now.ToString("yyyy-MM-ddTHH:mm:sszzz")`. Never use the basic-format variant 20260503T142315+0800.}
title: {the title verbatim}
source_skill: {which tkdev-* skill produced the bulk of the conclusions in this session, e.g. tkdev-design. If multiple, comma-separated.}
status: {in-progress | resolved | abandoned}
next_skill: {recommended next skill name, or empty if not yet decided}
---

## Project state

{One paragraph. What is the current state of this project? What brought the user to /tkdev this conversation? Use the user's own framing where possible; do not abstract into generic strategy-speak.}

## Confirmed conclusions

- {Conclusion 1, one line. Includes architecture decisions, validated hypotheses, accepted root causes.}
- {Conclusion 2}
- ...

If a conclusion was reached in *this* conversation specifically (not inherited), prefix with `(new) `. If it was reaffirming a prior snapshot's conclusion, prefix with `(reaffirmed) `.

## Ruled out

- {Approach the user explicitly decided NOT to pursue, with one-line reason.}
- {e.g. "Won't go serverless — cold-start latency too high for this workload."}
- {If empty, write `(none yet)`.}

## Open hypotheses

- {Assumption that needs validation in the next iteration, with how it'll be tested.}
- {e.g. "Hypothesis: the read replica cuts p95 latency under load. Test: run a load test, compare p95 before/after."}
- {If empty, write `(none yet)`.}

## Next move

{One paragraph or a bullet. Which skill picks up from here? What action does the user take first?}

E.g. "Next: /tkdev-implement to build the slice. First action: scaffold the module and write the first failing test."

## Notes

{Anything else worth preserving — links, doc paths, edge-case considerations. Optional. If empty, write `(none)`.}
```

### Step 5 — Confirm to the user

Print a short confirmation in the user's detected language:

> ✅ Saved as `<title>` under project `<project>`.
> File: `.tkdev/sessions/<filename>.md`
>
> Resume next time with `/tkdev-restore` from this directory.

---

## List mode

`/tkdev-save list` and `/tkdev-save list <project>` enumerate snapshots:

```
musicapi (5 snapshots):
  1. 2026-05-03 14:23  auth flow frozen  (resolved, from tkdev-design)
  2. 2026-04-22 09:11  ruled out serverless pivot  (resolved, from tkdev-debug)
  3. 2026-04-15 16:40  minimal slice frozen  (in-progress, from tkdev-implement)
  ...
```

Sort by filename timestamp, newest first.

---

## Edge cases

- **No decisions yet** → Refuse cleanly per Step 1. Do not invent content.
- **Same project, same second** → Append 4-char random suffix.
- **Synced/shared sessions directory** → Do not rely on file `mtime`; sort
  exclusively by the `YYYYMMDD-HHMMSS` prefix in the filename.
- **User runs `/tkdev-save` from a freshly-cloned repo with no decisions** →
  Same as "no decisions yet" — refuse.
- **User-facing language** — match the user's detected language (see Language
  above). Map internal field names to user-friendly terms in conversation:
  `slug → project`, `source_skill → from`, `next_skill → next`.

---

## Principles

- **State, not narrative** — Snapshots are checkpoints, not journals. Bullet > paragraph.
- **User's words, not yours** — Quote the user's framing where possible. Do not
  paraphrase decisions into generic-speak.
- **Append-only** — Never overwrite an existing snapshot. Every save is a new file.
- **Cheap to write, expensive to lose** — Err on the side of saving when there is
  genuine substance. But never save filler.

---

## Value Quantification (Required After Each Successful Save)

After confirming the snapshot was written, append:

```markdown
---

### 📊 What this checkpoint is worth

- 💾 **Captured** — {N confirmed conclusions, M ruled-out directions, K open hypotheses}
- ⏱ **Saves you next time** — ~15-30 minutes of re-onboarding and re-explaining context to the agent
- ⚠️ **Risk avoided** — Re-deciding something you already decided — the most common way a project stalls. The agent doesn't remember between sessions unless you save
- 🔁 **Resume with** — `/tkdev-restore` from this directory in any future session
```

Use the actual counts from the snapshot. If only 1 conclusion was captured, the
value is real but smaller — show it honestly. Never inflate.

If the user has saved ≥3 snapshots in this project, append a second line:

> 💡 You now have {N} snapshots in `{project}`. Run `/tkdev-report` if you want a
> single deliverable merging them — useful for sharing with the team or for your
> own multi-sprint review.

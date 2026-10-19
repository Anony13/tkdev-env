---
name: tkdev-skillify
description: "Codify a successful workflow from the current conversation into a permanent project-local skill. Use when the user says 'codify this', 'save this workflow', '把这个流程固化', '存成技能', or a repeatable workflow just worked."
---

# Tkdev Skillify — Codify a Working Workflow Into a Reusable Skill

> **Standard startup**: before producing output, run the startup sequence per
> `/tkdev` § Standard Skill Startup (none — state managers don't consume learnings/atoms).

Most successful workflows are discovered once, executed by hand, and forgotten.
The next time you face the same problem, you re-discover it (or rebuild a worse
version). `/tkdev-skillify` solves this: it walks back through the most recent
successful workflow, distills the steps, and writes a project-local `SKILL.md`.

The output is a custom skill stored at
`.tkdev/skills/{name}/SKILL.md`. Future sessions in this project
can reference it.

**You do not execute the workflow yourself.** You distill one that already worked
into a reusable, re-invocable skill file. This is a **state manager** — it writes
project-local skills but does not consume learnings/atoms itself; every other
`tkdev-*` skill surfaces them.

> All shell commands below are PowerShell (`pwsh`) on Windows. State lives under
> `.tkdev\` (written as `.tkdev/` in prose).

## Language

If the user's message carries a `[Language: ...]` tag, use it. Otherwise detect
the language from what the user wrote (Chinese → 中文; English → English) and
follow the conversation. Do NOT present a language menu.

---

## Triggers

| Command | Behavior |
|---|---|
| `/tkdev-skillify` | Codify the most recent successful workflow in this conversation |
| `/tkdev-skillify <name>` | Same, with an explicit name for the new skill |
| `/tkdev-skillify list` | List all project-local skills in `.tkdev/skills/` |
| `/tkdev-skillify show <name>` | Print a project-local skill |

**Natural-language equivalents** (any of these → run `/tkdev-skillify`):
- English: "this worked, save it", "codify this", "turn this into a skill", "make this reusable", "save this workflow"
- 中文: "把这个流程固化", "存成技能", "把这个流程固化下来", "保存这个流程"

---

## What counts as "a successful workflow"

A workflow is `/tkdev-skillify`-eligible if all three are true:

1. The user explicitly confirmed it worked (clear signal: "this worked", "fixed
   it", "ship it", "much better than before", "我们就这么干")
2. There's a clear sequence of steps (not just a single insight — that's a
   `/tkdev-learn`, not a skill)
3. The pattern is reusable — it would help to do exactly the same thing again
   next time, in this project

Anti-patterns that should NOT be skillified:

- A one-off bug fix with no repeatable procedure
- A sequence tied to one specific commit or branch that won't recur
- A single observation more naturally captured as a learning
- A pattern already covered by an existing `tkdev-*` skill

---

## Workflow

### Step 1 — Identify the workflow

Walk back through the conversation. Find the most recent sequence where:

1. The user described or asked for something to be done
2. A series of steps was executed
3. The user confirmed satisfaction

Quote the user's confirmation back so they can verify which workflow you're about
to codify:

> I'm about to codify the workflow that produced "{quoted confirmation}". The
> steps as I understood them:
> 1. {step 1}
> 2. {step 2}
> ...
>
> Is this what you want to skillify? [y / edit / different workflow]

If the user wants a different workflow, ask which.

### Step 2 — Choose a name

Default: `{slug-of-the-workflow}` (e.g., `fix-flaky-ci`, `db-migration-playbook`,
`release-cut-checklist`).

If `/tkdev-skillify <name>` was given, use that. Else propose 1-3 candidate names
and ask the user to pick.

The skill name will become the file path:

```
.tkdev/skills/{name}/SKILL.md
```

### Step 3 — Distill the steps

Convert the workflow into a fixed format:

```markdown
---
name: {project-slug}-{name}
description: "{One-line summary of what this skill does, when to invoke. Auto-derived but user can edit.}"
project: {project slug}
captured_at: {ISO 8601}
captured_from: {conversation-summary | snapshot-id}
trigger: {natural-language phrase or /command pattern that invokes this}
---

# {Title}

## When to use

{1-2 sentences describing the trigger condition. Specific. "Cutting a release for the auth service" not "when releasing".}

## Inputs needed

- {Input 1, e.g., "The service/version to release"}
- {Input 2, e.g., "The changelog entries since the last tag"}
- ...

## Steps

1. {Step 1, including any specific commands, tools, or templates used}
2. {Step 2}
3. ...

## Success signal

How to know it worked. ("Pipeline green, zero flakes in 10 runs", "Migration applied with zero downtime", etc.)

## Failure mode + fallback

What goes wrong, and what to do instead. ("If the migration locks the table, switch to {alternative}")

## Variables / templates

If the workflow uses a template (e.g., a migration file skeleton or a runbook checklist), include the template literally. Mark variables in `{double-braces}`.

## Evidence this works

The original conversation context: who, what, when, what result. One paragraph.

## Limitations

When this skill should NOT be used. ("This works for Postgres; do not use for other databases.")
```

### Step 4 — Write to disk

Path: `.tkdev/skills/{name}/SKILL.md`.

Create the directory tree first (PowerShell):

```powershell
$skillsDir = Join-Path $PWD ".tkdev\skills\$name"
New-Item -ItemType Directory -Force $skillsDir | Out-Null
Set-Content -Path (Join-Path $skillsDir 'SKILL.md') -Value $content -Encoding UTF8
```

If a file already exists at that path, ask:

- Append a version number (e.g., `fix-flaky-ci-v2/`)?
- Overwrite?
- Cancel?

Default to "append a version" — preserves the prior skill in case the new one is
worse.

### Step 5 — Confirm + register

Print:

```
✅ Skill codified.

Path: .tkdev/skills/{name}/SKILL.md
Trigger: {trigger}

To re-run this skill in a future session:
1. Open a session in this project's directory
2. Type "{trigger}" or load the file directly: `read .tkdev/skills/{name}/SKILL.md`
3. The skill will execute the same steps with new inputs
```

Optionally suggest recording that the workflow was captured:

> Want to also log a learning? E.g., "{name} cut release errors by X" —
> `/tkdev-learn add`.

---

## Auto-loading project-local skills

Other `tkdev-*` skills should check `.tkdev/skills/` at startup.
If any project-local skills exist, surface them once per session:

> 📦 This project has 3 codified skills: `fix-flaky-ci`, `db-migration-playbook`,
> `release-cut-checklist`. Reference them by name or run `/tkdev-skillify list` to
> see all.

This is how your accumulated craft becomes part of every future session,
automatically.

---

## List mode

`/tkdev-skillify list`:

```
Project-local skills for `{project}`:

| Name | Captured | Trigger |
|---|---|---|
| fix-flaky-ci | 2026-04-22 | "CI keeps failing intermittently" |
| db-migration-playbook | 2026-04-15 | "run a schema migration" |
| ... | | |
```

`/tkdev-skillify show <name>`: print the file. Show the path at the top.

---

## Edge cases

- **No clear successful workflow in conversation** — Ask the user to describe the
  workflow and walk through Step 3 manually.
- **Workflow uses external tools the user doesn't have configured** — Note them in
  the `SKILL.md` as prerequisites; don't fail.
- **Workflow contains sensitive data** (credentials, tokens, internal URLs) —
  Strip them out, replace with `{variable}` placeholders, and confirm sanitization
  with the user.
- **Project-local skill duplicates an existing `tkdev-*` skill** — Warn: "This
  overlaps significantly with `/tkdev-docs`. Are you sure you want a project-local
  version, or should we update the existing skill's workflow instead?"

---

## Principles

- **Codify only proven patterns** — Failed or unconfirmed workflows get a
  `/tkdev-learn` entry, not a skill.
- **Specific over general** — A skill named `release-cut-for-auth-service` is more
  useful than `release-process`. Specificity drives retrieval and quality.
- **Sanitize before saving** — Project-local skills may end up in version control
  or shared. Strip secrets and PII as part of Step 3.
- **Versions, not overwrites** — `fix-flaky-ci/` then `fix-flaky-ci-v2/` then
  `fix-flaky-ci-v3/`. The progression is itself useful institutional memory.
- **Skill, not journal** — A skill encodes a procedure. A journal records what
  happened. If there's no procedure to encode, log a learning instead.

---

## Related skills

- `/tkdev-learn` — capture a single observation as a learning (skills are multi-step).
- `/tkdev-save` — checkpoint full session state.
- `/tkdev-restore` — resume saved state; project-local skills surface alongside it.
- `/tkdev` — the router that auto-surfaces project-local skills at the start of every other skill.

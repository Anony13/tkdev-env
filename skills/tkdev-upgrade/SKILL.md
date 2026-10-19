---
name: tkdev-upgrade
description: "Update the Tkdev skill suite to the latest version via git (git pull + reinstall). Use when the user says 'upgrade tkdev', 'update skills', '检查更新', '升级', or wants the latest suite."
---

# Tkdev Upgrade — Update the Suite via Git

> **Standard startup**: before producing output, run the startup sequence per
> `/tkdev` § Standard Skill Startup (none — state managers don't consume learnings/atoms).

Your job is to bring the installed Tkdev suite up to the latest commit from the
git remote, then reinstall the 26 skills so the on-disk copies match. One command
checks for updates, one command applies them, and one command re-copies the
skills. No manual file copying, no hand-rolled version comparison, no partial
installs.

**This is a state manager.** It updates the suite itself — it does not run
diagnoses, does not give engineering advice, and does not consume learnings or
atoms. Everything under `.tkdev/` (sessions, learnings, reports, telemetry) is
left untouched by an upgrade.

> All shell commands below are PowerShell (`pwsh`) on Windows. The suite updates
> via **git**, not npm. No external API keys are involved.

## Language

If the user's message carries a `[Language: ...]` tag, use it. Otherwise detect
the language from what the user wrote (Chinese → 中文; English → English) and
follow the conversation. Do NOT present a language menu.

---

## When to use

| Command / phrase | Behavior |
|---|---|
| `/tkdev-upgrade` (bare) | Show the version/commit delta, then ask before pulling |
| `/tkdev-upgrade --yes` / `--auto` / "just update it" / "直接升级" | Skip the confirmation, update now |
| "check for updates" / "检查更新" | Fetch and report the delta only — do **not** pull |

`/tkdev` runs its own throttled update check once per session (see the router's
"Auto-Update Check"). This skill is the explicit, on-demand upgrade.

## Environment

1. **PowerShell, not bash.** Every command below runs through `pwsh`.
2. **Git-based update.** The repo is a git clone. There is no npm version check.
3. **No vision, no external AI keys.** Updating is pure git + file copy; nothing
   here needs an image or a hosted model.
4. **`$SUITE_ROOT`** = the directory that contains this repo — the folder holding
   `skills/`, `install.js`, and `VERSION`. From the workspace root, that is
   `D:\桌面\letian_V2`. Resolve it from the working directory; set it explicitly
   if you're not already in the repo root.

## What this skill does

Run the workflow in order. All three phases are idempotent — re-running any of
them produces the same clean end state.

1. **Print current state** — read `VERSION` and the current git HEAD.
2. **Check for updates** — `git fetch` and compare local HEAD to upstream.
3. **Apply and reinstall** — `git pull` then `node install.js`, then show what changed.

## The full update command

The single command that applies an update and re-copies the skills:

```powershell
git -C $SUITE_ROOT pull
node install.js   # re-copies the 26 skills to their installed locations
```

`node install.js` is idempotent — it replaces each skill directory wholesale, so
there is no risk of a partial install.

---

## Workflow

### Step 1 — Print current state

```powershell
$current = (Get-Content "$SUITE_ROOT\VERSION" -Raw).Trim()
$head    = (git -C $SUITE_ROOT rev-parse --short HEAD).Trim()
$count   = (Get-ChildItem "$SUITE_ROOT\skills" -Directory).Count

"Current installation:"
"  Version : v$current"
"  Commit  : $head"
"  Location: $SUITE_ROOT"
"  Skills  : $count directories"
```

### Step 2 — Check for updates

```powershell
git -C $SUITE_ROOT fetch --quiet
$local  = (git -C $SUITE_ROOT rev-parse HEAD).Trim()
$remote = (git -C $SUITE_ROOT rev-parse '@{u}').Trim()

if ($local -eq $remote) {
  "Already on the latest commit ($head). Nothing to update."
} else {
  $behind = (git -C $SUITE_ROOT rev-list --count "HEAD..@{u}").Trim()
  "$behind commit(s) behind upstream."
}
```

If `$local -eq $remote`, stop here with a clean "already latest" message. If the
user only asked to *check* ("检查更新"), also stop here — report the delta and
offer to proceed.

### Step 3 — Pull and reinstall

```powershell
git -C $SUITE_ROOT pull
node install.js
```

`git pull` fast-forwards to the latest commit; `node install.js` re-copies all 26
skill directories. After it returns, verify success:

- `VERSION` now reflects the new release (re-read it).
- `git -C $SUITE_ROOT status` is clean.
- `(Get-ChildItem "$SUITE_ROOT\skills" -Directory).Count` still equals the
  expected skill count (26).

### Step 4 — Show what changed

Read the changelog, not the raw commit log, for behavior changes:

```powershell
Get-Content "$SUITE_ROOT\CHANGELOG.md" -TotalCount 80
```

If `CHANGELOG.md` has no relevant entry, fall back to the commit list since the
old HEAD:

```powershell
git -C $SUITE_ROOT log --oneline <old-commit>..HEAD
```

Present the highlights in 5–10 bullets, not the full diff.

### Step 5 — Report the result

```
✅ Updated to v{new} (commit {new-head}).

The project copy at $SUITE_ROOT/skills/ is already live — the next /tkdev-*
invocation reads the new files. node install.js refreshed the installed copies
for Claude Code / Codex / Gemini.

What's new in this version:
- [bullet 1]
- [bullet 2]
- ...

Run /tkdev to start using the updated suite.
```

---

## Manual fallback

If the update fails, read the error message and surface **one** specific reason —
not a wall of generic recovery options.

| Failure | Diagnostic | Response |
|---|---|---|
| `git: command not found` | Git not installed | "Install Git from git-scm.org first, then re-run `/tkdev-upgrade`." |
| `fatal: unable to access ...` | Network unreachable or remote down | "Can't reach the remote. Check your network / VPN, then re-run." |
| `error: Your local changes would be overwritten` | Uncommitted local edits | "You have uncommitted changes in the repo. Commit or `git stash` them first, then re-run." |
| `CONFLICT (content): ...` | Merge conflict during pull | "A merge conflict occurred. Resolve it manually, then run `node install.js`." |
| `node: command not found` | Node.js not installed | "Install Node.js from nodejs.org first — `node install.js` needs it." |

## Rollback

The updater does **not** auto-rollback — a failed or regressed update leaves the
repo where it ended. To go back to a previous commit explicitly:

```powershell
# 1. Find the previous commit on the current branch
git -C $SUITE_ROOT log --oneline -20

# 2. Reset to that commit, then reinstall
git -C $SUITE_ROOT reset --hard <previous-commit>
node install.js
```

`reset --hard` discards uncommitted changes — use it only when you want a clean
return to a known-good commit. On a branch you share with others, prefer
`git revert <bad-commit>` instead.

---

## When to auto-update vs ask first

Default: **ask before updating.** Show the delta first, then let the user confirm.

```
Current: v{current} (commit {head})
Latest:  v{new} (commit {new-head})  ← {N} commits behind

New since v{current}:
- [bullet 1]
- [bullet 2]
- ...

Proceed with update? [y/n]
```

**Skip the confirmation** only if the user explicitly said `--yes`, `--auto`,
"just update it", or "直接升级" in their message.

---

## Principles

- **One command, one outcome** — the update is `git pull` + `node install.js`,
  not a stack of shell snippets to copy.
- **Show the delta before changing anything** — commit range + headline changelog
  bullets, not full diffs.
- **Don't auto-rollback** — a failed update surfaces as a failure; rollback is an
  explicit user action.
- **Read the CHANGELOG, not the commit log** — users care about behavior changes,
  not implementation churn.
- **Reinstall is idempotent** — `node install.js` replaces skill directories
  wholesale, so partial installs can't happen.
- **State is untouched** — `.tkdev/` sessions, learnings, reports, and telemetry
  survive any upgrade.

---

## Value Quantification (Required at End of Output)

```markdown
---

### 📊 What this update was worth

- ⏱ **Time saved** — ~10-15 minutes vs the manual path (compare versions, back up,
  copy 26 skill directories, verify, read the changelog)
- ⚠️ **Risks avoided** — (1) a partial install where some skills update and others
  don't; (2) running old skills against new docs/atoms after a rename, producing
  inconsistent behavior; (3) missing a breaking change because the changelog was
  never read
- ✅ **What you got** — the suite moved from v{current} → v{new}, the relevant
  CHANGELOG bullets, and a clean reinstall of all 26 skills
- 🚧 **Without this skill** — the suite silently drifts out of date, cross-references
  break after renames, and mystery bugs surface that turn out to be "you're on an
  old version"

💾 **Lock this in**: Run `/tkdev-save` to checkpoint these conclusions.
🧭 **Not sure what's next?** `/tkdev` reads this session's conclusions and recommends the next move.
```

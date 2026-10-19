# Tkdev — project instructions

This workspace hosts **Tkdev** (`tk` = the user's name "tyking"): a
**custom-software-development & delivery** skill suite adapted from **Show Me The
Money** v2.8.0 (`https://github.com/iamzifei/show-me-the-money`, CC BY-NC 4.0).
The adaptation design is documented in `ADAPTATION.md`.

The suite models this engagement lifecycle: **接单（需求澄清+报价）→ 开发 → 交付+验收
→ 售后修复 → 变更二次交付**.

The suite is 19 `SKILL.md` workflows. It is not a web app or a service — there is
nothing to compile or host. "Using" it means reading the right `SKILL.md` and
following its procedure.

## Where the skills live

The suite is **project-local only** — skills live in `./skills/<name>/SKILL.md`
inside this project's directory. There is **no global install** (do NOT run
`node install.js`, which copies to `~/.claude/skills/`). To use the suite in a
new project, copy `skills/`, `.claude-plugin/`, and `AGENTS.md` into it (see
"New-project bootstrap" below).

## How to invoke a skill here

DeepSeek Harness does not register skills as native tools, so these workflows do
not appear in the `skill` tool catalog. Invoke them by reading the file from this
project's `./skills/` directory:

> When the user types `/tkdev` or `/tkdev-<name>`, or describes a task the table
> below matches, **read `./skills/<name>/SKILL.md` and follow it** as if loaded
> through the `skill` tool.

Do not paraphrase from memory. Read the file, then execute its workflow. If a
skill references another skill, read that file too.

## Environment constraints (always apply)

- **No vision** (DeepSeek pro is text-only): verify UI/visual behavior through
  text — read source, `grep`, run tests, parse HTML/DOM, read logs, run headless
  commands. Never depend on a screenshot.
- **flash model** = weaker reasoning: prefer small, ordered, checklist steps with
  decision tables; prefer verifiable actions (run a command, read a file, run a
  test) over long speculation.
- **PowerShell, not bash**: every shell command is `pwsh` on Windows.
- **No external AI keys**: no `ccapi.ai`, no image/vision API. You are the model.
- **State dir**: `.tkdev/` — project-local (gitignored): project state,
  sessions, learnings, reports, analytics. Everything stays local.

## The engagement lifecycle & routing

| User says | Read this skill | What it does |
|---|---|---|
| `/tkdev`, "tkdev", "接单", "开发", "what's next", "下一步" | `skills/tkdev/SKILL.md` | Entry point: routing, project state, post-task navigation |
| `/tkdev tutorial`, `/tkdev 新手`, `/tkdev 教程` | `skills/tkdev/SKILL.md` | Zero-input guided tutorial |
| "客户要做", "接单", "报价", "新项目", "需求", "客户想要", "估个价" | `skills/tkdev-intake/SKILL.md` | Requirements clarification + scope lock + estimate + quote |
| "design", "architecture", "system design", "API design", "架构", "技术方案", "数据模型" | `skills/tkdev-design/SKILL.md` | Architecture & technical design (ADRs) |
| "build", "implement", "ship", "写代码", "实现", "开发这个", "部署", "上线" | `skills/tkdev-implement/SKILL.md` | Implementation + ship lifecycle |
| "write tests", "test coverage", "TDD", "写测试", "补测试", "单测" | `skills/tkdev-test/SKILL.md` | Testing strategy & test authoring |
| "review my code", "is this ready to ship", "security", "代码审查", "上线前检查" | `skills/tkdev-quality/SKILL.md` | Code review / QA / security / performance gates |
| "broken", "500", "fails", "crash", "debug", "报错", "排查", "定位 bug" | `skills/tkdev-debug/SKILL.md` | Root-cause debugging |
| "docs", "README", "user manual", "document", "changelog", "写文档", "用户手册" | `skills/tkdev-docs/SKILL.md` | Technical writing & user documentation |
| "CI", "CD", "deploy", "monitor", "automate", "pipeline", "监控", "告警" | `skills/tkdev-ops/SKILL.md` | CI/CD, deployment, monitoring |
| "交付", "验收", "部署给客户", "交接", "deliver", "acceptance" | `skills/tkdev-deliver/SKILL.md` | Delivery checklist + handoff + acceptance sign-off |
| "客户报障", "出问题了", "报错", "修复", "bug", "坏了", "support" | `skills/tkdev-support/SKILL.md` | Client bug → reproduce → fix → follow up |
| "客户要改", "新增需求", "修改", "变更", "加个功能", "change" | `skills/tkdev-change/SKILL.md` | Change request → impact → quote → implement → re-deliver |
| "save this", "checkpoint", "保存", "存档", "记下来" | `skills/tkdev-save/SKILL.md` | Checkpoint project state |
| "continue from last time", "resume", "接着上次", "续上" | `skills/tkdev-restore/SKILL.md` | Resume saved state |
| "package this up", "make a report", "出报告", "打包" | `skills/tkdev-report/SKILL.md` | Merge snapshots into a deliverable |
| "remember this", "log a learning", "记住这个", "这是个坑" | `skills/tkdev-learn/SKILL.md` | Project learnings / gotchas |
| "retro", "复盘", "本周回顾", "what did we ship" | `skills/tkdev-retro/SKILL.md` | Engagement / sprint retrospective |
| "codify this", "save this workflow", "固化流程", "存成技能" | `skills/tkdev-skillify/SKILL.md` | Codify a workflow into a skill |
| "upgrade tkdev", "update skills", "检查更新", "升级" | `skills/tkdev-upgrade/SKILL.md` | Update the suite (git) |

## Operating conventions the skills rely on

- **Project context** — this suite runs on ONE project at a time (the directory
  it lives in). `.tkdev/project.json` holds the project, quote, and status
  (`intake → quoted → building → delivered → accepted → support/change → done`).
- **State directory** `.tkdev/`: `project.json`, `requirements.md`, `delivery.md`,
  `learnings.jsonl`, `skills/`, `sessions/`, `reports/`, `analytics/`. All
  project-local (gitignored).
- **Standard startup**: most skills run the sequence in
  `skills/tkdev/SKILL.md` § "Standard Skill Startup" (project → telemetry →
  learnings → project-local skills → atoms → AOCI cognition). Read that section
  before running a sub-skill.
- **Atoms** (engineering principles) live at `./skills/tkdev/knowledge/atoms/`.
- **Language**: reply in the user's language (this project's user writes
  Chinese). The skills' English text is the procedure, not the output language.
- **Licensing**: upstream is CC BY-NC 4.0; do not raise it in personal/internal
  sessions. Surface `COMMERCIAL-LICENSE.md` once, only if the user says they are
  embedding the suite in a paid product, redistributing it, or removing
  attribution.

## New-project bootstrap (tkdev + aoci)

The environment ships as a self-contained bundle:
**`D:\桌面\letian_V2\dist\tkdev-aoci-bundle.zip`** — contains `skills/`,
`.claude-plugin/`, `AGENTS.md`, `docs/`, and `deploy.ps1`.

To start a NEW project:
1. Copy the bundle zip into the new project directory.
2. In a DSH session there, say:

   > **「将这个包解压并部署到本项目」** — or `/tkdev-init` / "解压并部署" / "部署 tkdev+aoci"

   The agent extracts the zip into **`.tkdev-env\`**, then runs
   `.tkdev-env\deploy.ps1` (gitignores `.tkdev-env\`, runs aoci `init` + `scan`
   on the project root, and appends the DSH MCP config). The project root stays
   clean — the environment is separated into a gitignored subfolder.

3. Restart DSH → tell the agent 「请为这个项目建立 AOCI 索引」.

Manual equivalent (if the agent needs the exact steps):

```powershell
Expand-Archive .\tkdev-aoci-bundle.zip -DestinationPath .\.tkdev-env -Force
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\.tkdev-env\deploy.ps1 -Target .
```

Full guide: `.tkdev-env\docs\aoci-environment.md`.

## Updating

```powershell
git pull
```

The suite is project-local; `git pull` is the only update step. Do **NOT** run
`node install.js` — it copies to the global `~/.claude/skills/`, which is not how
this suite is deployed. After `git pull`, re-package the bundle so new projects
get the latest suite (recreate `dist/tkdev-aoci-bundle.zip` from `skills/`,
`.claude-plugin/`, `AGENTS.md`, `docs/`, and `scripts/deploy.ps1`).

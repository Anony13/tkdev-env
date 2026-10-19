# Tkdev Adaptation Spec

Tkdev (`tk` = the user's name "tyking") is a **custom-software-development &
delivery** skill suite, adapted from **Show Me The Money** v2.8.0 (a 25-skill
*business automation* suite). It models this engagement lifecycle:

```
① 接单 intake   客户需求澄清 + 范围锁定 + 工时估算 + 报价 + 确认
② 开发 build    技术方案 → 实现 → 测试 → 质量 → 调试 → 文档 → 部署
③ 交付 deliver  交付物清单 + 部署交接 + 验收单 + 用户手册 + 客户验收
④ 售后 support  客户报障 → 复现 → 定位 → 修复 → 回归 → 回访
⑤ 变更 change   新增/修改需求 → 影响评估 → 报价 → 实现 → 二次交付
   （贯穿）     多客户、多项目，每个客户有独立档案/报价/交付/问题记录
```

It runs on **DSH + DeepSeek** in this Windows workspace (`D:\桌面\letian_V2`).

---

## 1. Final skill map (19 skills)

| # | Skill | Purpose |
|---|---|---|
| 1 | `tkdev` | Router: routing, client archive, post-task navigation, tutorial |
| 2 | `tkdev-intake` | Requirements clarification + scope lock + estimate + quote |
| 3 | `tkdev-design` | Architecture, data model, API design, ADR |
| 4 | `tkdev-implement` | Implementation + ship lifecycle (version/changelog/deploy/rollback) |
| 5 | `tkdev-test` | Testing strategy & authoring, TDD, coverage, flaky triage |
| 6 | `tkdev-quality` | Code review, QA, OWASP+STRIDE security, performance, a11y |
| 7 | `tkdev-debug` | Root-cause debugging (boundary isolation, minimal repro) |
| 8 | `tkdev-docs` | README, user manual, API docs, changelog, runbooks |
| 9 | `tkdev-ops` | CI/CD, deployment, monitoring, on-call |
| 10 | `tkdev-deliver` | Delivery checklist + handoff + acceptance sign-off |
| 11 | `tkdev-support` | Client bug → reproduce → fix → follow up + ticket log |
| 12 | `tkdev-change` | Change request → impact → quote → implement → re-deliver |
| 13 | `tkdev-save` | Checkpoint project state |
| 14 | `tkdev-restore` | Resume saved state |
| 15 | `tkdev-report` | Merge snapshots into a deliverable |
| 16 | `tkdev-learn` | Project learnings / gotchas |
| 17 | `tkdev-retro` | Engagement / sprint retrospective |
| 18 | `tkdev-skillify` | Codify a workflow into a skill |
| 19 | `tkdev-upgrade` | Update the suite (git) |

### What changed from the original 25

- **Deleted 9** (no place in a custom-dev delivery business):
  - business-only: `money-discover` (ideation), `money-strategy` (market research),
    `money-diagnose` (business diagnosis), `money-content` (marketing),
    `money-finance` (revenue), `money-outreach` (cold email), `money-social` (social),
    `money-seo` (SEO), `money-ads` (ads).
  - their dev analogs were partially kept then re-scoped: `money-product`→implement,
    `money-quality`→quality (kept), `money-ops`→ops (kept).
- **Kept & re-scoped 13**: router, implement, quality, test(new), ops, docs(new from
  content), debug(new from diagnose), design(new from strategy), save, restore,
  report, learn, retro, skillify, upgrade.
- **Added 4** for the delivery business: intake, deliver, support, change.

---

## 2. Environment rules (DSH + DeepSeek)

1. **No vision** (pro is text-only): verify UI/visual behavior through text —
   source, `grep`, tests, DOM/HTML, logs, headless commands. Never a screenshot.
2. **flash model = weaker reasoning**: small, ordered, checklist steps; decision
   tables; fill-in templates; prefer verifiable actions over long inference.
3. **PowerShell, not bash**: `pwsh` on Windows; `$env:USERPROFILE` for `~`.
4. **No external AI keys**: no `ccapi.ai`, no image/vision API. The agent is the model.
5. **Skills are read on demand**: DSH has no `~/.claude/skills` catalog; skills are
   `SKILL.md` files routed by `AGENTS.md`.
6. **Update via git**: `git pull` + `node install.js`.

---

## 3. Client archive model

This suite runs on ONE project at a time (the directory it lives in). Client
info and project state live in the project-local `.tkdev/` directory:

- `.tkdev/project.json` — project, quote, status
- `.tkdev/requirements.md` — locked scope + acceptance criteria
- `.tkdev/delivery.md` — handoff summary
- `.tkdev/learnings.jsonl` — gotchas/patterns
- `.tkdev/skills/` — project-local skills (via `/tkdev-skillify`)
- `.tkdev/sessions/` — checkpoints (via `/tkdev-save`)
- `.tkdev/reports/` — deliverables (via `/tkdev-report`)
- `.tkdev/analytics/skill-usage.jsonl` — telemetry

Status lifecycle: `intake → quoted → building → delivered → accepted → (support | change → … → delivered) → done`.

Learnings categories: `architecture, bug, performance, security, reliability,
dependency, testing, docs, workflow, decision, client, cost`.

---

## 4. Global skill conventions

- **Front matter**: `name` == directory name + a `description` with EN+中文 trigger
  phrases, no business/money jargon.
- **Title**: `# Tkdev <Name> — <subtitle>`.
- **Startup note**: references `/tkdev § Standard Skill Startup` with this skill's
  learnings/atoms categories.
- **Language**: detect, don't ask (Chinese → 中文; English → English).
- **Value Quantification** end block, dev/delivery-reframed; CTA `/tkdev-save`.
- **Atoms** (engineering principles) at `$SUITE_ROOT/skills/tkdev/knowledge/atoms/`
  — categories: architecture, testing, reliability, security, maintainability,
  performance, dev_workflow, documentation (40 atoms).

---

## 5. Validation

- 19 directories in `skills/`, each `name:` matches.
- No dangling `/tkdev-*` cross-references; no references to deleted skills.
- No business jargon in active skills (attribution + "no ccapi.ai" + "business
  rules"/"custom-software business" are the only intentional occurrences).
- `AGENTS.md` routing table lists all 19 skills.
- `node install.js` installs 19 skills to `~/.claude/skills/`.

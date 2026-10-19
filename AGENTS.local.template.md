# TKDEV — 本项目开发流程（本地叠加层，勿提交 / machine-local, do not commit）

本项目使用 **tkdev** 软件开发流程套件，技能文件位于 `.tkdev-env\skills\` 下。
**任何开发 / 变更 / 售后 / 交付任务都必须走 tkdev 技能流程，禁止「直接定位代码就改」的裸改。**

## 如何调用

当用户输入 `/tkdev`、`/tkdev-<name>`，或描述的任务命中下表时，**读取
`.tkdev-env\skills\<name>\SKILL.md` 并严格照做**（等同于通过 skill 工具加载）。
不要凭记忆复述；先读文件再执行。技能引用了其它技能时，也要读那个文件。

## 任务路由表

| 用户说 | 读这个技能 | 干什么 |
|---|---|---|
| `/tkdev`、"tkdev"、"接单"、"开发"、"下一步"、"what's next" | `.tkdev-env\skills\tkdev\SKILL.md` | 入口：路由、项目状态、任务后导航 |
| "客户要做"、"接单"、"报价"、"需求"、"客户想要"、"估个价" | `.tkdev-env\skills\tkdev-intake\SKILL.md` | 需求澄清 + 范围锁定 + 报价 |
| "设计"、"架构"、"技术方案"、"数据模型" | `.tkdev-env\skills\tkdev-design\SKILL.md` | 架构 / 技术设计 |
| "实现"、"写代码"、"开发这个"、"部署"、"上线"、"build" | `.tkdev-env\skills\tkdev-implement\SKILL.md` | 实现 + 上线 |
| "写测试"、"补测试"、"单测"、"test" | `.tkdev-env\skills\tkdev-test\SKILL.md` | 测试 |
| "代码审查"、"上线前检查"、"安全"、"review" | `.tkdev-env\skills\tkdev-quality\SKILL.md` | 审查 / QA / 安全 |
| "报错"、"排查"、"定位 bug"、"debug"、"崩溃" | `.tkdev-env\skills\tkdev-debug\SKILL.md` | 根因排查 |
| "写文档"、"用户手册"、"README"、"document" | `.tkdev-env\skills\tkdev-docs\SKILL.md` | 文档 |
| "CI/CD"、"监控"、"告警"、"deploy" | `.tkdev-env\skills\tkdev-ops\SKILL.md` | 部署 / 监控 |
| "交付"、"验收"、"部署给客户"、"交接"、"deliver" | `.tkdev-env\skills\tkdev-deliver\SKILL.md` | 交付 + 验收 |
| "客户报障"、"出问题了"、"修复"、"坏了"、"support" | `.tkdev-env\skills\tkdev-support\SKILL.md` | 售后修复 |
| "客户要改"、"新增需求"、"修改"、"变更"、"加个功能"、"change" | `.tkdev-env\skills\tkdev-change\SKILL.md` | 变更 → 影响 → 报价 → 实现 → 再交付 |
| "保存"、"存档"、"checkpoint" | `.tkdev-env\skills\tkdev-save\SKILL.md` | 存档项目状态 |
| "接着上次"、"续上"、"resume" | `.tkdev-env\skills\tkdev-restore\SKILL.md` | 恢复状态 |
| "出报告"、"打包"、"report" | `.tkdev-env\skills\tkdev-report\SKILL.md` | 出报告 |
| "记住这个"、"这是个坑"、"learning" | `.tkdev-env\skills\tkdev-learn\SKILL.md` | 记经验 |
| "复盘"、"回顾"、"retro" | `.tkdev-env\skills\tkdev-retro\SKILL.md` | 复盘 |
| "固化流程"、"存成技能" | `.tkdev-env\skills\tkdev-skillify\SKILL.md` | 固化技能 |
| "升级"、"检查更新" | `.tkdev-env\skills\tkdev-upgrade\SKILL.md` | 更新套件 |

## 关键约定

- **标准启动**：大多数技能先执行 `.tkdev-env\skills\tkdev\SKILL.md` 的
  "Standard Skill Startup"（项目 → 遥测 → 经验 → 项目技能 → 原子 → AOCI 认知）。
- **AOCI 认知地图**：本项目已建 AOCI 索引。改代码前用
  `aoci_cognition action="overview"`（或读 `aoci.txt` / `aoci.code.txt`）拿全局认知；
  改完用 `aoci_cognition action="maintain"` + `aoci_verify` / `aoci_check` 重对齐。
- **状态目录**：`.tkdev\`（项目内、gitignored）。
- **语言**：用中文回复（技能英文文本是流程，不是输出语言）。

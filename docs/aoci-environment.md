# AOCI + tkdev 环境使用说明

tkdev（软件开发流程）+ aoci（代码认知地图）开发环境。环境与项目**物理分离**：环境在每个项目的 `.tkdev-env\` 子目录里（gitignored），项目代码在工作区根目录，互不干扰。

## 0. 已就绪的东西

| 项 | 位置 |
|---|---|
| aoci 二进制 | `C:\aoci\bin\aoci.exe`（v0.1.0-rc21，SHA-256 已校验） |
| 部署包 | `D:\桌面\letian_V2\dist\tkdev-aoci-bundle.zip` |
| 本地指针 | `AGENTS.local.md`（deploy 自动创建，项目本地、gitignored，不污染全局） |
| tkdev 母版 | `D:\桌面\letian_V2\`（`skills\` 在根，用于升级环境/重新打包） |

## 1. 新项目部署（复制包 → 解压到 .tkdev-env → 部署）

**第 1 步**：把 `tkdev-aoci-bundle.zip` 复制到新项目根目录。

**第 2 步**：在新项目的 DSH 会话里说：

> **「将这个包解压并部署到本项目」** — 或 `/tkdev-init` / 「解压并部署」/「部署 tkdev+aoci」

Agent 会做两件事：
1. **解压**到 `.tkdev-env\`（环境：skills/、AGENTS.md、deploy.ps1、docs/、.claude-plugin/）；
2. **部署**：运行 `.tkdev-env\deploy.ps1` → 自动把 `.tkdev-env\` 加进 `.gitignore` → aoci init + scan（项目根）→ 追加 DSH MCP 配置。

手动等价命令：

```powershell
Expand-Archive .\tkdev-aoci-bundle.zip -DestinationPath .\.tkdev-env -Force
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\.tkdev-env\deploy.ps1 -Target .
```

> 前置：项目目录需先 `git init`（aoci 要求 git 仓库）。deploy 是**自愈 + 幂等**的：新机自动下载 aoci.exe，重复运行全程跳过。

## 2. 目录结构（环境 vs 项目，各在其位）

```
项目工作区（= DSH 打开这里）
├── 客户代码 + .git                          ← 项目（交付物）
├── aoci.txt / aoci.code.txt / .aoci\        ← 项目自己的「代码地图」
├── AGENTS.md                                ← 项目约定（客户/项目自己的，环境不碰）
├── AGENTS.local.md                          ← 本地指针（deploy 创建，gitignored，不污染全局）
├── .gitignore                               ← 含 .tkdev-env/ 和 AGENTS.local.md
└── .tkdev-env\                              ← 环境（隐藏、gitignored、交付自动排除）
    ├── skills\                              ← tkdev 19 个技能
    ├── AGENTS.md                            ← tkdev 路由（Agent 读技能时自动加载）
    ├── deploy.ps1
    └── docs\
```

## 3. 接进 DSH 的 MCP + 建索引

deploy.ps1 已自动把 MCP 配置追加进 `~\.dsh\profiles\desktop\cordis.patch.yml`。你只需：

1. **重启 DSH**（加载 `mcp__aoci__*` 工具）；
2. 对 Agent 说「请为这个项目建立 AOCI 索引」（首次约 1 小时/20 万行，之后增量自动维护）。

## 4. 日常开发（tkdev 驱动 + aoci 自动给全局视野）

- 说 `/tkdev` 或描述「接单/开发/交付/售后/变更」→ Agent 读 `.tkdev-env\` 里的技能执行；
- 改代码时 aoci 自动在收尾重对齐地图（已做成 implement/support/change 的硬检查项）；
- 全程显式提示：会明示「走哪个技能」「调了哪个 aoci 工具」「地图更新几条」。

## 5. 常用命令

```powershell
$aoci = "C:\aoci\bin\aoci.exe"
& $aoci --repo <项目路径> verify          # 报告 Missing/Orphan/Stale 漂移
& $aoci --repo <项目路径> check           # 聚合治理门禁
& $aoci --repo <项目路径> ui --open       # 本机只读面板
& $aoci --version                          # 应为 0.1.0-rc21
```

## 6. 已知边界

- 方案 A 是**静态单仓库绑定**：每新接一个项目要加一条 MCP 配置 + 重启 DSH（多项目频繁切换会稍麻烦）。
- 环境每项目一份（你要的自包含）；升级环境 = 改母版 `D:\桌面\letian_V2\` 后重新打包 + 对老项目重新解压 `.tkdev-env\`。
- 索引是「地图/先验」，不替代改代码前读真实源码。
- AOCI-CODE 本身 FSL-1.1-MIT；本机自用不涉及分发。

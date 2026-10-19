# tkdev-env

「tkdev + aoci」开发环境 —— 一套给 AI Agent 用的**软件开发流程 + 代码认知地图**工具，托管在 GitHub 上做版本管理。

- **tkdev**：19 个软件开发流程技能（接单 → 设计 → 开发 → 测试 → 质量 → 交付 → 售后 → 变更）。
- **aoci**：代码认知地图（给 Agent 提供「改代码前的全局视野」，随代码增量维护）。
- **dsh-aoci**：AOCI 的 DSH 动态 MCP 插件（vendor 在本仓库，避免上游删库）。

## 一条命令部署

在 DSH 会话里说：

> **「帮我部署 tkdev-env」**（新机器第一次建议说全：`帮我部署 github.com/<你的用户名>/tkdev-env`）

Agent 会：`git clone/pull` 本仓库 → 装 aoci.exe + dsh-aoci 插件（若缺）→ 把 tkdev 技能部署到当前项目。

### 手动等价命令

```powershell
# 1. 拉取仓库（首次 clone，之后 pull）
git clone https://github.com/<你的用户名>/tkdev-env.git C:\tkdev-env

# 2. 机器级引导（装 aoci.exe + dsh-aoci 插件，一次）
powershell -NoProfile -ExecutionPolicy Bypass -File C:\tkdev-env\scripts\bootstrap.ps1

# 3. 项目级部署（复制 tkdev 技能到当前项目的 .tkdev-env\，每项目一次）
powershell -NoProfile -ExecutionPolicy Bypass -File C:\tkdev-env\scripts\deploy.ps1 -Target .

# 4. 绑定代码地图（dsh-aoci）
#    在 DSH 里说：/aoci <项目路径>
```

## 目录结构

```
├── skills/          ← tkdev 19 个技能（部署到项目 .tkdev-env\skills\）
├── dsh-aoci/        ← vendored AOCI 插件源码 + 构建产物 .tgz
├── scripts/
│   ├── bootstrap.ps1   ← 机器级引导（装 aoci.exe + 插件）
│   ├── deploy.ps1      ← 项目级部署（复制技能到 .tkdev-env\）
│   └── install-aoci.ps1← 下载 + 校验 aoci.exe
├── docs/            ← 使用说明
├── AGENTS.md        ← tkdev 路由表
├── ADAPTATION.md    ← 上游改编说明（署名）
├── LICENSE / COMMERCIAL-LICENSE.md  ← 许可
└── README.md
```

## 版本管理

- 每次迭代/改动 = `git commit`；历史可回溯。
- 回退 = `git checkout <commit/tag>`。
- 换方案 = 开 `git branch`，主线继续迭代。
- 新机器/新项目永远拉同一版本：`git pull`。

## 许可

- tkdev 技能改编自 [Show Me The Money](https://github.com/iamzifei/show-me-the-money)（CC BY-NC 4.0，署名 + 非商用），见 [ADAPTATION.md](ADAPTATION.md)。
- dsh-aoci 插件为 MIT，见 `dsh-aoci/LICENSE`。
- aoci.exe 为 FSL-1.1-MIT，本仓库不捆绑其二进制。

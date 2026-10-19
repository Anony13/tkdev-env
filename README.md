# tkdev-env

「tkdev + aoci」开发环境 —— 一套给 AI Agent 用的**软件开发流程 + 代码认知地图**工具，托管在 GitHub 上做版本管理。

- **tkdev**：19 个软件开发流程技能（接单 → 设计 → 开发 → 测试 → 质量 → 交付 → 售后 → 变更）。
- **aoci**：代码认知地图（给 Agent 提供「改代码前的全局视野」，随代码增量维护）。
- **dsh-aoci**：AOCI 的 DSH 动态 MCP 插件（vendor 在本仓库，避免上游删库）。

## 一条命令部署

在 DSH 会话里说：

> **「帮我部署 tkdev-env」**（新机器第一次建议说全：`帮我部署 github.com/Anony13/tkdev-env`）

Agent 会：`git clone` 本仓库**直接进项目的 `.tkdev-env\`** → 装 aoci.exe + dsh-aoci 插件（若缺）→ 建 AGENTS.local.md + gitignore。

**没有多余的「工具箱」副本** —— `.tkdev-env\` 就是环境本身（自带 .git，可 pull 更新）。

### 手动等价命令

```powershell
# 1. 把环境仓库直接 clone 进当前项目的 .tkdev-env\（每项目一份）
git clone https://github.com/Anony13/tkdev-env.git .tkdev-env

# 2. 机器级引导（装 aoci.exe + dsh-aoci 插件，每台机器一次）
powershell -NoProfile -ExecutionPolicy Bypass -File .\.tkdev-env\scripts\bootstrap.ps1

# 3. 项目级 setup（建 AGENTS.local.md + gitignore）
powershell -NoProfile -ExecutionPolicy Bypass -File .\.tkdev-env\scripts\deploy.ps1 -Target .

# 4. 绑定代码地图（dsh-aoci）
#    在 DSH 里说：/aoci <项目路径>
```

## 目录结构

```
（本仓库被 clone 进每个项目的 .tkdev-env\，成为那个项目的环境）
├── skills/          ← tkdev 19 个技能
├── dsh-aoci/        ← vendored AOCI 插件源码 + 构建产物 dist/*.tgz
├── scripts/
│   ├── bootstrap.ps1   ← 机器级引导（装 aoci.exe + 插件）
│   ├── deploy.ps1      ← 项目级 setup（建 AGENTS.local.md + gitignore）
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
- 某项目里的环境更新 = 在 `.tkdev-env\` 里 `git pull`。

## 许可

- tkdev 技能改编自 [Show Me The Money](https://github.com/iamzifei/show-me-the-money)（CC BY-NC 4.0，署名 + 非商用），见 [ADAPTATION.md](ADAPTATION.md)。
- dsh-aoci 插件为 MIT，见 `dsh-aoci/LICENSE`。
- aoci.exe 为 FSL-1.1-MIT，本仓库不捆绑其二进制。

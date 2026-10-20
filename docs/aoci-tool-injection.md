# AOCI 原生工具注入调查记录

> 状态：**搁置（CLI 为主路径）**，待后续开发继续。
> 关联版本：dsh-aoci v0.2.6（已含 `harness.defineTool` 修复）。

## 一句话结论

DSH 0.2.1-rc.2 里，**外部插件（非 `@deepseek-ai/dsh-*`）给模型注入工具，必须走沙箱**
（`@deepseek-ai/dsh-cordis-host-runner`），而这条链路里「工具注册成功 → 注入到模型函数集」
这一跳目前没通。所以 tkdev 的 AOCI 能力改用 **CLI 主路径**（读 `aoci.code.txt` + 跑
`aoci.exe`），原生工具注入留作后续。

## 背景

dsh-aoci 是第三方（单人维护）的 DSH 插件，给 DSH 提供 AOCI 代码认知地图工具。
它注册两类工具：

- **静态工具**：`aoci_status` / `aoci_verify` / `aoci_check` / `aoci_cognition` 等，在
  `apply()` 里通过 `ctx.tools.register(defineTool(...))` 注册。
- **动态 MCP 工具**：`mcp__aoci-<slug>__aoci_overview` / `aoci_call`，在 `/aoci <path>`
  绑定时通过 MCP 桥动态注册。

## 现象

在 DSH 0.2.0-rc.2 上，静态工具 `aoci_cognition` 可用（动态工具未注入）。DSH 自动升级到
0.2.1-rc.2 后，**所有 aoci 工具都不进模型函数集**（agent 的函数集里只有
`pwsh`/`read`/`grep`/`write`/`glob`/`web_*`/`todo_write`/`skill`/`subagent` 等基础工具）。

## 根因链（已从 DSH 源码实锤）

1. DSH 0.2.1-rc.2 引入了「model-mounted dual-half packages」机制，由
   `@deepseek-ai/dsh-cordis-host-runner` 承载。外部包在 `node:vm` 沙箱里跑。

2. 沙箱里 `ctx.tools.register` 是**带标记校验**的：

   ```javascript
   function assertDynamicTool(tool) {
     if (!isPlainRecord(tool) || tool[DYNAMIC_TOOL] !== true)
       throw new Error('dynamic tool registration must use a tool returned by harness.defineTool(...)');
   }
   ```

   只有 `harness.defineTool()` 生成（打 `DYNAMIC_TOOL` 标记）的工具才能注册。

3. dsh-aoci 原来用的是 `@deepseek-ai/dsh-tools` 的 `defineTool`（**不打标记**），所以每个
   工具注册都被 `assertDynamicTool` 拒掉，错误又被它自己的 `try/catch {}` 静默吞掉。

4. **已修**（v0.2.6）：把 dsh-aoci 里 19 处 `defineTool(...)` 改成沙箱全局的
   `harness.defineTool(...)`。

5. 但改完后工具**仍然不进函数集**。进一步确认：
   - `register()` 没抛错（文件日志没生成，`appendFileSync` 未被沙箱 trap）；
   - 沙箱 `sandboxTools` 的 `register` 接线正确：`register → sandboxRegisterTool →
     assertDynamicTool + ctx.tools.register(real)`；
   - `harness` 在插件代码里可访问（插件在 VM 里跑，`harness` 是 VM 全局）。

   所以断点收敛到最后一跳：**工具注册进了 registry，但没流进模型的函数集
   （prompt assembly / scope 归属）**。最可疑是「外部包的工具写进了 host 作用域，而模型
   读的是 agent 作用域」——`dsh-tools` 的 `schemas(scope)` 按 `exec.agent` 读，而
   `register` 用 `this.ctx.effect(...)` 写。

## 已排查、可排除的

- ❌ 不是「沙箱整体不通」——内置工具（`dsh-tool-fs`/`dsh-tool-fs-search`/`dsh-tool-terminal`
  这些 `@deepseek-ai/dsh-tool-*` 核心包）走非沙箱注册，能正常进函数集。
- ❌ 不是「invoke handler 表」——`harness.handle` 是跨半边 RPC（client↔host），与工具注入无关。
- ❌ 不是 `contributes.tools` —— DSH 运行时不读 `dsh.plugin.json` 的 `contributes`（那是
  dsh-aoci 从 VS Code/Claude Code 抄来的非标准字段）。
- ✅ 版本声明（0.2.0-rc.2 → 0.2.1-rc.2）已经修了，插件能正常加载。

## 官方文档的空白

`@deepseek-ai/dsh-cordis-host-runner/README.md` 说了「host half 在 vm 沙箱跑」「注册工具会
改变下一次请求的工具视图」，但**没有任何文档写 `harness.defineTool` / `harness.registerTool`
的具体用法**（搜 `registerTool` 在文档里 0 命中）。外部插件工具注入属于「无文档、只能反编译
源码」的灰色地带。

## 后续恢复开发的方向

要坐实「作用域归属」，需要继续看：

1. `@deepseek-ai/dsh-app-boot` / `dsh/lib/profile-boot` 如何给外部包传 `ctx`（传的是 host
   ctx 还是 agent ctx）；
2. `@deepseek-ai/dsh-scope` 的 `scopeOf` / `ScopedLayers` —— 工具写进哪一层、模型读哪一层；
3. cordis 的 `insert` patch 把外部包插进了哪个作用域。

线索文件（asar 内）：

- `dsh/node_modules/@deepseek-ai/dsh-cordis-host-runner/lib/index.js` —— 沙箱、harness、
  sandboxTools、assertDynamicTool
- `dsh/node_modules/@deepseek-ai/dsh-tools/lib/index.js` —— `ctx.tools.register` /
  `schemas(scope)` / `scopeOf`
- `dsh/node_modules/@deepseek-ai/dsh-scope` —— 作用域层

## 相关提交

- `43e1a2c` —— 版本声明升级到 0.2.1-rc.2（v0.2.5）
- `75d6994` —— defineTool 改用 `harness.defineTool`（v0.2.6）

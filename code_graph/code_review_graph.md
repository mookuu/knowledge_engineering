# code-review-graph 用法（Review / 调用链 / MCP）

[code-review-graph](https://github.com/tirth8205/code-review-graph) 是面向 AI 编程助手的本地**代码结构图谱**（Tree-sitter AST → SQLite 图库 → MCP），擅长回答「谁调谁、改一处影响哪、相关测试在哪」。  
与 AiBasic 已文档化的 [Graphify](graphify.md) 互补：后者偏 **多模态语料 + 概念关联 + 交互可视化**；本工具偏 **Review / 调用链 / 增量索引**。

工具生态对比见：[code_knowledge_graph_tools.md](code_knowledge_graph_tools.md)。

---

## 定位对比（本仓库语境）


| 维度         | code-review-graph                               | Graphify                      |
| ---------- | ----------------------------------------------- | ----------------------------- |
| 主要输入       | 源代码（19+ 语言）                                     | 代码 + Markdown/PDF/图片/视频等      |
| 抽取方式       | Tree-sitter AST，确定性边                            | AST（代码）+ LLM（文档/语义边）          |
| 存储         | `django_learn_demo/.code-review-graph/graph.db` | 项目内 `graphify-out/graph.json` |
| IDE 集成     | MCP（`.cursor/mcp.json`）                         | Skill（`/graphify`）+ 可选 MCP    |
| 典型问题       | 「谁调用了 X？」「改动影响面？」                               | 「Auth 和 Database 如何关联？」       |
| AiBasic 现状 | 已配置 `django_learn_demo`                         | 已生成 `django_learn_demo/graphify-out/`（见 [graphify.md](graphify.md)） |


---

## 环境要求


| 项       | 要求                                                   |
| ------- | ---------------------------------------------------- |
| Python  | 3.10+                                                |
| PyPI 包名 | `code-review-graph`                                  |
| 本仓库实例   | `django_learn_demo/.venv` 内已安装；MCP 使用该 venv 的 Python |
| 图谱范围    | **仅** `django_learn_demo/`（非整个 AiBasic monorepo）     |


嵌套 monorepo 必须在 MCP / CLI 中设置 `**CRG_REPO_ROOT`** 指向子项目根目录，否则会在错误路径建图或查不到节点。

---

## 安装

### 1. 安装 CLI（子项目 venv）

```bash
cd django_learn_demo
python -m venv .venv
.venv/Scripts/pip install code-review-graph   # Windows
# source .venv/bin/activate && pip install code-review-graph   # Linux/macOS
```

验证：

```bash
.venv/Scripts/python.exe -m code_review_graph --version
```

### 2. 注册 Cursor MCP（本仓库已配置）

AiBasic 根目录 `.cursor/mcp.json` 示例：

```json
{
  "mcpServers": {
    "code-review-graph": {
      "command": "…/django_learn_demo/.venv/Scripts/python.exe",
      "args": ["-m", "code_review_graph", "serve"],
      "cwd": "…/django_learn_demo",
      "env": {
        "CRG_REPO_ROOT": "…/django_learn_demo"
      },
      "type": "stdio"
    }
  }
}
```

修改路径后需**重启 Cursor** 或重载 MCP。也可在子项目内执行：

```bash
cd django_learn_demo
code-review-graph install --platform cursor
```

---

## 建图与增量更新

在 `**django_learn_demo**` 目录下操作，并设置 `CRG_REPO_ROOT`：

```bash
cd django_learn_demo
export CRG_REPO_ROOT="$(pwd)"          # Git Bash / Linux / macOS
# PowerShell: $env:CRG_REPO_ROOT = (Get-Location).Path

# 全量重建（改结构、首次克隆、迁移后）
.venv/Scripts/python.exe -m code_review_graph build --repo "$CRG_REPO_ROOT"

# 增量（仅变更文件，日常开发）
.venv/Scripts/python.exe -m code_review_graph update --repo "$CRG_REPO_ROOT"

# 查看统计
.venv/Scripts/python.exe -m code_review_graph status --repo "$CRG_REPO_ROOT"
```

**推荐流程**（代码有较大结构变更后）：

1. `build` 全量重建
2. `visualize` 生成 HTML
3. `python scripts/patch_graph_html.py` 修补可视化（见下文）
4. 重启 MCP 或 Cursor，使助手读到新图

`graph.db` 可提交 git，便于异地直接 `update` 而非从零 `build`。

---

## 输出目录 `.code-review-graph/`


| 文件                  | 说明                                    |
| ------------------- | ------------------------------------- |
| `graph.db`          | SQLite 图谱（节点、边、Flows、Communities、FTS） |
| `graph.html`        | 官方生成的交互力导向图（需 patch，见下节）              |
| `d3.v7.min.js`      | patch 脚本下载的本地 D3（避免 CDN / SRI 失败）     |


可选导出：

```bash
code-review-graph visualize --format graphml
code-review-graph visualize --format svg
code-review-graph wiki          # 按社区生成 Markdown wiki
```

---

## 浏览器可视化

### 生成与预览

```bash
cd django_learn_demo
export CRG_REPO_ROOT="$(pwd)"

# 只生成 HTML
.venv/Scripts/python.exe -m code_review_graph visualize --repo "$CRG_REPO_ROOT"

# 生成并用内置 HTTP 服务预览（默认 localhost:8765）
code-review-graph visualize --serve
```

用**系统浏览器**打开（不要用 Cursor Simple Browser 预览大图谱）：

- **[http://localhost:8765/graph.html](http://localhost:8765/graph.html)**

界面操作：搜索节点、`Fit` 居中、Flows / Communities 高亮、按 Kind 过滤、`?` 快捷键帮助。

### 必做：patch `graph.html`

上游 `visualize` 生成的 HTML 在本项目上有已知问题，**每次 `visualize` 后需执行**：

```bash
cd django_learn_demo
python scripts/patch_graph_html.py
```

脚本会：


| 问题                     | 修复                                             |
| ---------------------- | ---------------------------------------------- |
| D3 CDN / SRI 失败 → 整页空白 | 改为本地 `d3.v7.min.js`（jsDelivr 镜像下载）             |
| 力导向图挤在左侧图例、主画布黑屏       | `d3.select("svg")` → `d3.select("#graph-svg")` |
| 未解析外部符号边 → 节点 NaN      | 过滤只保留两端均为已知节点的边                                |
| 窗口 resize 后布局错乱        | 注入 resize + 自动 `fitGraph`                      |

---

## 在 Cursor 中使用（MCP）

探索 `**django_learn_demo**` 时，助手应**优先**使用 code-review-graph MCP，再 fallback 到 Grep/Read（见仓库根 `AGENTS.md`）。

### 何时优先用图谱


| 场景              | 推荐工具                                             |
| --------------- | ------------------------------------------------ |
| 按名称找函数/类        | `semantic_search_nodes`                          |
| 调用方 / 被调用方      | `query_graph`（`callers_of` / `callees_of`）       |
| import / 测试覆盖   | `query_graph`（`imports_of` / `tests_for`）        |
| 改动影响面           | `detect_changes` + `get_impact_radius`           |
| Code Review 上下文 | `get_review_context`                             |
| 执行路径            | `get_affected_flows`                             |
| 架构总览            | `get_architecture_overview` + `list_communities` |
| 重构规划            | `refactor_tool`                                  |


### 对话示例

```text
用 code-review-graph 查 notes/views.py 里 note_list 的 callers
detect_changes 分析当前 git 改动的影响面
query_graph tests_for NoteListView
```

---

## 在 AiBasic 上的推荐用法

### 场景 A：Django 学习子项目日常编码

- MCP 已指向 `django_learn_demo`；改代码后 `update`，大改后 `build`。  
- Review 时用 `detect_changes` + `get_review_context`，不必整文件 `@` 进对话。

### 场景 B：与 Graphify 分工


| 任务                                            | 用哪个                                                     |
| --------------------------------------------- | ------------------------------------------------------- |
| `callers_of` / `tests_for` / `detect-changes` | **code-review-graph**（本文）                               |
| 「文档里的架构和代码是否一致？」                              | Graphify `query` / `path`（见 [graphify.md](graphify.md)） |
| 浏览全局社区 + 多模态语料                                | Graphify `graph.html`                                   |


两者数据目录**互不覆盖**，可同时保留。

### 场景 C：提交图谱供他人使用

```bash
# 本地 build 后
git add django_learn_demo/.code-review-graph/graph.db
# graph.html / d3.v7.min.js 按需是否提交
```

他人克隆后可直接 `update`，无需全量 `build`。

---

## 常见问题

`**PermissionError: WinError 10013`（`visualize --serve`）**

- 8765 端口已被占用（常为上次未退出的 Python）。  
- 处理：`netstat -ano | findstr 8765` → `taskkill /PID <pid> /F`，或直接打开已 patch 的 `graph.html`（`file://` 或 `python -m http.server`）。

**主画布黑屏，力导向图出现在左侧图例小框**

- 未执行 `patch_graph_html.py`。按上文「必做：patch」一节处理。

**Console：`localStorage` SecurityError（`prepare.js`）**

- 多为浏览器扩展注入脚本，**不是** graph.html 本身；用系统浏览器访问 `http://localhost:8765/graph.html`，可忽略或无痕窗口排除扩展。

**MCP 查不到节点 / 建图路径不对**

- 确认 `CRG_REPO_ROOT` 与 `cwd` 均为 `django_learn_demo` 绝对路径；大改后执行 `build` 并重启 Cursor。

**与 Graphify 冲突吗？**

- 不冲突。MCP 读 `.code-review-graph/graph.db`；Graphify 写 `graphify-out/`。

**每次 `visualize --serve` 会覆盖 patch 吗？**

- `--serve` 会重新生成 `graph.html`。习惯流程：`visualize` → `patch_graph_html.py` → `--serve` 或硬刷新浏览器预览。

---

## CLI 速查

```bash
code-review-graph build [--repo PATH]     # 全量建图
code-review-graph update [--repo PATH]    # 增量
code-review-graph status [--repo PATH]
code-review-graph visualize [--serve]
code-review-graph detect-changes          # 变更影响（CLI 版）
code-review-graph watch                   # 监听文件自动 update
code-review-graph serve                   # MCP stdio（Cursor 已配置）
```

---

## 链接


| 资源     | URL                                                                                              |
| ------ | ------------------------------------------------------------------------------------------------ |
| GitHub | [https://github.com/tirth8205/code-review-graph](https://github.com/tirth8205/code-review-graph) |
| 官网     | [https://code-review-graph.com](https://code-review-graph.com)                                   |
| PyPI   | [https://pypi.org/project/code-review-graph/](https://pypi.org/project/code-review-graph/)       |


---

*最后更新：2026-05-22*
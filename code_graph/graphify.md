# Graphify 用法（AI 知识图谱 Skill）

[Graphify](https://graphify.net/) 是面向 AI 编程助手的开源 **Skill**，把代码、文档、论文、图片、音视频等整包材料建成**可查询知识图谱**（Tree-sitter AST + LLM 语义抽取 + Leiden 社区聚类）。  
与 AiBasic 已落地的 [code-review-graph](code_review_graph.md) 互补：后者偏 **Review / 调用链 / MCP**；Graphify 偏 **多模态语料 + 概念关联 + 交互可视化**。

工具生态对比见：[code_knowledge_graph_tools.md](code_knowledge_graph_tools.md)。

---

## 定位对比（本仓库语境）

| 维度 | code-review-graph | Graphify |
|------|-------------------|----------|
| 主要输入 | 源代码（19+ 语言） | 代码 + Markdown/PDF/图片/视频等 |
| 抽取方式 | Tree-sitter AST，确定性边 | AST（代码）+ LLM（文档/语义边） |
| 存储 | `django_learn_demo/.code-review-graph/graph.db` | `django_learn_demo/graphify-out/graph.json` |
| IDE 集成 | MCP（`.cursor/mcp.json`） | Skill（`/graphify`）+ 可选 MCP |
| 典型问题 | 「谁调用了 X？」「改动影响面？」 | 「Auth 和 Database 如何关联？」「设计 rationale 在哪？」 |
| AiBasic 现状 | 已配置 `django_learn_demo` | 已生成 `django_learn_demo/graphify-out/`（与 CRG 可并存） |

---

## 环境要求

| 项 | 要求 |
|----|------|
| Python | 3.10+ |
| 包管理（推荐） | [uv](https://github.com/astral-sh/uv) 或 pipx |
| PyPI 包名 | **`graphifyy`**（双 y；CLI 命令仍为 `graphify`） |
| 语义抽取（可选） | 设置 `GEMINI_API_KEY` / `GOOGLE_API_KEY` 并安装 `graphifyy[gemini]` 或 `openai`；否则 headless 下文档语义边可能缺失，代码 AST 仍可用 |

> 其他 PyPI 上的 `graphify*` 包与官方无关，请只安装 `graphifyy`。

---

## 安装

### 1. 安装 CLI

**本仓库推荐**：装入 `django_learn_demo/.venv`（与 code-review-graph 共用子项目 venv）：

```bash
cd django_learn_demo
python -m venv .venv
.venv/Scripts/pip install graphifyy          # Windows
# source .venv/bin/activate && pip install graphifyy   # Linux/macOS
```

全局安装（任意目录可用 `graphify` 命令）：

```powershell
uv tool install graphifyy    # 推荐，自动加入 PATH
pipx install graphifyy
```

验证：

```powershell
graphify --version           # 例：graphify 0.8.14
# venv 内未加入 PATH 时：
python -m graphify --help
```

### 2. 注册到 Cursor

在**项目根**（AiBasic）或子项目内执行：

```powershell
graphify cursor install
```

会在项目中写入 `.cursor/rules/graphify.mdc`，使助手在存在 `graphify-out/` 时优先用图谱查询，而不是整仓 Grep。

卸载：

```powershell
graphify cursor uninstall
graphify uninstall          # 所有平台
graphify uninstall --purge  # 并删除 graphify-out/
```

### 3. 可选能力包

按需安装，避免默认装全量依赖：

```powershell
pip install "graphifyy[pdf]"      # PDF
pip install "graphifyy[office]"   # docx / xlsx
pip install "graphifyy[video]"    # 音视频转写（Whisper）
pip install "graphifyy[gemini]"   # Gemini API 语义抽取
pip install "graphifyy[mcp]"      # MCP stdio 服务
pip install "graphifyy[neo4j]"    # 推送到 Neo4j
pip install "graphifyy[all]"      # 全部
```

---

## 本仓库实例（django_learn_demo）

图谱范围：**仅** `django_learn_demo/`（与 code-review-graph 相同子项目，输出目录互不覆盖）。

### 全量建图（headless，已验证 graphifyy 0.8.14）

```bash
cd django_learn_demo

# 1. 安装（若尚未安装）
.venv/Scripts/pip install graphifyy

# 2. AST + 语义抽取（无 API Key 时仍写出代码 AST 图；文档语义块会告警并跳过）
.venv/Scripts/python.exe -m graphify extract . --out .

# 3. 若需单独重算聚类 / 补全 graph.html、GRAPH_REPORT.md
.venv/Scripts/python.exe -m graphify cluster-only .
```

**当前产出（2026-05-22）**：105 节点 · 134 边 · 20 社区；扫描 30 个代码文件 + 7 个文档。  
核心 hub 示例：`CookieJWTCSRFTests`、`CookieJWTAuthentication`、`Note`（详见 `graphify-out/GRAPH_REPORT.md`）。

打开可视化（用系统浏览器，勿用 Cursor 窄条 Simple Browser）：

```text
file:///…/django_learn_demo/graphify-out/graph.html
```

### 增量更新（改代码后，无 API 费用）

```bash
cd django_learn_demo
.venv/Scripts/python.exe -m graphify update .
# 大改后若节点数异常变少，可加 --force
```

### CLI 查询（不经过 Cursor Skill）

```bash
cd django_learn_demo
.venv/Scripts/python.exe -m graphify query "Cookie JWT 和 CSRF 如何关联？" --budget 1500
.venv/Scripts/python.exe -m graphify path "CookieLogoutView" "csrf_init"
.venv/Scripts/python.exe -m graphify explain "CookieJWTAuthentication"
```

### 补全文档语义边（可选）

headless 语义抽取需 API 客户端；未安装时会出现 `requires the openai package` 告警，**不影响代码 AST 图**：

```powershell
cd django_learn_demo
.venv/Scripts/pip install openai          # 或 graphifyy[gemini]
$env:GEMINI_API_KEY = "your-key"
.venv/Scripts/python.exe -m graphify extract . --out . --backend gemini
```

`graph.json` 可提交 git（与 `graph.db` 类似）；`graphify-out/cache/` 为本地缓存，通常不必提交。

---

## 在 Cursor 中使用

### 构建图谱（Skill 主路径）

在 Cursor 对话中输入（对**当前工作区目录**建图）：

```text
/graphify .
```

对指定子目录（例如只建 `django_learn_demo`）：

```text
/graphify django_learn_demo
```

从 GitHub 克隆后建图：

```text
/graphify https://github.com/owner/repo
```

**PowerShell 注意**：在终端直接跑 CLI 时用 `graphify extract . --out .`，不要写 `/graphify .`（前导 `/` 会被 PowerShell 当成路径）。

### 常用构建参数（Skill / CLI）

| 参数 | 作用 |
|------|------|
| `--mode deep` | 更激进的 INFERRED 语义边（Skill） |
| `--update` / `graphify update` | 仅重抽新增/变更文件（代码无需 LLM） |
| `--no-viz` | 跳过 HTML，只生成报告 + JSON |
| `cluster-only` | 仅重跑聚类并刷新 `graph.html` / `GRAPH_REPORT.md` |
| `--directed` | 有向图（保留 source→target） |
| `--wiki` | 生成按社区拆分的 Markdown wiki |
| `watch` | 监听目录变更自动重建（无需 LLM） |
| `--mcp` | 启动 MCP stdio 供 Agent 查询 |

大仓库（>200 文件或 >200 万词）时，Skill 会提示选择子目录，避免一次性抽爆 Token。

### 建图后查询

在已有 `graphify-out/` 的前提下：

```text
/graphify query "Cookie 认证和 CSRF 如何关联？"
/graphify query "logout 流程" --dfs
/graphify query "..." --budget 1500

/graphify path "CookieLogoutView" "csrf_init"
/graphify explain "CookieLogoutView"
```

| 子命令 | 用途 |
|--------|------|
| `query` | BFS 遍历相关子图（默认）；`--dfs` 追踪单一路径 |
| `path` | 两概念间最短路径 |
| `explain` | 对某节点的 plain-language 说明 |

### 增量追加材料

```text
/graphify add https://example.com/doc
/graphify add --author "Name"
```

---

## 输出目录 `graphify-out/`

建图完成后，在扫描根目录下生成 `graphify-out/`（`extract --out .` 即 `./graphify-out/`）：

| 文件 / 目录 | 说明 |
|-------------|------|
| `graph.html` | 浏览器交互图（节点点击、过滤、搜索） |
| `graph.json` | 完整图数据，供 `query` / `path` / `explain` 复用 |
| `GRAPH_REPORT.md` | 人类可读摘要：god nodes、意外连接、社区 hub |
| `manifest.json` | 各源文件的 mtime / hash，供 `update` 增量比对 |
| `cache/` | AST 与语义抽取缓存（本地重建用） |
| `.graphify_analysis.json` | 抽取统计与元数据 |
| `.graphify_labels.json` | 社区标签等辅助数据 |

> **勘误**：旧版文档中的 `.graphify_python`、`.graphify_root` 在 graphifyy **0.8.x** 中已由 `manifest.json` 等替代。

可选导出：

```powershell
graphify export callflow-html   # Mermaid 调用流 HTML
graphify tree                   #  collapsible D3 树形 HTML → graphify-out/GRAPH_TREE.html
```

用系统浏览器打开 `graphify-out/graph.html`（与 code-review-graph 类似，避免用 Cursor 窄条 Simple Browser 预览大图谱）。

---

## 无界面 CLI（headless）

不经过对话 Skill、直接在终端建图：

```bash
cd django_learn_demo
.venv/Scripts/python.exe -m graphify extract . --out .
# 语义边（需 API Key + openai 或 gemini  extras）：
# .venv/Scripts/python.exe -m graphify extract . --out . --backend gemini
```

其他常用命令（graphifyy 0.8.14）：

```powershell
graphify update .              # 增量（代码 AST，无 LLM）
graphify cluster-only .          # 重聚类 + 刷新 HTML/报告
graphify clone https://github.com/owner/repo
graphify merge-graphs a/graphify-out/graph.json b/graphify-out/graph.json --out graphify-out/merged.json
graphify export callflow-html
graphify benchmark graphify-out/graph.json
```

> **勘误**：`graphify detect` 在 0.8.x CLI 中**不存在**；建图前可直接 `extract`，或查看 `extract` 日志中的 `found N code, M docs` 行。

启动 MCP（需 `graphifyy[mcp]`）：

```powershell
graphify --mcp
# 或在 Skill 中：/graphify --mcp
```

---

## 边的置信度标签

Graphify 对每条关系标注来源，便于 Review：

| 标签 | 含义 |
|------|------|
| `EXTRACTED` | 源码/文档中显式出现（import、调用、引用） |
| `INFERRED` | 合理推断（共享数据结构、隐含依赖） |
| `AMBIGUOUS` | 不确定，需人工核对 |

代码文件的 **import/调用** 主要由 Tree-sitter AST 本地抽取；**跨文档概念、设计 rationale** 依赖 LLM 语义边。

---

## 在 AiBasic 上的推荐用法

### 场景 A：只分析 Django 学习子项目

```text
/graphify django_learn_demo
```

或 headless：`cd django_learn_demo && python -m graphify extract . --out .`  
产出在 `django_learn_demo/graphify-out/`，与 `django_learn_demo/.code-review-graph/` **互不覆盖**。

### 场景 B：FirstAgent 代码 + 知识工程文档统一图谱

```text
/graphify FirstAgent knowledge_engineering/agents
```

适合把 [`knowledge_engineering/agents/`](../agents/) 里的设计说明与 `FirstAgent` 下 Agent 代码关联查询。

### 场景 C：与 code-review-graph 分工

| 任务 | 用哪个 |
|------|--------|
| `callers_of` / `tests_for` / `detect-changes` | code-review-graph（见 [code_review_graph.md](code_review_graph.md)） |
| 「文档里说的架构和代码是否一致？」 | Graphify `query` / `path` |
| 浏览全局社区结构 | Graphify `graph.html` |

---

## 支持的文件类型（摘要）

| 类型 | 扩展名示例 |
|------|------------|
| 代码 | `.py` `.ts` `.js` `.go` `.java` `.rs` …（约 31 种） |
| 文档 | `.md` `.html` `.txt` `.yaml` … |
| 论文 | `.pdf`（需 `[pdf]`） |
| 办公 | `.docx` `.xlsx`（需 `[office]`） |
| 图片 | `.png` `.jpg` `.webp` … |
| 音视频 | `.mp4` `.mp3` …（需 `[video]`，Whisper 转写） |

代码抽取**不调用外部 API**；文档/图片/视频语义抽取会消耗模型 Token（Gemini 或当前 IDE 会话模型）。

---

## 常见问题

**`graphify: command not found`**

- 使用 `uv tool install graphifyy` 或 `pipx install graphifyy`；plain `pip` 进 venv 时用 `python -m graphify`（本仓库 `django_learn_demo/.venv`）。

**`semantic chunk(s) failed` / `requires the openai package`**

- headless 下未装 API 客户端或未设 Key 时，**文档语义边**会失败；**代码 AST 图仍会写入** `graph.json`。需要完整语义边时：`pip install openai` 或 `graphifyy[gemini]`，并设置对应 API Key 后重跑 `extract`。

**`extract --out graphify-out` 写了两层目录？**

- `--out` 是**父目录**，实际输出为 `<out>/graphify-out/`。对本仓库请用 `--out .`，得到 `./graphify-out/`。

**与 code-review-graph MCP 冲突吗？**

- 不冲突。MCP 指向 `code_review_graph`；Graphify 写 `graphify-out/` 并通过 Skill 或 `graphify query` 查询。`graph.json` 可按需提交；`cache/` 建议忽略。

**大仓库很慢**

- 用子目录建图；或 `graphify update` 增量；语料极大时设置 `GEMINI_API_KEY` 走并行 Gemini 抽取。

**Windows 上 `/graphify` 无效**

- 在**终端**用 `python -m graphify extract . --out .`；在 **Cursor 聊天**里用 `/graphify django_learn_demo`。

---

## 链接

| 资源 | URL |
|------|-----|
| 官网 | https://graphify.net/ |
| GitHub | https://github.com/safishamsi/graphify |
| CLI 参考 | https://graphify.net/graphify-cli-commands.html |
| PyPI | https://pypi.org/project/graphifyy/ |

---

*最后更新：2026-05-22（django_learn_demo 实例已建图；勘误 graphifyy 0.8.14 CLI 与输出文件）*

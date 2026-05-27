# Graphify 用法整理

[Graphify](https://graphify.net/) 是面向 AI 编程助手的知识图谱工具。它把一个仓库里的代码、Markdown、PDF、图片、音视频等材料转换为 `graphify-out/` 下的可查询图谱，核心流程是：

1. **AST 提取**：本地 Tree-sitter 解析代码结构。
2. **语义提取**：用 LLM 从文档、图片、论文等非结构化材料中抽取概念和关系。
3. **图谱生成**：合并两阶段结果，做社区聚类，生成 `graph.json`、`graph.html` 和报告。

本文只用一个仓库做示例：`D:\kan\kan\Python\knowledge_engineering`。

---

## 安装

PyPI 包名是 **`graphifyy`**，安装后命令名是 `graphify`。

```powershell
cd D:\kan\kan\Python\knowledge_engineering
python -m venv .venv
.\.venv\Scripts\pip install graphifyy
.\.venv\Scripts\python -m graphify --help
```

也可以全局安装：

```powershell
uv tool install graphifyy
# 或
pipx install graphifyy
```

可选能力按需安装：

```powershell
pip install "graphifyy[pdf]"      # PDF
pip install "graphifyy[office]"   # docx / xlsx
pip install "graphifyy[video]"    # 音视频转写
pip install "graphifyy[mcp]"      # MCP stdio 服务
pip install "graphifyy[neo4j]"    # Neo4j 导出 / 推送
pip install "graphifyy[all]"      # 全部可选能力
```

---

## 两阶段提取

### 关系总览

AST 提取和语义提取是同一条建图流水线中的两个互补阶段：前者负责代码里的确定性结构，后者负责文档、图片、PDF 等材料中的概念关系。两部分结果最终会合并为同一张图谱。

```text
代码文件
  -> AST 提取
  -> 确定性结构图：类、函数、调用、import

文档 / 图片 / PDF / 说明材料
  -> 语义提取
  -> 概念图：设计意图、业务概念、架构关系

AST 图 + 语义图
  -> 合并
  -> 聚类 / 可视化 / 查询图谱
```

`graphify .` 是统一建图入口，不是“AST 提取”和“语义提取”各自一条独立命令。执行时 Graphify 会扫描文件并按流水线处理：代码文件走 AST 提取，文档、图片、PDF 等材料尝试走语义提取，然后把成功得到的结果合并成图谱。

API 只影响语义提取阶段能否补全：没有 API 或助手模型能力时，AST 提取仍会执行，代码结构图仍可生成；语义提取可能跳过、失败或只产生较少结果，并给出相关警告。

### 1. AST 提取：代码结构，本地完成

AST 提取用于代码文件，例如 `.py`、`.js`、`.ts`、`.go`、`.java`、`.rs` 等。Graphify 会用 Tree-sitter 在本机解析：

- 模块、类、函数、方法等结构节点
- import / dependency 边
- 调用关系边
- docstring 和 `NOTE`、`IMPORTANT`、`WHY` 等 rationale 注释

这一阶段的特点：

- **不需要 API Key**
- **不调用外部模型**
- **源码不离开本机**
- 输出关系通常标记为 `EXTRACTED`，表示来自源码中的确定事实

命令行执行：

```powershell
cd D:\kan\kan\Python\knowledge_engineering
.\.venv\Scripts\python -m graphify .
```

如果 `graphify` 已在 PATH 中：

```powershell
cd D:\kan\kan\Python\knowledge_engineering
graphify .
```

在 Cursor 聊天中执行同一件事：

```text
/graphify .
```

注意：`/graphify` 是 Cursor / AI 助手里的 slash command；PowerShell 终端里不要写前导 `/`，终端应使用 `graphify .` 或 `python -m graphify .`。

### 2. 语义提取：文档 / 图片 / 论文等，需要模型

语义提取用于非结构化或弱结构化材料，例如：

- Markdown / HTML / TXT 文档
- PDF / Office 文档
- 图片 / 架构图
- 音视频转写后的文本

这一阶段会用 LLM 抽取概念、设计理由和跨文件关系。输出关系通常标记为：

- `INFERRED`：模型根据上下文推断出的关系
- `AMBIGUOUS`：模型认为不确定，需要人工复核

API 来源取决于执行方式：

| 执行方式 | API 来源 | 是否需要你额外设置 Key |
|----------|----------|-------------------------|
| Cursor / 其他 AI 助手中执行 `/graphify .` | 助手当前配置的模型 API | 通常不需要在仓库里额外放 Key |
| 终端中执行 `graphify .` | 当前 shell 环境中的模型 API 配置 | 需要按所用 provider 设置环境变量 |
| 只想做代码 AST 图 | 不需要模型 API | 不需要 |

### 语义提取时设置常见大模型 Key

终端中运行 `graphify .` 时，语义提取阶段通常从当前 shell 环境变量读取模型凭据。常见 provider 的环境变量名如下，具体以 Graphify 当前版本及其底层 SDK 支持为准：

| Provider | 常见环境变量 |
|----------|--------------|
| OpenAI | `OPENAI_API_KEY` |
| Anthropic / Claude | `ANTHROPIC_API_KEY` |
| Google Gemini | `GEMINI_API_KEY` 或 `GOOGLE_API_KEY` |
| DeepSeek | `DEEPSEEK_API_KEY` |
| OpenRouter | `OPENROUTER_API_KEY` |
| 阿里云 DashScope / 通义千问 | `DASHSCOPE_API_KEY` |
| Azure OpenAI | `AZURE_OPENAI_API_KEY`、`AZURE_OPENAI_ENDPOINT`、部署名等 Azure 相关配置 |

方式一：只在当前 PowerShell 会话临时设置，关闭终端后失效：

```powershell
$env:GEMINI_API_KEY = "your-key"
graphify .
```

方式二：设置当前用户级环境变量，新开的终端会生效：

```powershell
setx GEMINI_API_KEY "your-key"
```

执行 `setx` 后，需要重新打开 PowerShell，再运行：

```powershell
graphify .
```

方式三：使用项目本地 `.env` 文件。只有当 Graphify 或启动脚本会显式加载 `.env` 时才有效：

```text
GEMINI_API_KEY=your-key
OPENAI_API_KEY=your-key
ANTHROPIC_API_KEY=your-key
```

`.env` 只适合本地开发，不应提交到仓库。若使用 `.env`，应确认 `.gitignore` 已忽略它。

如果使用 OpenAI / Anthropic / 其他 provider，则按对应工具或 SDK 要求设置环境变量。Graphify 本身不托管模型，也不提供统一中转服务；语义提取阶段使用的是你本机、当前 shell 或 AI 助手已经配置好的模型凭据。

没有 API Key 时，通常仍可得到代码 AST 图；文档、图片等语义关系可能缺失或出现 semantic extraction 相关警告。

---

## 一次完整建图

以 `knowledge_engineering` 仓库为例。

### 命令行方式

```powershell
cd D:\kan\kan\Python\knowledge_engineering
.\.venv\Scripts\python -m graphify .
```

如果使用全局命令：

```powershell
cd D:\kan\kan\Python\knowledge_engineering
graphify .
```

### Cursor 方式

在 Cursor 聊天中输入：

```text
/graphify .
```

这会对当前仓库建图。若工作区里打开了多个仓库，建议先明确路径：

```text
/graphify D:\kan\kan\Python\knowledge_engineering
```

---

## 图谱生成行为

Graphify 建图命令默认会在扫描根目录下生成 `graphify-out/`。例如在 `knowledge_engineering` 根目录执行后，默认产物是：

```text
D:\kan\kan\Python\knowledge_engineering\graphify-out\
```

常见输出：

| 文件 / 目录 | 说明 | 默认是否生成 |
|-------------|------|--------------|
| `graph.json` | 完整图谱数据，供 `query` / `path` / `explain` 使用 | 是 |
| `graph.html` | 可视化交互图 | 是，除非使用 `--no-viz` |
| `GRAPH_REPORT.md` | 人类可读摘要，例如 hub、社区、异常连接 | 是 |
| `manifest.json` | 文件 hash / mtime 等增量更新依据 | 是 |
| `cache/` | 本地缓存，便于重跑和增量 | 通常会生成 |
| `.graphify_analysis.json` | 抽取统计和元数据 | 版本相关，可能生成 |
| `.graphify_labels.json` | 社区标签等辅助数据 | 版本相关，可能生成 |

打开可视化：

```text
D:\kan\kan\Python\knowledge_engineering\graphify-out\graph.html
```

建议用系统浏览器打开，不要用 Cursor 窄窗口预览大图。

### 其他可视化输出

`graph.html` 是默认交互图，适合浏览完整知识图谱。除此之外，Graphify 还可按用途生成更聚焦的视图：

| 可视化形式 | 典型用途 | 示例命令 |
|------------|----------|----------|
| 交互图 `graph.html` | 浏览完整图谱、搜索节点、查看社区结构 | `graphify .` |
| 调用流 HTML | 看函数、类、模块之间的调用方向，适合代码 Review；HTML 中可包含架构 / 调用流 Mermaid 图 | `graphify export callflow-html .` |
| 树形视图 | 从目录、模块或概念层级理解项目结构 | `graphify tree` |
| SVG | 导出静态图片，适合放进文档或报告 | `graphify . --svg` |
| GraphML | 给 Gephi、yEd 等专业图工具继续分析 | `graphify . --graphml` |
| Wiki / Obsidian | 按社区拆分为可阅读的知识库 | `graphify . --wiki` / `graphify . --obsidian` |
| Neo4j Cypher | 导入图数据库做复杂查询 | `graphify . --neo4j` |

当前 CLI 支持 `html`、`callflow-html`、`obsidian`、`wiki`、`svg`、`graphml`、`neo4j` 等导出格式；没有单独的 `callflow-mermaid` 格式。不同 Graphify 版本的导出子命令可能略有差异；如果命令不可用，先查看当前安装版本支持的导出项：

```powershell
graphify --help
graphify export --help
```

### 跳过可视化

如果只要 JSON 和报告，不生成 HTML：

```powershell
graphify . --no-viz
```

### 只重新聚类 / 刷新图谱展示

已有 `graphify-out/graph.json`，只想重新生成社区聚类或刷新 HTML / 报告：

```powershell
graphify . --cluster-only
```

### 增量更新

代码或文档小范围变更后：

```powershell
graphify . --update
```

增量更新依赖 `graphify-out/manifest.json`。如果改动较大、节点异常减少或结果不可信，直接重新跑全量建图：

```powershell
graphify .
```

---

## 建图后查询

已有 `graphify-out/` 后，可以查询图谱。

命令行：

```powershell
cd D:\kan\kan\Python\knowledge_engineering
graphify query "code-review-graph 和 Graphify 的区别是什么？"
graphify query "图谱生成流程" --budget 1500
graphify path "code-review-graph" "Graphify"
graphify explain "Graphify"
```

Cursor 中：

```text
/graphify query "code-review-graph 和 Graphify 的区别是什么？"
/graphify query "图谱生成流程" --budget 1500
/graphify path "code-review-graph" "Graphify"
/graphify explain "Graphify"
```

---

## 导出与集成

常用导出参数和子命令：

```powershell
graphify . --wiki          # 按社区生成 Markdown wiki
graphify . --obsidian      # 生成 Obsidian vault
graphify . --svg           # 导出 graph.svg
graphify . --graphml       # 导出 graph.graphml
graphify . --neo4j         # 生成 cypher.txt
graphify export callflow-html .
graphify tree
```

启动 MCP stdio 服务需安装 `graphifyy[mcp]`：

```powershell
pip install "graphifyy[mcp]"
graphify . --mcp
```

---

## 版本控制建议

`graphify-out/` 是生成物，是否提交取决于用途：

- 若希望团队或 AI 助手复用同一份图谱，可以提交 `graphify-out/graph.json`、`GRAPH_REPORT.md` 等核心产物。
- 若图谱可随时本地重建，通常把 `graphify-out/` 放进 `.gitignore`。
- `cache/` 通常不建议提交。
- API Key 不应写入仓库，应放在 shell 环境变量、系统凭据或 AI 工具自己的配置中。

当前仓库若只把 Graphify 作为本地分析工具，推荐忽略：

```gitignore
graphify-out/
```

---

## 常见问题

### `graphify: command not found`

说明命令未进入 PATH。使用 venv 时改用：

```powershell
.\.venv\Scripts\python -m graphify .
```

或用 `uv tool install graphifyy` / `pipx install graphifyy` 全局安装。

### 有 API 警告，是否代表建图失败？

不一定。AST 阶段不需要 API，代码图仍可生成。API 相关警告通常影响文档、图片、论文等语义边。

### AST 提取和语义提取是否是两个独立命令？

日常使用中通常不是。`graphify .` 会编排完整流程：先做 AST，再做语义提取，最后生成图谱。二者是流水线的两个阶段，不需要分别手动执行。你需要区分的是：AST 阶段本地确定性完成，语义阶段才可能需要模型 API。

### 默认是否生成 `graph.html`？

默认生成。只有显式使用 `--no-viz` 时才跳过 HTML 可视化。

### Cursor 中的 `/graphify .` 和终端 `graphify .` 有什么区别？

目标相同，都是建图。区别在于运行环境：

- Cursor 中的 `/graphify .` 由 AI 助手调用，语义提取可使用助手已配置的模型能力。
- 终端中的 `graphify .` 由当前 shell 执行，语义提取依赖 shell 中的环境变量和本机依赖。

---

## 链接

- 官网：https://graphify.net/
- GitHub：https://github.com/safishamsi/graphify
- CLI 参考：https://graphify.net/graphify-cli-commands.html
- PyPI：https://pypi.org/project/graphifyy/

---

*最后更新：2026-05-27（整理为单仓库示例，拆清 AST / 语义提取、API 来源与图谱生成行为）*

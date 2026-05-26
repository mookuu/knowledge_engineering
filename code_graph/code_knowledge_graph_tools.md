# 项目 / 代码知识图谱工具整理

面向 **AI 编程助手、Code Review、大仓库上下文压缩** 场景的代码结构图谱（Knowledge Graph / Code Graph）工具速览。  
与「纯向量 RAG」不同：这类工具多基于 **AST / 调用图 / 依赖图**，回答「谁调谁、改一处影响哪」等结构问题。

---

## 一、为什么要用代码知识图谱

| 痛点 | 图谱能做什么 |
|------|----------------|
| 每次让 AI 读全仓库，Token 爆炸 | 按符号/调用链只拉相关文件 |
| 「改这个函数会影响谁？」说不清 | Blast radius / 影响面分析 |
| 文档与代码脱节 | 结构 +（部分工具）语义聚类 |
| 多语言单体/微服务边界模糊 | 跨文件 import、调用、服务依赖边 |

典型数据模型：**节点**（文件、类、函数、模块）+ **边**（调用、继承、导入、测试覆盖、可选语义相似）。

---

## 二、主流工具分类

### 1. 开源 + MCP / AI 助手集成（个人/团队最常用）

#### [code-review-graph](https://github.com/tirth8205/code-review-graph)

- **定位**：本地持久化代码图谱，为 Claude Code / Cursor / Codex / Gemini CLI / Copilot 等提供 MCP。
- **技术**：Tree-sitter 解析 AST → 图（节点/边）→ 增量更新（hash diff，大仓库秒级重索引）。
- **亮点**：
  - Blast radius：变更文件的调用方、被依赖方、相关测试
  - 官方称 Review 场景约 **6.8×** 省 Token，日常任务最高约 **49×**（需结合项目实测）
  - **19+** 语言，支持 Jupyter / Databricks 笔记本
  - `pip install code-review-graph` → `install`（自动写各平台 MCP）→ `build`
- **协议**：MIT | **形态**：Python CLI + MCP（约 22 个工具）
- **本仓库用法**：见 [code_review_graph.md](code_review_graph.md)（MCP 配置、`CRG_REPO_ROOT`、建图/增量、可视化、与 Graphify 分工）。

```bash
pip install code-review-graph
code-review-graph install --platform cursor   # 或 claude-code / codex 等
code-review-graph build
```

- **官网**：https://code-review-graph.com

---

#### [Graphify](https://graphify.net/)

- **定位**：开源 **Skill**，为 AI 助手构建可查询知识图谱（代码、文档、论文、图表）。
- **技术**：Tree-sitter 静态分析 + LLM 语义抽取；NetworkX + Leiden 聚类；可导出交互可视化。
- **亮点**：宣称约 **71.5×** Token 压缩（宣传数据）；适配 Claude Code、OpenAI Codex、Cursor 等。
- **形态**：Skill / 工作流，偏「知识库 + 图谱」而不只是 Review。
- **本仓库用法**：见 [graphify.md](graphify.md)（安装、`/graphify`、query/path/explain、与 code-review-graph 分工）。

---

#### [OpenTrace](https://github.com/opentrace/opentrace)

- **定位**：系统架构 + 代码结构 + 服务关系的知识图谱平台（2026 年前后活跃）。
- **技术**：tree-sitter WASM 解析（约 **12** 种语言）→ LadybugDB 存图 → MCP 暴露。
- **亮点**：Claude 插件 / OpenCode 插件；探索代码、依赖分析、用法查找等 Agent。
- **形态**：图谱平台 + MCP + 编辑器插件。

---

#### [Ix](https://ix-infra.com/)

- **定位**：代码库的 **持久记忆**（Persistent Memory），命令行 + AI 集成。
- **能力**：`ix map` 建图、搜索、定位定义、解释行为、影响分析。
- **亮点**：官方对比称带 Ix 的 Claude 探索任务约 **89%** Token 下降（17k vs 155k，个案）。
- **形态**：CLI + 与 Claude 等配合，偏「长期记住仓库结构」。

---

#### [CodePrism](https://rustic-ai.github.io/codeprism/)

- **定位**：Rust 实现的 **MCP Server**，图优先的代码智能。
- **亮点**：查询延迟 **&lt;50ms**（宣传）；5+ 语言；20+ MCP 工具；图可实时更新。
- **形态**：本地/服务 MCP，适合要**低延迟结构化查询**的场景。

---

#### [SourcePrep](https://codrag.io/)（Codrag）

- **定位**：MCP Server，映射 import、调用链、符号层级。
- **亮点**：**3–20×** 上下文压缩；语义搜索、blast radius、审计增强等约 **6** 个 MCP 工具；兼容 Cursor、Claude Code。
- **形态**：偏「给 Agent 的精简上下文包」，不是完整 IDE 套件。

---

### 2. 平台型 / 企业代码智能（自建索引 + 全库搜索）

#### Sourcegraph — Code Graph + SCIP

- **定位**：企业级代码搜索与 AI（Cody）；**Code Graph** 描述定义、引用、符号、文档注释。
- **技术**：[SCIP](https://sourcegraph.com/docs/code_navigation/references/indexers)（优于旧 LSIF）索引器，按语言生成元数据再上传实例。
- **亮点**：多语言精确跳转、全库引用查询；Cody 用图谱做上下文，而非纯文本切片。
- **形态**：自建 Sourcegraph 或使用云服务；适合**大 monorepo、多团队**。
- **文档**：https://sourcegraph.com/docs/cody/core-concepts/code-graph

---

#### 其他（了解即可）

| 工具/能力 | 说明 |
|-----------|------|
| **GitHub Copilot workspace / 代码库索引** | 托管在 GitHub 生态，偏产品内置，非通用本地图谱 CLI |
| **Cursor @codebase / 索引** | IDE 内置语义+结构索引，无统一开放图谱格式，与 MCP 图谱工具可并存 |
| **Neo4j + 自研解析** | 用图数据库存调用图，完全自控，成本高 |
| **Language Server / LSP** | 单文件/工作区符号，是图谱的「轻量版」，缺全库持久与 Review 工作流 |

---

## 三、对比总表（简版）

| 工具 | 开源 | 本地优先 | MCP | 多语言 AST | 增量索引 | 典型场景 |
|------|:----:|:--------:|:---:|:----------:|:--------:|----------|
| [code-review-graph](code_review_graph.md) | ✅ MIT | ✅ | ✅ | ✅ Tree-sitter | ✅ | Review、日常编码省 Token |
| Graphify | ✅ | ✅ | Skill | ✅ | 视配置 | 知识库 + 图谱 + 可视化 |
| OpenTrace | ✅ | ✅ | ✅ | ✅ ~12 | — | 架构/依赖探索、Agent 插件 |
| Ix | 部分/商业 | ✅ | 集成 | ✅ | ✅ | 持久记忆、map/影响分析 |
| CodePrism | ✅ | ✅ | ✅ | ✅ 5+ | ✅ | 低延迟 MCP 查询 |
| SourcePrep | — | ✅ | ✅ | ✅ | — | 调用链、上下文压缩 |
| Sourcegraph SCIP | 索引器开源 | 可自建 | 企业 | ✅ 多语言 | 企业流水线 | 全库导航、Cody、大团队 |

> 宣传中的 Token 倍数因仓库大小、任务类型、模型而异，选型时建议在自己的项目上实测。

---

## 四、与「向量 RAG」怎么选

| 维度 | 代码知识图谱 | 向量 RAG（chunk + embedding） |
|------|----------------|-------------------------------|
| 强项 | 调用链、定义/引用、影响面、精确符号 | 自然语言问文档、模糊语义检索 |
| 弱项 | 纯叙述性文档、产品需求原文 | 「第 327 行谁 import 我」类结构题 |
| 实践 | **结构问图谱，语义问 RAG**，可组合 | |

---

## 五、推荐选型（结合本仓库 AI 学习方向）

| 你的目标 | 建议 |
|----------|------|
| 本地 Django / Python 学习仓库 + Cursor/Claude | 优先试 **[code-review-graph](code_review_graph.md)**（安装简单、MCP 全、Python 友好） |
| 要画图、聚类、文档+代码统一图谱 | 看 **Graphify**（[graphify.md](graphify.md)） |
| 微服务、架构关系、服务依赖 | 看 **OpenTrace** |
| 公司级 monorepo、统一代码搜索 | **Sourcegraph + SCIP** |
| 只要 MCP、要低延迟查询 | **CodePrism** / **SourcePrep** |

### 最小上手（[code-review-graph](code_review_graph.md)）

通用安装：

```bash
cd your_project
pip install code-review-graph
code-review-graph install --platform cursor   # 按你用的 IDE 改
code-review-graph build
# 重启 Cursor / Claude Code 后，在对话里让助手「基于 graph 做 review」或查调用关系
```

**本仓库实例（AiBasic / django_learn_demo）**：图谱仅建在 `django_learn_demo/`，嵌套 monorepo 需设置 `CRG_REPO_ROOT`；完整步骤见 [code_review_graph.md](code_review_graph.md)。

---

## 六、核心概念速查

| 术语 | 含义 |
|------|------|
| **AST** | 抽象语法树，解析代码结构 |
| **Tree-sitter** | 多语言增量解析器，图谱工具常用 |
| **MCP** | Model Context Protocol，AI 助手调外部工具的协议 |
| **Blast radius** | 改动影响的调用方/依赖/测试范围 |
| **SCIP** | 代码智能索引交换格式（Sourcegraph 生态） |
| **GraphRAG** | 用图结构增强检索/推理（含社区摘要等） |

---

## 七、链接汇总

| 工具 | 链接 |
|------|------|
| code-review-graph | https://github.com/tirth8205/code-review-graph · 本仓库 [code_review_graph.md](code_review_graph.md) |
| Graphify | https://graphify.net/ · 本仓库 [graphify.md](graphify.md) |
| OpenTrace | https://github.com/opentrace/opentrace |
| Ix | https://ix-infra.com/ |
| CodePrism | https://rustic-ai.github.io/codeprism/ |
| SourcePrep / Codrag | https://codrag.io/ |
| Sourcegraph Code Graph | https://sourcegraph.com/docs/cody/core-concepts/code-graph |
| SCIP | https://sourcegraph.com/docs/code_navigation/references/indexers |
| Tree-sitter | https://tree-sitter.github.io/tree-sitter/ |
| MCP | https://modelcontextprotocol.io/ |

---

## 八、维护说明

- 工具迭代快，Star 数、Token 倍数、支持语言以各项目 **README / Release** 为准。
- 本文档侧重 **2025–2026** 与 AI 编程助手结合的图谱方案；有新工具可在本节下追加表格行。

*文档路径：`knowledge_engineering/code_graph/code_knowledge_graph_tools.md`*

# RAG、Skill、MCP 的区别与组合

> 结合 [llm-wiki](https://github.com/luotwo/llm-wiki) 方法论与 **mind-sync** 个人知识库实践整理。
> 相关笔记：[[harness_engineering]]、[[HelloAgents]]

## 一句话区分

| 概念 | 一句话 |
|------|--------|
| **RAG** | 问的时候再去**检索**片段，拼进上下文让模型回答 |
| **Skill** | 事先写好**工作手册**，教 Agent 何时、按什么流程做事 |
| **MCP** | 给 Agent 接上**可调用的外部能力**（API、数据库、搜索、同步等） |

三者不是互斥关系，而是知识获取、行为编排、系统连接三个不同层面。

---

## 核心对比

| 维度 | RAG（检索增强生成） | Skill（技能 / 工作流说明） | MCP（Model Context Protocol） |
|------|---------------------|----------------------------|--------------------------------|
| **解决什么问题** | 模型不知道你的私有资料 | 模型不知道**该怎么维护**知识库 | 模型**够不着**本地服务与工具 |
| **工作时机** | 每次提问时检索 | 任务匹配时加载进上下文 | Agent 决定调用时执行 |
| **知识形态** | 文档切块、索引、向量或全文 | Markdown  playbook（步骤、约定、模板） | 工具 schema + 服务端实现 |
| **是否积累** | 经典 RAG：**不积累**，每次重找 | 随 Skill 迭代而演进 | 取决于后端（可有持久化 Wiki） |
| **典型输出** | 带引用的答案 | 结构化 Wiki 页面、交叉引用、日志 | JSON 结果、文件读写、任务状态 |
| **谁维护** | 索引管道 / 向量库 | 人 + Agent 共写 Skill 与 Schema | 开发者实现 MCP Server |
| **类比** | 开卷考试前的**查资料** | 岗位**SOP / 培训手册** | 电话簿 + **远程控制台** |

---

## RAG：检索增强生成

### 经典模式

1. 把文档切成 chunk，建立索引（BM25、向量等）
2. 用户提问 → 检索 Top-K 相关片段
3. 把片段 + 问题交给 LLM 生成答案

**特点**：实现快、适合「资料很多、结构松散、一次性问答」。
**局限**（[llm-wiki](https://github.com/luotwo/llm-wiki) 的核心批评）：每次提问都在**从零拼凑**碎片，跨多篇资料的综合、矛盾标注、实体关系**不会自动沉淀**；复杂问题每次都要重新「考古」。

### mind-sync 中的 RAG 变体

mind-sync **没有**独立向量库，而是 **SQLite FTS5 全文检索 + LLM 归纳**：

```
问题 → FTS 匹配 documents_fts → 取 citation 片段
     → evidence 四档置信度（EXTRACTED / INFERRED / AMBIGUOUS / UNVERIFIED）
     → 注入 purpose.md（研究方向）→ LLM 结构化回答
     → 可选 save_to_wiki 写入 wiki/queries/
```

| 组件 | 路径 / 接口 |
|------|-------------|
| 检索 | `apps/api` SQLite FTS5，`GET /api/search` |
| 问答 | `POST /api/query`，`query_engine.py` |
| 证据 | `evidence.py` |
| 沉淀 | `data/wiki/queries/*.md` |

因此 mind-sync 的「RAG」更偏 **可信检索问答**：强调引用与置信度，并与 **摘要层**（`wiki/summaries/`）配合——摘要优先于原始长文，减轻每次从 raw 重推的负担。

### llm-wiki 对 RAG 的定位

- **小规模**：用 `wiki/index.md` 当目录，Agent 先读索引再读页面，**不必**上 embedding 基础设施
- **大规模**：可选 [qmd](https://github.com/tobi/qmd)（BM25 + 向量混合检索），CLI 或 **MCP Server** 接入

RAG 在 llm-wiki 里是**可选加速器**，不是方法论核心；核心是 **持久 Wiki 的增量编译**。

---

## Skill：技能与工作流说明

### 在 llm-wiki 里

Skill 对应仓库中的 `skill/SKILL.md`（安装到 `~/.claude/skills/llm-wiki/SKILL.md`），与 **Schema**（如 `CLAUDE.md`）分工：

| 层级 | 职责 |
|------|------|
| **Raw** | 原始资料，只读 |
| **Wiki** | LLM 维护的结构化 Markdown（实体页、概念页、摘要页） |
| **Schema / Skill** | 告诉 Agent：目录约定、命名规范、Ingest / Query / Lint 流程 |

Skill 定义三大操作：

1. **Ingest** — 读 `raw/`，写/更新 `wiki/`，维护 `index.md`、`log.md`，建立 `[[wikilink]]`
2. **Query** — 读索引与页面，综合回答；**好答案回写 Wiki**，探索也能复利
3. **Lint** — 矛盾、孤儿页、过时内容、缺失概念页

> 类比（llm-wiki 原文）：Obsidian 是 IDE，LLM 是程序员，**Wiki 是代码库**；Skill 则是**编码规范 + 开发流程**。

### 在 Cursor 里

Cursor Agent Skills（`SKILL.md`）同样是 **触发式工作手册**：

- YAML frontmatter：`name`、`description`（匹配用户意图的关键词）
- 正文：步骤、模板、禁忌、项目约定

与 llm-wiki Skill **同构**：不是运行时 API，而是 **何时读、读什么、按什么顺序改哪些文件**。

### 与 RAG 的本质区别

| | RAG | Skill |
|---|-----|-------|
| 内容 | 你的**资料** |  Agent 的**操作说明** |
| 更新 | 随文档索引更新 | 随工作流演进人工/Agent 改 Skill |
| 失败模式 | 检错 chunk、幻觉 | 流程漏步、未 Lint、未回写 Wiki |

**Skill 不负责「找到第 7 页说了什么」**；它负责 **「找到之后如何整理进 Wiki、如何检查健康」**。

---

## MCP：Model Context Protocol

### 是什么

MCP 是 **Agent 与外部系统之间的标准工具协议**：Host（如 Cursor）加载 MCP Server，暴露带 schema 的 `tools`（及可选 `resources`），模型在对话中 **选择并调用**。

### mind-sync 的 MCP 层

项目 `apps/mcp/server.py` 将 REST API 封装为工具，例如：

| 工具 | 作用 |
|------|------|
| `sync_sources` / `sync_status` | 索引同步 |
| `search_docs` / `browse_docs` | 检索与浏览 |
| `query_wiki` | 问答 + 可选保存到 queries |
| `lint_wiki` / `wiki_graph` | 质量与链接图谱 |
| `get_purpose` | 读取研究方向 |

配置见 mind-sync 的 `.cursor/mcp.json` 与 `docs/CURSOR_MCP_SETUP.md`。

**MCP 不做「教 Agent 写 Wiki」**——那是 Rule / Skill；**MCP 负责在 Cursor 里一键调用 mind-sync 后端**。

### 与 Skill 的区别

| | Skill | MCP |
|---|-------|-----|
| 载体 | Markdown 指令 | JSON-RPC 工具协议 |
| 执行 | 模型读文本后**自己**读文件、改仓库 | 调用 Server **返回结构化结果** |
| 边界 | 软约束（可被忽略） | 硬接口（权限、超时、错误码） |
| 典型用途 | Ingest 步骤、命名规范 | 搜索 API、触发同步、跑 Lint |

### 与 RAG 的关系

MCP **可以暴露 RAG 能力**（例如 `search_docs`、`query_wiki`），也可以暴露 **非检索** 能力（同步、图谱、部署）。
RAG 是 **一种后端能力**；MCP 是 **把能力接到 Agent 的插头**。

llm-wiki 提到 qmd 同时提供 CLI 与 MCP Server——检索本身仍是 RAG，**接入方式**是 MCP。

---

## 三者如何协同（推荐栈）

以 **llm-wiki 方法论 + mind-sync 工程化** 为例：

```text
┌─────────────────────────────────────────────────────────┐
│  Cursor Agent                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Skill / Rule │  │  MCP Tools   │  │  直接读仓库   │  │
│  │ 工作流手册    │  │ search/query │  │ 改 wiki md   │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
└─────────┼─────────────────┼─────────────────┼──────────┘
          │                 │                 │
          v                 v                 v
   Ingest/Query/Lint   FTS + LLM 问答     持久 Wiki 页面
   约定与模板          （RAG 层）          （复利资产）
          │                 │                 │
          └─────────────────┴─────────────────┘
                            │
                    sources / raw → summaries / wiki
```

| 场景 | 用什么 |
|------|--------|
| 剪藏文章、整理成实体页/概念页 | **Skill**（Ingest 流程）+ 手改/Agent 写 Markdown |
| 「Harness Pipeline 有哪些 Stage？」 | **MCP** `query_wiki` 或 Web 问答（内建 **RAG**） |
| 全文搜关键词、按主题浏览 | **MCP** `search_docs` / `browse_docs` |
| 检查断链、孤儿页、过期摘要 | **Skill**（Lint 清单）+ **MCP** `lint_wiki` |
| 资料量极大、索引页不够 | 加 **RAG** 引擎（qmd / 向量库），经 **MCP** 或 API 暴露 |

**复利来自 Wiki（Skill 驱动维护），可信来自 RAG（检索 + 引用），效率来自 MCP（IDE 内一键调用）。**

---

## 常见误解

| 误解 | 澄清 |
|------|------|
| 「上了 MCP 就不需要 RAG」 | MCP 只是协议；检索仍要在 Server 里实现（FTS、向量等） |
| 「Skill 就是长 Prompt」 | Skill 含**触发条件、多步工作流、文件约定**，可版本化管理 |
| 「RAG 可以替代 Wiki」 | RAG 回答完即散；Wiki 保留交叉引用、矛盾标注与综合结论 |
| 「llm-wiki 反 RAG」 | 反的是**只做 RAG、不做持久 Wiki**；大规模仍可用 RAG 辅助 |
| 「mind-sync 等于 llm-wiki」 | mind-sync 多了 **API、FTS 索引、证据分级、Docker、MCP**；Wiki 层理念一致 |

---

## 选型速查

| 你的目标 | 优先建设 |
|----------|----------|
| 私有文档问答、要快 | RAG（或 mind-sync 开箱 FTS + query） |
| 知识要越积越厚、可浏览图谱 | Skill + 持久 Wiki（llm-wiki 模式） |
| 在 Cursor 里调自己的后端 | MCP Server |
| 团队规范、防 Agent 乱改 | Skill + Rule + Lint |
| 答案必须可审计 | RAG + 引用 + evidence（mind-sync 做法） |

---

## 参考

| 来源 | 链接 / 路径 |
|------|-------------|
| llm-wiki 理念 | https://github.com/luotwo/llm-wiki · `llm-wiki.md` |
| llm-wiki Skill | https://github.com/luotwo/llm-wiki/blob/master/skill/SKILL.md |
| mind-sync 工作流 | `mind-sync/docs/MIND_SYNC_WORKFLOW.md` |
| mind-sync MCP | `mind-sync/docs/CURSOR_MCP_SETUP.md` · `apps/mcp/server.py` |
| MCP 规范 | https://modelcontextprotocol.io |
| 驾驭工程（周边概念） | [[harness_engineering]] |

---

## 归档说明

- **位置**：`knowledge_engineering/agents/RAG_SKILL_MCP.md`
- **索引**：由 mind-sync `sources.yaml` 挂载 `knowledge_engineering` 源，同步后可检索
- **更新**：2026-05-30 — 初版，对照 llm-wiki v1.1 Skill 与 mind-sync FTS 问答架构

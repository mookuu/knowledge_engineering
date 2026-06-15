# 知识库工程 — 功能可行性分析（修正版）

> 基于已有 mind-sync 基础设施，非从零假设

---

## 现有基础设施总览

在分析之前，先明确 two 个项目各自的角色和已有能力：

```
mind-sync（引擎层 — 已跑通）
├── sources.yaml 多源同步（local / GitHub / Web）
├── SQLite FTS5 全文检索（BM25 排序 + 分类权重）
├── Query Engine（LLM 问答 + 无 LLM 降级）
├── Evidence 系统（四档置信度）
├── Wiki 沉淀（summaries / queries / 自动导航）
├── Lint 引擎（断链 / 孤岛 / 过期检测）
├── 三层接口：REST API / CLI / MCP
├── Docker 编排（docker-compose.yml / .prod.yml）
└── CI 测试套件（30+ 测试文件）

knowledge_engineering（内容层 — 纯文档）
├── 按模块组织的 Markdown 笔记（agents/ django/ server/ 等）
├── 无检索机制
├── 无自动化流程
└── 目标是作为数据源之一挂载到 mind-sync
```

---

## 功能一：无 LLM 时，源文件 → Wiki → 知识检索/沉淀

### 原分析结论

❌ "需要从零搭建 MkDocs + 自己写检索"

### 修正结论

✅ **无需搭建。mind-sync 已经完整实现。**

### 实际实现路径

```
知识工程笔记（.md）
    │  放在 knowledge_engineering/ 下
    ▼
sources.yaml 配置
    │  type: local, path: knowledge_engineering/, include: "**/*.md"
    ▼
mind-sync sync（增量 mtime/sha1 比较）
    ▼
SQLite FTS5 全文索引
    ├── BM25 排序
    ├── 分类权重（summary=1.2, query=1.1, source=1.0）
    └── 中文支持
    ▼
三种检索方式，均不需 LLM
    ├── mind_sync search <query>          ← CLI
    ├── MCP search_docs(query, category)  ← IDE 内调用
    └── GET /api/search?q=                ← Web 界面
```

### 无 LLM 的工作流沉淀

```
源文件（笔记 / 代码 / 网页）
    │  通过 sources.yaml 的 type: local / github / web 同步
    ▼
mind-sync 同步 → FTS 索引
    │
    ▼
┌── 有 LLM ──┬── 无 LLM ──┐
│ Query      │ FTS 直接    │
│ Engine     │ 检索出结果   │
│ (归纳回答)  │            │
└────────────┴────────────┘
    │              │
    ▼              ▼
保存为 wiki/queries/*.md    ← 沉淀（两种模式都有）
```

### 实现步骤

| 步骤 | 操作 | 预估时间 |
|---|---|---|
| 1 | 在 `mind-sync/sources.yaml` 增加 `knowledge_engineering` 源 | 5 分钟 |
| 2 | （可选）创建 `inbox/` 目录作为碎片素材暂存区，也加入 sources.yaml | 5 分钟 |
| 3 | 执行 `mind_sync sync` 全量同步 + 索引重建 | 几分钟 |
| 4 | 测试查询：`mind_sync search "xxx"` | — |

### 对比原方案

| 维度 | MkDocs 方案（原分析） | mind-sync 方案（实际） |
|---|---|---|
| 搭建时间 | ~30 分钟 | ~10 分钟（配置 sources.yaml） |
| 搜索质量 | 基础中文分词 | BM25 + 分类权重 + 证据置信度 |
| 检索方式 | 仅 Web 浏览 | CLI / MCP / API 三种 |
| 沉淀能力 | 无 | 自动保存问答为 queries/*.md |
| 增量更新 | 需手动 build | 增量 mtime 比较 |
| 多源支持 | 仅本地 | local / GitHub / Web 三源 |
| 离线可用 | ✅ | ✅ |
| 依赖 | MkDocs + Python | mind-sync（已有） |

### 风险

| 风险 | 缓解 |
|---|---|
| mind-sync 有 bug 或未覆盖场景 | 源码在手，30+ 测试覆盖了核心路径 |
| sources.yaml 配置错误 | 已有 CI 测试验证配置解析 |
| 中文搜索精度不够 | 可加 jieba 分词插件（目前 FTS5 按字/词匹配） |

---

## 功能二：有 LLM 时，Karpathy 式 raw → Wiki → 沉淀

### 原分析结论

✅ 可行，中等成本。需要写 ingest Skill + 孤岛检测。

### 修正结论

✅ **核心流程已跑通，只需将 Cursor Skill 转为 Reasonix Skill 格式。**

### Karpathy 方法论在 mind-sync 中的对应

| Karpathy 原则 | mind-sync 实现 |
|---|---|
| **写，不是存** | Ingest Skill 流程：素材 → 人工审阅 → 摘要写入 |
| **连接** | Summary 模板的 `tags:` 和 `related:` 字段显式链接 |
| **迭代** | Lint Skill 定期扫描孤岛/过期/断链，建议重写/合并 |
| **结构涌现** | 不预定义分类，先写，`wiki_nav.py` 自动生成导航结构 |

### 现状：三个生产级 Skill 已经能用

这三个 Skill 目前是 Cursor 格式，需要转为 **Reasonix `/skill` 格式**：

| Skill | Cursor 位置 | 做什么 | 转 Reasonix 成本 |
|---|---|---|---|
| **Ingest**（素材→摘要） | `.cursor/skills/mind-sync-ingest/SKILL.md` | sync → search → write → re-index → lint | ~20 分钟 |
| **Query**（问答沉淀） | `.cursor/skills/mind-sync-query/SKILL.md` | get_purpose → query_wiki → check evidences → save | ~15 分钟 |
| **Lint**（质检） | `.cursor/skills/mind-sync-lint/SKILL.md` | sync → lint_wiki → fix stale-summary / broken-links / orphans | ~15 分钟 |

### 实际实现路径

```
原始素材（URL / 对话 / 代码 / 笔记）
    │
    ▼
┌──────────────────────────────────────┐
│  Reasonix /ingest Skill（转写后）      │
│                                      │
│  1. 接收素材 → 写入 inbox/           │
│  2. 调用 LLM 提炼（标签/摘要/关联）    │
│  3. 写入 summaries/                  │
│  4. 触发 mind-sync 重索引             │
│  5. Lint 检查                        │
└──────────────────────────────────────┘
    │
    ┌──────── 人工审阅修改 ────────┐
    ▼                              ▼
summaries/（结构化沉淀）          queries/（问答沉淀）
    │                              │
    ▼                              ▼
wiki_nav.py 自动更新导航       重新索引，纳入 FTS5
```
                    
### 沉淀 vs 不沉淀的关键区别

已在 `agents/RAG_SKILL_MCP.md` 中明确阐述：

| 模式 | 行为 | 结果 |
|---|---|---|
| **纯 RAG 查询** | 每次从源文件检索 + LLM 归纳 | 每次重新算，不保留 |
| **Wiki 沉淀** | 回答后保存为 queries/*.md，之后 FTS 直接命中 | 复利积累，不重复问 |

### 实现步骤

| 步骤 | 操作 | 预估时间 |
|---|---|---|
| 1 | 用 `install_skill` 创建 Reasonix 版 Ingest Skill | ~20 分钟 |
| 2 | 创建 Reasonix 版 Query Skill | ~15 分钟 |
| 3 | 创建 Reasonix 版 Lint Skill | ~15 分钟 |
| 4 | 验证：跑一遍 Ingest → Query → Lint 全流程 | ~10 分钟 |

---

## 总结：新可行性结论

| 维度 | 功能一（无 LLM） | 功能二（有 LLM） |
|---|---|---|
| **可行性** | ✅ 直接可用 | ✅ 核心已跑通 |
| **需要做的事** | sources.yaml 加一行配置 | 转写 3 个 Reasonix Skill |
| **预估时间** | 10 分钟 | 50 分钟 |
| **依赖** | mind-sync（你已有的） | mind-sync + Reasonix |
| **无 LLM 兜底** | FTS5 直接检索 + 证据引擎 | 不需要 LLM 也能查 |
| **重复造轮子** | ❌ 不需要 | ❌ 不需要 |

### 建议推进顺序

1. **今天就能做** — 把 `knowledge_engineering/` 加到 `mind-sync/sources.yaml`，跑一次 sync 验证检索
2. **本周做** — 转写三个 Reasonix Skill（Ingest / Query / Lint）
3. **以后做** — 搭 Graphify 图谱可视化查询（已在 `code_graph/graphify.md` 中说明）

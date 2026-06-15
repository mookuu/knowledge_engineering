# Karpathy LLM Wiki — AI 驱动的个人知识库

> Andrej Karpathy（前 Tesla AI 总监、OpenAI 联合创始人）提出的知识管理范式。
> 核心思想：用 LLM 替代人手动整理、分类、维护知识库，形成"摄入 → 编译 → 问答 → 回流"的自动闭环。

## 核心理念

传统笔记靠人手动整理、归类、维护，而 LLM 可以自动完成这些工作，将知识库从一个"被动存储"变成一个"主动管理的智能系统"。

关键在于 **可写**——RAG 只读不写，知识不会增长；LLM Wiki 在每次问答中沉淀新知识，越用越丰富。

---

## 一、三层架构

```
┌─────────────────────────────────────────────────┐
│                   Raw                            │
│   原始层：sources/、笔记、网页剪藏、代码片段等      │
│   只读，不修改                                    │
└───────────────────────┬─────────────────────────┘
                        │ Ingest
                        ▼
┌─────────────────────────────────────────────────┐
│                   Wiki                           │
│   知识层：summaries/ + queries/ + index + log    │
│   LLM 维护的结构化 Markdown，人可读可编辑          │
└───────────────────────┬─────────────────────────┘
                        │ 遵循
                        ▼
┌─────────────────────────────────────────────────┐
│                   Schema                         │
│   规则层：SCHEMA.md、模板、操作规范、置信度分级     │
│   告诉 Agent「怎么维护」知识库                     │
└─────────────────────────────────────────────────┘
```

| 层 | 角色 | 内容 | 可写？ |
|----|------|------|--------|
| **Raw** | 原始素材 | `sources/`、网页剪藏、PDF、代码片段、外部笔记 | 只读 |
| **Wiki** | 知识库 | `summaries/`（摘要）、`queries/`（问答沉淀）、`index.md`（目录）、`log.md`（时间线） | **LLM 自动维护** |
| **Schema** | 规则约束 | `SCHEMA.md`、模板、Skill 工作流定义 | 人工维护 |

> 类比（llm-wiki 原文）：Obsidian 是 IDE，LLM 是程序员，**Wiki 是代码库**；Schema/Skill 则是**编码规范 + 开发流程**。

### ① Raw 层（原始素材）

原始资料，**只读不修改**。来源包括：

- **本地笔记**：`sources/` 下的 Markdown 笔记
- **网页剪藏**：Obsidian Web Clipper / 浏览器扩展保存
- **GitHub 仓库**：clone 到本地的代码/文档
- **PDF/文档**：手动放入的原始文件
- **代码片段**：项目中提取的代码块

Raw → Wiki 的转换方向是**单向**的：原始资料只作为 Ingest 的输入，不会被修改。如果 Raw 更新了，Lint 会检测 `stale-summary` 标记过时摘要，触发重新 Ingest。

### ② Wiki 层（知识库）

LLM 维护的**结构化 Markdown 知识库**，包含四大组件：

| 组件 | 路径 | 说明 | 维护方式 |
|------|------|------|----------|
| **摘要** | `summaries/{topic}/{slug}.md` | 对 Raw 素材的结构化学习摘要 | Ingest 生成，File Back 追加 |
| **问答沉淀** | `queries/{timestamp}_{slug}.md` | Q&A 记录，带 evidence 引用 | Query 时自动保存 |
| **目录** | `index.md` | 按 topic 分类的摘要/问答导航 | **自动重建**，禁止手改 |
| **时间线** | `log.md` | Append-only 操作事件日志 | **自动追加**，禁止手改 |

目录结构：

```
data/wiki/
├── SCHEMA.md              ← Schema 层
├── index.md               ← Wiki 层（自动生成）
├── log.md                 ← Wiki 层（自动生成）
├── summaries/             ← Wiki 层
│   ├── topic-a/
│   │   ├── page1.md
│   │   └── page2.md
│   └── topic-b/
│       └── page3.md
└── queries/               ← Wiki 层
    └── 20260615_qa-example.md
```

每个摘要文件的 frontmatter 示例：

```yaml
---
type: summary
topic: prompt-engineering
tags: [chain-of-thought, reasoning]
sources:
  - knowledge_engineering/notes/cot-intro.md
confidence: extracted
updated: 2026-06-15
---
```

### ③ Schema 层（规则约束）

该层定义了整个 Wiki 的**行为边界和质量标准**，是 Raw → Wiki 转换的规则依据。

```
SCHEMA.md
├── 页面类型：summary（摘要）| query（问答）
├── 摘要 frontmatter 必填字段：
│   ├── type / topic / tags / sources
│   ├── confidence（置信度分级）
│   │   ├── extracted    — 直接来自原文，高可信
│   │   ├── inferred     — LLM 推理得出，中等
│   │   ├── ambiguous    — 存在歧义
│   │   └── unverified   — 待核实
│   └── updated（最后更新日期）
├── Ingest 规范：
│   ├── 必须引用 sources（不可编造）
│   ├── 必须使用统一模板
│   └── 写入后须重新索引 + Lint
├── Query 规范：
│   ├── 必须检索库内证据，不可靠对话记忆
│   ├── UNVERIFIED 证据不可表述为确定事实
│   └── 可自动保存至 queries/ 沉淀
└── Lint 规范：
    ├── stale-summary：源新摘要旧
    ├── broken-link：断链
    ├── orphan：孤儿页
    └── thin-content：内容过短
```

**Schema 的作用**：没有规则约束，LLM 生成的摘要格式不一、质量不可控、来源不可追溯。Schema 确保所有操作**可重复、可质检、可追溯**。

---

## 二、四步工作流：Ingest → Compile → Query → File Back

```
                ┌──────────────┐
                │   原始素材     │
                │ 网页/PDF/笔记  │
                └──────┬───────┘
                       │
                       ▼ ①
                ┌──────────────┐
                │   Ingest     │  LLM 读取 + 结构化摘要
                │   （摄入）     │  写入 summaries/{topic}.md
                └──────┬───────┘
                       │
                       ▼ ②
                ┌──────────────┐
                │   Compile    │  重建 index.md + log.md
                │   （编译）     │  重新索引至搜索引擎
                └──────┬───────┘
                       │
                       ▼ ③
                ┌──────────────┐
                │   Query      │  自然语言问答
                │   （问答）     │  带 evidence 引用
                └──────┬───────┘
                       │
             ┌─────────┴─────────┐
             │                   │
             ▼                   ▼
     ┌──────────────┐    ┌──────────────┐
     │  File Back   │    │    结束      │
     │   （回流）     │    │  无新知识沉淀  │
     │ 新知识→summaries│    └──────────────┘
     └──────┬───────┘
            │
            ▼ (回到 ② Compile，重新索引)
     导航层自动更新
```

### ① Ingest（摄入）

将原始素材转变为结构化摘要。

```
原始素材（网页/PDF/笔记）
    │
    ▼
① 同步素材到本地（sync_sources）
    │
    ▼
② LLM 阅读原文 → 生成结构化摘要
    ├── 标题 / 核心结论（3-5 条可检索要点）
    ├── 标签分类（自动打标）
    ├── confidence 分级（extracted / inferred / ambiguous / unverified）
    └── 关联已有知识点（wiki 内链 [[...]]）
    │
    ▼
③ 写入 summaries/{topic}/{slug}.md
    ├── frontmatter 遵循 SCHEMA
    └── 正文使用统一模板
```

**遵循规则**：必须引用 `sources:`，不可编造结论；写入后须重新索引。

### ② Compile（编译）

将摘要文件**编译**为可检索的导航结构和搜索引擎索引。这是从"一堆 Markdown 文件"到"可用知识库"的关键步骤。

```
新增/修改了 summaries/ 下的文件
    │
    ▼
① 重建 index.md
    ├── 扫描 summaries/ 和 queries/ 下所有 *.md
    ├── 读取 frontmatter + 首段摘要
    ├── 按 topic 分组生成目录
    └── 写入 index.md
    │
    ▼
② 追加 log.md
    └── 记录本次操作事件（时间 + 操作类型 + 详情）
    │
    ▼
③ 重新索引搜索引擎
    └── 将新/变更文件索引到 SQLite FTS，使 Query 阶段可检索
```

**触发时机**：Ingest 之后、File Back 之后、手动触发 rebuild。

### ③ Query（问答）

基于已编译的知识库进行带证据的问答。

```
用户提问："什么是 RLHF？"
    │
    ▼
① 预检：搜索 summaries/ 看是否已有相关摘要
    │
    ▼
② query_wiki(question, save_to_wiki=true)
    ├── 检索搜索引擎（基于 FTS / embedding）
    ├── LLM 综合多个摘要 + 原始素材证据
    └── 返回带 [n] 引用的回答（对应 evidences 列表）
    │
    ▼
③ 结果解读
    ├── EXTRACTED > INFERRED > AMBIGUOUS > UNVERIFIED
    └── 引用标注 source_id/rel_path
    │
    ▼
④ 沉淀（save_to_wiki=true时）
    └── 自动写入 queries/{timestamp}_{slug}.md
        更新 index.md / log.md
```

**遵循规则**：不可用对话记忆替代库内检索；UNVERIFIED 证据不可表述为确定事实。

### ④ File Back（回流）—— 闭环关键

问答过程中产生的新知识**自动写回 Wiki**，形成学习闭环。

```
Query 给出了回答
    │
    ├── 回答中产生了新的见解/总结/关联
    │   （这些知识原本不在 summaries/ 中）
    │
    ▼
LLM 判断：这段新知识是否值得写入 Wiki？
    │
    ├── 是
    │   ├── 生成或追加到 summaries/{topic}.md
    │   └── → 回到 Compile ②（重建索引 + 导航）
    │
    └── 否 → 丢弃（避免噪音污染）
```

**File Back 的意义**：如果没有回流，知识库只会单向消耗（只读不写），问答产生的洞见无法沉淀。回流让 Wiki **在每次交互中自我生长**。

---

## 三、与传统笔记工具的对比

| 维度         | 传统笔记（Notion/Obsidian） | Karpathy LLM Wiki                          |
| ------------ | --------------------------- | ------------------------------------------ |
| **整理**     | 手动分类、建文件夹          | LLM 自动摘要 + 打标                        |
| **索引**     | 人手工维护目录              | 自动生成 `index.md`                        |
| **检索**     | 关键词搜索                  | 自然语言语义问答                           |
| **维护**     | 过期笔记无人管              | Lint 自动检测 stale 条目                   |
| **架构分层** | 无明确分层                  | **Schema → Wiki → Raw** 三层架构           |
| **工作流**   | 单向：记录 → 遗忘           | 闭环：Ingest → Compile → Query → File Back |
| **规模**     | 人脑容量限制（~几百条）     | 可扩展到数千上万条                         |
| **闭环**     | 知识单向消耗，无自动回流    | File Back 回流：问答新知识自动写回 Wiki    |

---

## 四、完整工作流示例

```
场景：看到一篇关于"Chain of Thought"的好文章
                   │
         ══════════╤══════════
         ║ ① Ingest         ║
         ╚═════════╤══════════
                   │
         LLM 读取文章
         生成摘要：CoT 原理、论文引用、关键例子
         自动打标签：[prompt-engineering, reasoning, chain-of-thought]
         关联已有条目："few-shot" 笔记
                   │
                   ▼
         ══════════╤══════════
         ║ ② Compile        ║
         ╚═════════╤══════════
                   │
         index.md 更新：
           prompt-engineering
           ├── Chain of Thought 详解
           ├── Few-Shot Prompting
           └── System Prompt 最佳实践
         log.md 追加 ingest 事件
         搜索引擎重建索引
                   │
                   ▼
         ══════════╤══════════
         ║ ③ Query          ║
         ╚═════════╤══════════
                   │
         提问："CoT 和 Few-Shot 什么关系？"
         → 检索 summaries/ → LLM 综合回答
         → 返回带引用结果，沉淀到 queries/
                   │
                   ▼
         ══════════╤══════════
         ║ ④ File Back      ║
         ╚═════════╤══════════
                   │
         回答中 LLM 发现新视角：
         "CoT 本质是一种显式的中间推理"
         判断值得写入 Wiki
         → 追加到 summaries/cot-explained.md
                   │
                   ▼
         （回到 ② Compile，index/log 自动更新）
                   │
                   ▼
         ══════════╤══════════
         ║ Lint（贯穿始终）  ║
         ╚═════════╤══════════
                   │
         一个月后 Lint 检测：
         → 原文有更新？标记 stale 建议重新 ingest
         → 回流产生的摘要同样参与质检
```

---

## 五、使用场景

| 场景                    | 说明                                               | 适合度     |
| ----------------------- | -------------------------------------------------- | ---------- |
| **个人知识管理（PKM）** | 阅读大量文章/论文，需要自动整理摘要、打标、检索    | ⭐⭐⭐⭐⭐ |
| **技术团队内部 Wiki**   | 自动维护技术文档、决策记录、架构说明，避免文档腐烂 | ⭐⭐⭐⭐⭐ |
| **研究笔记**            | 追踪论文进展，自动关联相关研究方向                 | ⭐⭐⭐⭐⭐ |
| **写作素材库**          | 积累写作灵感和素材，通过问答快速检索               | ⭐⭐⭐⭐   |
| **企业知识库**          | 整合内部文档、会议记录、项目复盘                   | ⭐⭐⭐     |
| **学习笔记**            | 学习新领域时自动整理知识点，形成结构化知识网络     | ⭐⭐⭐⭐⭐ |

### 不适合的场景

- **高频事务数据**（日志、交易记录）→ 适合传统数据库
- **需要强一致性的事务系统** → 适合关系型数据库
- **实时性要求极高的查询** → 适合缓存/搜索引擎

---

## 六、与 RAG 的区别

RAG（Retrieval-Augmented Generation）和 Karpathy LLM Wiki 都涉及"检索 + LLM"，但理念和架构完全不同。

| 对比维度            | RAG（检索增强生成）                | Karpathy LLM Wiki                                       |
| ------------------- | ---------------------------------- | ------------------------------------------------------- |
| **定位**            | 一种推理增强技术                   | 一种知识管理体系                                        |
| **数据源**          | 原始文档直接检索                   | **经过 LLM 摘要加工**的结构化 Markdown                  |
| **写入**            | 只读——文档原样存入向量库，不修改   | **可写**——Ingest 生成摘要，File Back 回流知识           |
| **架构分层**        | 无明确分层                         | **Schema → Wiki → Raw** 三层架构                         |
| **工作流**          | 单步：检索 → 生成                  | **四步闭环**：Ingest → Compile → Query → File Back      |
| **索引维护**        | 无——需手动更新文档库               | 自动——Compile 阶段重建 `index.md` + `log.md` + 搜索引擎 |
| **知识密度**        | 低——检索结果是原始段落，含大量噪音 | **高**——检索结果是 LLM 提炼后的精华摘要                 |
| **知识演化**        | 无——文档是什么就是什么             | **有**——Lint 检测过时，File Back 积累新知识             |
| **存储结构**        | 向量 embedding（不可读）           | 纯文本 Markdown（人可读、可编辑）                       |
| **一次 Query 成本** | 低——仅检索 + 生成                  | 略高——检索 + 生成 + 可能触发 File Back                  |
| **长期价值**        | 低——文档不升级，问答不沉淀         | **高**——wiki 持续生长，越用越丰富                       |

### 一句话区分

> **RAG** 是给 LLM **配了一本书**——回答时翻书引用，书不变化。
>
> **Karpathy LLM Wiki** 是给 LLM **配了一个笔记本**——不仅翻笔记回答，还边答边写新笔记。

### 可以结合使用

两者并非互斥，可以叠加：

```
原始文档 → RAG（精准引用原文）
              │
              ▼
     Karpathy LLM Wiki（提炼摘要 + 长期沉淀）
              │
              ▼
       File Back 回流（问答新知识）
```

---

## 七、关键设计原则

1. **SCHEMA 驱动** — 所有操作遵循 SCHEMA.md 定义的规则，确保格式统一、质量可控、来源可追溯
2. **Append-only log** — `log.md` 只追加不修改，保留完整历史
3. **Wiki 层自动化** — `index.md`、`log.md`、搜索引擎索引由程序自动维护
4. **四步闭环工作流** — Ingest → Compile → Query → File Back，每次操作后自动 Compile（重建索引 + 导航）
5. **File Back 回流** — 问答中产生的新知识自动写回 Wiki，知识库在每次交互中生长
6. **质检闭环** — Lint 贯穿始终，检测 stale / broken-link / orphan / thin-content
7. **LLM 作为胶水** — LLM 贯穿 ingest→compile→query→file back→lint 全流程的核心引擎

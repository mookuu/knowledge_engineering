# AI 辅助软件开发生命周期（AI-SDLC/Software Development Life Cycle）全流程

> 从 PRD 到运维，每个阶段如何利用 AI 工具（Reasonix / Cursor / Copilot 等）提效，以及各阶段可使用的 Skills（技能模板）。

## 核心原则

| 原则 | 说明 |
|---|---|
| **人机协作，AI 辅助** | AI 是副驾驶，关键决策仍由人做 |
| **渐进式交付** | 大任务拆小步，每步可验证、可回退 |
| **最小改动** | 不擅自改无关代码，不引入不必要的抽象 |
| **可验证** | 每阶段有明确完成标准（DoD, Definition of Done） |
| **记忆复用** | 跨会话记住项目偏好、架构决策、命名约定 |

## 流程全景

```
┌─────────────────────────────────────────────────────────┐
│                    AI-SDLC 全景图                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ① PRD / 需求分析 ───────────────────→ ② 技术架构设计   │
│     ↓ AI 辅助撰写/分析/拆解               ↓ AI 辅助选型  │
│     ↓ Skills: prd-writing                ↓ Skills: arch-review │
│                                                         │
│  ③ 编码实现 ─────────────────────────→ ④ 自动测试       │
│     ↓ AI 辅助编码/补全/重构              ↓ AI 辅助生成/执行 │
│     ↓ Skills: tdd-workflow, coding       ↓ Skills: test-gen  │
│                                                         │
│  ⑤ Code Review ─────────────────────→ ⑥ 部署 / CI-CD   │
│     ↓ AI 辅助审查/安全检查              ↓ AI 辅助流水线   │
│     ↓ Skills: code-review, sec-review   ↓ Skills: deploy    │
│                                                         │
│  ⑦ 运维 / 监控 / 文档 ──────────────→ (循环回到 ①)     │
│     ↓ AI 辅助排障/日志分析/文档生成      ↓ 持续迭代      │
│     ↓ Skills: debug, doc-gen                           │
└─────────────────────────────────────────────────────────┘
```

## 各阶段速览

| 阶段 | 核心交付物 | AI 主要作用 | 典型工具/模型 |
|---|---|---|---|
| [① PRD/需求](01-prd.md) | PRD 文档、用户故事、验收标准 | 分析需求、生成初稿、拆解任务 | DeepSeek / Claude / ChatGPT |
| [② 架构设计](02-architecture.md) | 架构图、技术选型、数据模型 | 对比方案、风险评估、生成骨架 | AI Coding Agent + MCP |
| [③ 编码实现](03-development.md) | 功能代码、单元测试 | 代码生成、补全、重构、解释 | Reasonix / Cursor / Copilot |
| [④ 测试](04-testing.md) | 测试用例、测试报告 | 生成测试、边界分析、Mock 数据 | AI + pytest/jest/playwright |
| [⑤ Code Review](05-code-review.md) | Review 意见、安全审计 | 自动化审查、安全检查、规范检查 | AI Coding Agent / CodeRabbit |
| [⑥ 部署/CI-CD](06-deployment.md) | 部署脚本、流水线配置 | 编写配置、排障、回滚方案 | AI + Docker / GitHub Actions |
| [⑦ 运维/文档](07-operation.md) | 运行文档、排障记录 | 日志分析、生成文档、知识沉淀 | AI Coding Agent + wiki-ingest |

## 可用 Skills 索引

以下 Skills 可在各阶段直接调用（位于 [`skills/`](skills/) 目录下）：

| Skill 名称 | 适用阶段 | 说明 |
|---|---|---|
| `prd-writing` | ① PRD | 辅助撰写/分析/细化 PRD |
| `story-splitting` | ① PRD | 将 PRD 拆解为用户故事和任务 |
| `arch-review` | ② 架构 | 辅助技术选型和架构评审 |
| `tdd-workflow` | ③ 编码 | TDD 流程：先测试再实现 |
| `coding-standards` | ③ 编码 | 按项目规范生成代码 |
| `test-generation` | ④ 测试 | 自动生成单元/集成测试 |
| `code-review` | ⑤ Review | 代码质量审查 |
| `security-review` | ⑤ Review | 安全专项审查 |
| `deploy-config` | ⑥ 部署 | 生成/审查部署配置 |
| `debug-assist` | ⑦ 运维 | AI 辅助排障分析 |
| `doc-generation` | ⑦ 文档 | 自动生成技术文档 |
| `wiki-ingest` | ⑦ 文档 | 将素材整理到知识库 |

## 通用注意事项

1. **上下文窗口管理** — AI Agent 上下文有上限，长流程应分段执行，必要时 `/new` 重启会话
2. **记忆优先** — 项目约定、架构决策、命名偏好等应 `remember` 保存，避免重复说明
3. **审核不可跳过** — AI 生成的代码/配置需人工审查后再合并
4. **安全红线** — 不将密钥/令牌硬编码；敏感操作（数据库、生产环境）需人工确认
5. **版本追踪** — 每个阶段的产物（PRD、设计、代码）都应版本化管理

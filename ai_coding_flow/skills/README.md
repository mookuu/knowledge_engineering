# AI-SDLC 配套 Skills

本目录包含 AI-SDLC 各阶段可用的 Skill 定义。每个 Skill 是对应阶段的"可复用专长说明书"，包含触发条件、操作流程和输出规范。

## 目录

| Skill | 适用阶段 | 说明 |
|---|---|---|
| [`prd-writing`](prd-writing.md) | ① PRD | 辅助撰写/分析/细化 PRD |
| [`story-splitting`](story-splitting.md) | ① PRD | 将 PRD 拆解为用户故事和任务 |
| [`arch-review`](arch-review.md) | ② 架构 | 技术选型建议和架构评审 |
| [`tdd-workflow`](tdd-workflow.md) | ③ 编码 | TDD 流程：先写测试再实现 |
| [`test-generation`](test-generation.md) | ④ 测试 | 自动生成单元/集成测试 |
| [`code-review`](code-review.md) | ⑤ Review | 代码质量审查 |
| [`security-review`](security-review.md) | ⑤ Review | 安全专项审查 |
| [`deploy-config`](deploy-config.md) | ⑥ 部署 | 生成/审查部署配置 |
| [`debug-assist`](debug-assist.md) | ⑦ 运维 | AI 辅助排障分析 |
| [`doc-generation`](doc-generation.md) | ⑦ 文档 | 自动生成技术文档 |

## 结构与格式

每个 Skill 文件使用标准 Markdown 编写，包含以下结构：

```markdown
---
name: <skill-name>
description: <一句话描述 + 触发场景>
---

# <标题>

## Quick Start
1. 第一步
2. 第二步
3. 第三步

## Checklist
- [ ] 检查点

## Output Format
输出规范

## Rules
规则说明
```

## 使用方式

- 在 AI Coding Agent（如 Reasonix）中直接描述任务 + 引用 Skill 名称
- 或在 Agent 配置中注册为正式 Skill（放在 `.reasonix/skills/` 下）

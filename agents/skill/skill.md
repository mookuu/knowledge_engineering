## Skill
Skill简单理解为给Agent的可复用专长说明书

定义：不是普通的提示词片段，而是一套带结构的能力定义。即把某类任务的""打包给Agent的能力模块
+ 触发条件：告诉Agent在什么场景下该做什么
+ 操作流程：按什么流程做
+ 输出规范：应该输出什么


作用：把某类任务固定下来，比如

+ 代码评审
+ 生成commit messages
+ 处理PDF/表格
+ 某个团队内部流程
+ 某类固定格式的生成报告

常见结构：

```
skill-name/
├── SKILL.md：必须，流程、触发条件、输出规范
├── reference.md：可选，详细规范
├── examples.md：可选，输入输出示例
└── scripts/：可选，能直接执行的脚本
```

### SKILL.md
```
---
name: code-review
description: Review code for quality, security, and maintainability. Use when reviewing pull requests, examining code changes, or when the user asks for a code review.
disable-model-invocation: true
---
# Code Review -> 给模型和人看的主题锚点

## Quick Start -> 最小可执行流程
1. Check correctness
2. Check security
3. Check readability
4. Check tests
```

name：Skill唯一标识

description：Skill的简要描述
+ 做什么
+ 什么时候使用

disable-model-invocation：可选，是否禁用模型调用，默认false

### 触发方式

1. 显示触发

    用户明确提到某个Skill，或者系统规则要求使用某个Skill

2. 自动触发

    Agent根据description里的场景描述，判断当前任务适合这个Skill

所以，description不是装饰文本，而是检索入口。Agent判断该不该用这个Skill的依据

### Skill5个关键点

1. 可发现：description要清晰描述触发场景
2. 可执行：Quick Start要明确最小可执行流程
3. 可检查：Checklist给了标准，明确检查项
4. 可控输出：Providing Feedback规定了输出风格
5. 可扩展：额外细节放到独立文件
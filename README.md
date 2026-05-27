# 知识工程（knowledge_engineering）

AiBasic 仓库内集中存放学习笔记、架构说明与工具文档（Markdown 及配图），与可运行代码工程（如 `FirstAgent/`、`django_learn_demo/`）分离，便于归档与检索。

## 目录

| 路径 | 说明 |
|------|------|
| [`django/`](django/) | Django / Python Web、Docker、项目结构等笔记 |
| [`agents/`](agents/) | Agent、ReAct、Prompt、Harness Engineering、Skill 与零碎学习备忘 |
| [`code_graph/`](code_graph/) | code-review-graph、Graphify 建图与工具选型 |

## 与代码工程的关系

- **`FirstAgent/`**：智能体示例代码（`scripts/`、`notebooks/`），文档已迁至本目录 [`agents/`](agents/) 与 [`code_graph/`](code_graph/)。
- **`django_learn_demo/`** 等：运行时代码与图谱产物仍在各子项目内；操作说明见 [`code_graph/code_review_graph.md`](code_graph/code_review_graph.md)。

## 独立仓库同步

本目录内容同步至 [github.com/mookuu/knowledge_engineering](https://github.com/mookuu/knowledge_engineering) 的 `main` 分支。

在 AiBasic 根目录执行：

```bash
bash scripts/sync-knowledge-engineering.sh
```

提交 AiBasic 且修改了 `knowledge_engineering/` 后，应推送到 `origin` 再运行上述脚本。

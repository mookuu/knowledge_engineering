# 知识工程（knowledge_engineering）

本仓库集中存放学习笔记、架构说明与工具文档（Markdown 及配图），与可运行代码工程（如 [mookuu/AI](https://github.com/mookuu/AI) 中的 `FirstAgent/`、`django_learn_demo/`）分离，便于归档与检索。

## 目录

| 路径 | 说明 |
|------|------|
| [`django/`](django/) | Django / Python Web、Docker、项目结构等笔记 |
| [`agents/`](agents/) | Agent、ReAct、Prompt、Harness Engineering、Skill 与零碎学习备忘 |
| [`code_graph/`](code_graph/) | code-review-graph、Graphify 建图与工具选型 |

## 与代码工程的关系

- **AiBasic**（[mookuu/AI](https://github.com/mookuu/AI)）：智能体与 Django 示例代码；文档链接指向本仓库。
- **`FirstAgent/`**：示例代码在 AiBasic；Agent 笔记见 [`agents/`](agents/) 与 [`code_graph/`](code_graph/)。
- **`django_learn_demo/`** 等：运行时代码与图谱产物在 AiBasic 子项目内；操作说明见 [`code_graph/code_review_graph.md`](code_graph/code_review_graph.md)。

## 本机多根工作区

常与 AiBasic、PythonBasic、learning_log 一并打开：`D:\kan\kan\Python\PythonBasic.code-workspace`。文档仅在本仓库维护，AiBasic 内不再包含 `knowledge_engineering/` 子目录。

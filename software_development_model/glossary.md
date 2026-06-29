# 软件开发模式 — 相关词汇表

> 中文 / English 对照，按主题分组。覆盖 SDLC、敏捷、Scrum、DevOps 等常见术语。

---

## A. 基础概念

| 术语 (EN) | 中文 | 释义 |
|-----------|------|------|
| **SDLC** (Software Development Life Cycle) | 软件开发生命周期 | 从需求到退役的完整过程，包含规划、分析、设计、编码、测试、部署、维护 |
| **Development Model** | 开发模式/开发模型 | 组织 SDLC 各阶段的方式（如瀑布、敏捷、DevOps） |
| **Methodology** | 方法论 | 一套有原则/实践/角色的系统化工作方式 |
| **Framework** | 框架 | 比方法论更具体的一组规则和流程（如 Scrum Framework） |
| **Process** | 流程 | 具体执行步骤序列 |

---

## B. 经典模型

| 术语 (EN) | 中文 | 释义 |
|-----------|------|------|
| **Waterfall** | 瀑布模型 | 线性顺序开发，阶段不可逆 |
| **V-Model** | V模型 | 瀑布的变体，强调开发与测试阶段一一对应 |
| **Spiral Model** | 螺旋模型 | Barry Boehm 提出，每轮迭代以风险评估为核心 |
| **Iterative** | 迭代式 | 分多轮逐步精化产品 |
| **Incremental** | 增量式 | 分块逐步追加新功能 |
| **Big Bang** | 大爆炸模型 | 无计划直接开发，资源一次性投入 |
| **RAD** (Rapid Application Development) | 快速应用开发 | 原型驱动，快速迭代，用户深度参与 |
| **Prototype Model** | 原型模型 | 先做低保真原型确认需求再正式开发 |

---

## C. 敏捷 (Agile)

| 术语 (EN) | 中文 | 释义 |
|-----------|------|------|
| **Agile Manifesto** | 敏捷宣言 | 2001 年 17 位软件专家发布的四项价值观和十二条原则 |
| **Sprint** | Sprint / 冲刺 | Scrum 中 1-4 周的固定迭代周期 |
| **Daily Standup** | 每日站会 | 15 分钟、三个问题（昨天、今天、阻碍） |
| **Sprint Review** | Sprint 评审 | Sprint 结束时向干系人演示可工作的增量 |
| **Sprint Retrospective** | Sprint 回顾 | 团队内部反思改进的会议（做什么、停什么、改什么） |
| **Timebox** | 时间盒 | 为活动设定固定时间上限 |
| **MVP** (Minimum Viable Product) | 最小可行产品 | 用最少投入验证核心假设的产品版本 |
| **MMF** (Minimum Marketable Feature) | 最小可售卖特性 | 能独立交付的最小功能集合 |

---

## D. Scrum 角色与工件

| 术语 (EN) | 中文 | 释义 |
|-----------|------|------|
| **Product Owner** | 产品负责人 (PO) | 负责 Product Backlog 优先级，代表客户/业务 |
| **Scrum Master** | Scrum 教练 (SM) | 确保 Scrum 流程被遵循，移除团队障碍 |
| **Development Team** | 开发团队 | 3-9 人跨职能自组织团队 |
| **Product Backlog** | 产品待办列表 | 按优先级排列的所有需求列表，永不全 |
| **Sprint Backlog** | Sprint 待办列表 | 当前 Sprint 要完成的 Backlog 子集 + 实现计划 |
| **Increment** | 增量 / 可交付增量 | Sprint 结束后可工作的产品增量（DoD 后的结果） |
| **DoD** (Definition of Done) | 完成定义 | 团队约定的"做完"标准清单 |
| **DoR** (Definition of Ready) | 就绪定义 | Backlog 条目可被拉入 Sprint 的门槛条件 |
| **User Story** | 用户故事 | `As a [角色], I want [目标], So that [收益]` |
| **Epic** | 史诗 | 大粒度的用户故事，可拆解为多个更小的故事 |
| **Velocity** | 速率 | 团队每个 Sprint 完成的 Story Points 历史均值 |
| **Story Point** | 故事点 | 相对估算单位，衡量复杂度而非工时 |
| **Burndown Chart** | 燃尽图 | Sprint 剩余工作量随时间下降的趋势图 |
| **Burnup Chart** | 燃起图 | 已完成工作量随时间上升的趋势图 |

---

## E. Kanban（看板）

| 术语 (EN) | 中文 | 释义 |
|-----------|------|------|
| **Kanban Board** | 看板 | 可视化工作流的面板（To Do / In Progress / Done） |
| **WIP** (Work In Progress) | 在制品 / 进行中工作 | 同时进行中的任务数量 |
| **WIP Limit** | 在制品限制 | 每列最大允许的卡片数，强制减少多任务并行 |
| **Lead Time** | 前置时间 | 从需求提出到交付的端到端时间 |
| **Cycle Time** | 周期时间 | 从开始开发到交付的时间（Leed Time 的子集） |
| **Cumulative Flow Diagram (CFD)** | 累积流量图 | 可视化各状态随时间累积的卡片数 |
| **Pull System** | 拉式系统 | 下游空闲才从上游拉取新任务（vs 推式分配） |

---

## F. 极限编程 (XP)

| 术语 (EN) | 中文 | 释义 |
|-----------|------|------|
| **Pair Programming** | 结对编程 | 两人共用一台电脑：Driver 写代码，Navigator 审查思考 |
| **Collective Code Ownership** | 代码集体所有权 | 任何成员可修改任何代码，无人独占模块 |
| **Continuous Integration (CI)** | 持续集成 | 代码频繁合并主干，每次合并触发自动化构建和测试 |
| **Sustainable Pace** | 可持续节奏 | 不过度加班，保持长期高效 |
| **Simple Design** | 简单设计 | 只做当前需要的，不做超前设计 |
| **Refactoring** | 重构 | 在不改变外部行为的前提下改进内部结构 |
| **Spike** | 探针/技术刺探 | 限时研究任务，旨在获取信息而非产出产品代码 |

---

## G. TDD / BDD

| 术语 (EN) | 中文 | 释义 |
|-----------|------|------|
| **TDD** (Test-Driven Development) | 测试驱动开发 | Red → Green → Refactor 循环 |
| **Unit Test** | 单元测试 | 对单个函数/类/模块的测试 |
| **BDD** (Behavior-Driven Development) | 行为驱动开发 | Dan North 提出，用 Given-When-Then 描述行为 |
| **Acceptance Test** | 验收测试 | 验证系统是否满足业务需求的端到端测试 |
| **Regression Test** | 回归测试 | 确保改动未破坏已有功能 |
| **Test Fixture** | 测试夹具 | 为测试准备的固定环境/数据 |
| **Mock** | 模拟对象 | 替代真实依赖的测试替身 |
| **Stub** | 桩 | 提供固定返回值的简单替代实现 |
| **Arrange-Act-Assert** | 准备-执行-断言 | 单元测试三段式结构 |

---

## H. DevOps & CI/CD

| 术语 (EN) | 中文 | 释义 |
|-----------|------|------|
| **DevOps** | 开发运维一体化 | Development + Operations 文化/实践融合 |
| **CI/CD** | 持续集成/持续交付 | CI (频繁合并+自动验证) + CD (自动部署到生产或就绪) |
| **Pipeline** | 流水线 | CI/CD 的自动化步骤链（Build → Test → Deploy） |
| **IaC** (Infrastructure as Code) | 基础设施即代码 | 用代码管理服务器/网络/配置（Terraform, Ansible） |
| **Canary Release** | 金丝雀发布 | 先让少量用户使用新版本、验证无误后全量 |
| **Blue-Green Deployment** | 蓝绿部署 | 两套完全对称的环境，切换流量完成部署 |
| **Feature Flag** | 功能开关 | 运行时开关控制功能可见性，无需重新部署 |
| **SRE** (Site Reliability Engineering) | 站点可靠性工程 | Google 提出的运维方法论，用软件工程方式做运维 |
| **SLI** / **SLO** / **SLA** | 服务指标 / 目标 / 协议 | 可靠性量化体系 |
| **DORA Metrics** | DORA 四项指标 | 部署频率、变更前置时间、故障恢复时间、变更失败率 |
| **MTTR** (Mean Time to Recovery) | 平均恢复时间 | 故障从发生到修复的平均耗时 |

---

## I. 精益 (Lean)

| 术语 (EN) | 中文 | 释义 |
|-----------|------|------|
| **Muda** | 浪费 (無駄) | 不产生价值的一切活动 |
| **Value Stream** | 价值流 | 从概念到交付的完整活动链 |
| **Kaizen** | 持续改善 | 每天/每 Sprint 的小改进累积 |
| **Just-In-Time** | 准时化 | 只在需要时做需要的事（减少 WIP） |
| **Andon Cord** | 安灯绳 | 发现问题立刻停下（质量内建） |
| **Gemba Walk** | 现场走查 | 管理者亲自到一线观察实际工作 |
| **Eliminate Waste** | 消除浪费 | 精益核心原则之一 |

---

## J. 杂项

| 术语 (EN) | 中文 | 释义 |
|-----------|------|------|
| **Iron Triangle** | 铁三角 | 范围×时间×成本 —— 三者不可同时锁定 |
| **Technical Debt** | 技术债 | 为速度牺牲代码质量，未来需要偿还的代价 |
| **Bus Factor** | 巴士因子 | 关键人物缺席时的团队风险系数 |
| **Bikeshedding** | 自行车棚效应 | 讨论简单问题时过度纠结细节（Parkinson's Law of Triviality） |
| **Conway's Law** | 康威定律 | 系统架构会反映组织的沟通结构 |
| **Brooks's Law** | 布鲁克斯法则 | 向一个已经延期的项目加人只会让它更延期 |
| **Agile Fluency Model** | 敏捷流畅度模型 | 组织敏捷成熟度的分级模型 |
| **ScrumBut** | 伪 Scrum | "我们用 Scrum，但……" —— 名义 Scrum 实际未遵循 |

---

*关联：这些术语在具体模式文档中有更详细的上下文说明。*

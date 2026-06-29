# DevOps (开发运维一体化)

> **2009 年** Patrick Debois 在比利时根特组织了第一届 DevOpsDays。DevOps 不是工具，也不是岗位——是一种**文化运动**，目标是打破开发（Dev）和运维（Ops）之间的墙。

---

## 为什么需要 DevOps

```
传统现状：Dev 与 Ops 各自为政

  Dev 团队                    Ops 团队
  "代码在我机器上能跑"         "服务器不是你的笔记本"
  "我们要快速上线新功能"       "我们要稳定，别出事"
  "这是 Ops 的问题"            "这是 Dev 的 bug"

          ↓ 矛盾 ↓

  部署是痛苦的、低频的、熬夜的
  故障排查要两边甩锅
  交付速度被隔阂严重拖慢
```

DevOps 解法：**你 Build 它，你 Run 它。**

---

## CALMS 框架

| 维度 | 含义 | 例子 |
|------|------|------|
| **C**ulture | 共享责任，不甩锅 | Dev 参与 On-Call，Ops 参与设计评审 |
| **A**utomation | CI/CD、基础设施即代码 | GitHub Actions / Jenkins / Terraform |
| **L**ean | 精益原则，消除浪费 | 缩小批次大小、限制 WIP |
| **M**easurement | 数据驱动决策 | DORA 指标、SLI/SLO、告警质量 |
| **S**haring | 知识共享、工具共享 | 内部 Runbook、Postmortem、ChatOps |

---

## DevOps 实践金字塔

```
        ┌──────────┐
        │  持续改进  │ ← 事后反思 (Blameless Postmortem)
       ┌┴──────────┴┐
       │   监控告警   │ ← SLI/SLO/SLA / 可观测性
      ┌┴────────────┴┐
      │   持续交付 CD  │ ← 蓝绿部署 / 金丝雀 / Feature Flag
     ┌┴──────────────┴┐
     │   持续集成 CI   │ ← 自动构建 / 测试 / 安全扫描
    ┌┴────────────────┴┐
    │  基础设施即代码    │ ← Terraform / Ansible / Docker / K8s
   ┌┴──────────────────┴┐
   │  版本控制一切        │ ← 代码 / 配置 / 环境 / Pipeline 全部 Git
  └──────────────────────┘
```

---

## CI/CD 流水线

```
代码提交 ──→ Build ──→ Unit Test ──→ Static Analysis ──→ Package
                                                    │
         ┌──────────────────────────────────────────┘
         ↓
  Staging Deploy ──→ Integration Test ──→ Approval Gate
                                                │
         ┌──────────────────────────────────────┘
         ↓
  Production Deploy (Canary → Blue-Green → Rolling)
         │
         ↓
  Monitoring (Metrics / Logs / Traces / Alerts)
```

---

## DORA 四项指标

| 指标 | 精英水平 | 中位水平 |
|------|---------|---------|
| **部署频率** (Deployment Frequency) | 按需（每日多次） | 每周~每月 |
| **变更前置时间** (Lead Time for Changes) | 不到 1 小时 | 1 周~1 月 |
| **故障恢复时间** (MTTR) | 不到 1 小时 | 1 天~1 周 |
| **变更失败率** (Change Failure Rate) | 0-15% | 0-15% |

> 数据来源: *Accelerate State of DevOps Report* (DORA/Google Cloud)

---

## DevOps vs 其他

| 对比 | 关系 |
|------|------|
| vs **敏捷** | 敏捷管"怎么做软件"；DevOps 管"怎么交付和运行软件"——互补而非替代 |
| vs **SRE** | SRE 是 Google 对 DevOps 的具体实现；SRE 更强调量化和工程化 |
| vs **平台工程** | 平台工程是为开发团队提供自助服务平台，是 DevOps 的规模化手段 |

---

## 常见误解

| 误解 | 真相 |
|------|------|
| "招个 DevOps 工程师" | DevOps 是文化，不是职位名（尽管行业确实有这岗位） |
| "有 Jenkins = 有 DevOps" | 工具是必要条件，但远不充分——文化才是核心 |
| "DevOps 就是自动化" | 自动化是手段，目标是**快速、安全、稳定地交付价值** |
| "DevOps = 不需要运维" | 是 Dev 和 Ops 协作，不是 Ops 消失 |

---

## 相关词汇

见 [glossary.md](glossary.md) — CI/CD / Pipeline / IaC / Canary Release / Blue-Green / DORA / SRE / MTTR

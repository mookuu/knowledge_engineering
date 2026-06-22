# 阶段六：部署 / CI-CD

## 概述

部署阶段将经过测试和审查的代码发布到目标环境。AI 在此阶段的作用是**协助编写和审查部署配置、排障部署失败、生成 CI/CD 流水线配置**。部署涉及生产环境操作，**高风险操作必须人工确认**。

## 核心交付物

| 交付物 | 说明 | AI 可参与程度 |
|---|---|---|
| CI 配置文件 | GitHub Actions / GitLab CI / Jenkinsfile | 高 — 从项目结构生成 |
| Dockerfile | 容器镜像构建 | 高 — 从语言/框架生成 |
| Docker Compose / K8s 配置 | 多服务编排 | 中 — 辅助生成 |
| 部署脚本 | 自动化部署脚本 | 中 — 辅助生成 |
| 回滚方案 | 失败时的回滚步骤 | 中 — 辅助编写 |

## AI 辅助工作流

```
代码合并到主分支
    ↓
CI 触发 → 自动构建 + 测试 + 静态分析
    ↓
AI 辅助 → 生成/审查部署配置
    ↓
部署到 Staging 环境
    ↓
AI 辅助 → Smoke Test（冒烟测试）
    ↓
人工确认 → 可以发布生产
    ↓
部署到生产环境（蓝绿/金丝雀/滚动）
    ↓
监控 → 确认健康（AI 辅助监控分析）
    ↓
(失败时) AI 辅助 → 回滚或排障
```

### 环境策略

| 环境 | 用途 | AI 介入程度 | 部署方式 |
|---|---|---|---|
| **Dev** | 本地开发 | 编写 docker-compose | 本地启动 |
| **Staging** | 预发布验证 | 审查配置 + 冒烟测试 | CI/CD 自动部署 |
| **Production** | 生产环境 | 仅辅助排障 | 人工触发 + 灰度 |

## CI/CD 配置生成

### GitHub Actions 示例 prompt

```
请为以下项目生成 .github/workflows/ci.yml：

项目信息：
- 语言/框架：Python FastAPI
- 包管理：Poetry
- 测试：pytest + pytest-cov
- Lint：ruff
- 数据库：PostgreSQL（测试用）
- 构建：Docker image push to GHCR

流水线阶段：
1. Lint check
2. Unit test with PostgreSQL service
3. Build Docker image
4. Push to registry

要求：
- 仅在 push 到 main 和 PR 时触发
- 使用矩阵构建 Python 3.11 / 3.12
- 测试步骤需要等待 PostgreSQL 服务就绪
```

### Dockerfile 示例 prompt

```
请为以下项目生成 Dockerfile：

项目：React SPA（Vite + TypeScript）
要求：
- 多阶段构建（build stage + nginx serve stage）
- 构建阶段用 node:20-alpine
- 运行阶段用 nginx:alpine
- 配置 SPA 路由 fallback（try_files）
- 暴露 80 端口
- 使用非 root 用户运行
```

## 部署策略与 AI 建议

| 策略 | 说明 | 适用场景 |
|---|---|---|
| **蓝绿部署** | 两套环境切换，瞬间切换流量 | 关键生产服务 |
| **金丝雀部署** | 先发布到小比例实例，观察后再全量 | 需要灰度验证的新功能 |
| **滚动更新** | 逐步替换实例 | 微服务/K8s 环境 |
| **特性标记（Feature Flag）** | 代码已部署但功能按需开启 | 需要细粒度控制 |

AI 可以帮助列出各策略的优劣对比，但**选择哪种策略取决于业务容忍度**，不是技术问题。

## 发布的常见检查清单

### 部署前
- [ ] 测试是否全部通过（CI 绿色）
- [ ] Code Review 是否全部 resolved
- [ ] 数据库迁移是否向前兼容
- [ ] 是否有回滚方案
- [ ] 是否更新了 CHANGELOG / Release Notes
- [ ] 配置项（环境变量、密钥）是否就绪
- [ ] 监控/告警是否配置

### 部署后
- [ ] 服务健康检查通过（/health endpoint）
- [ ] 关键业务流程是否正常（Smoke Test）
- [ ] 错误率/延迟是否在正常范围内
- [ ] 日志是否有异常

## 流行工具

| 工具 | 用途 | 说明 |
|---|---|---|
| **GitHub Actions** | CI/CD | 生态最丰富的 CI 平台之一 |
| **GitLab CI** | CI/CD | GitLab 原生集成 |
| **Docker / Docker Compose** | 容器化 | 本地/单机部署标准 |
| **Kubernetes (K8s)** | 容器编排 | 生产级多服务编排 |
| **Terraform / OpenTofu** | IaC | 基础设施即代码 |
| **Ansible** | 配置管理 | 服务器配置自动化 |
| **ArgoCD** | GitOps | K8s 声明式部署 |
| **Vercel / Netlify** | 前端部署 | 前端 SPA/SSG 一键部署 |
| **Railway / Fly.io** | PaaS | 简化部署的平台 |

## 可使用的 Skills

| Skill | 说明 | 什么时候用 |
|---|---|---|
| `deploy-config` | 生成/审查部署配置 | 首次搭建 CI/CD 或修改部署配置时 |

## 注意事项 / 陷阱

- ⚠️ **AI 生成的 Dockerfile/配置可能不安全** — 常见问题：root 运行、暴露多余端口、使用 latest 标签、忘记清理缓存层。生成后必须人工审计
- ⚠️ **密钥泄漏** — 不要在 CI 配置中硬编码密钥。使用 Secrets 管理（GitHub Secrets / Vault / 1Password）
- ⚠️ **数据库迁移不可逆** — AI 生成的迁移脚本需要人工检查是否可回滚。生产数据库变更应遵循"增量化、可回退"原则
- ⚠️ **AI 不了解你的基础设施限制** — AI 不知道你的云服务配额、网络策略、证书到期时间。部署前需要人工核对基础设施约束
- ⚠️ **CI 配置陷阱** — AI 可能遗漏 pipeline 间的依赖关系、缓存策略、并发限制。生成后做一次完整的 dry-run
- ✅ **最佳实践**：部署流程应做到"一键部署、一键回滚"，AI 可帮助编写这两条路径的脚本

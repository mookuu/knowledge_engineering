---
name: deploy-config
description: 生成和审查部署配置。使用场景：首次搭建 CI/CD 流水线、修改部署配置、排查部署失败时。
---

# 部署配置

## Quick Start

1. 收集项目信息（语言、框架、依赖管理、构建方式）
2. 明确目标环境（Docker / K8s / VPS / PaaS）
3. 生成 CI 配置文件（GitHub Actions / GitLab CI）
4. 生成容器配置（Dockerfile / Docker Compose）
5. 检查配置安全性（密钥管理、运行权限、端口暴露）
6. 生成部署和回滚脚本

## CI 配置检查清单

- [ ] 触发条件是否合理（仅 push/main + PR）
- [ ] 测试阶段是否包含 lint + test + build
- [ ] 缓存策略是否配置（依赖缓存加速构建）
- [ ] 密钥管理（使用 Secrets，不硬编码）
- [ ] 构建产物上传（artifact / image registry）
- [ ] 并行/矩阵构建是否合理

## Dockerfile 检查清单

- [ ] 使用多阶段构建（build → run）
- [ ] 使用特定版本 tag（不用 latest）
- [ ] 运行阶段使用非 root 用户
- [ ] 暴露最小端口
- [ ] 清理构建缓存（减小镜像体积）
- [ ] 添加 HEALTHCHECK 指令

## 输出格式

完整的 CI/Dockerfile/Docker Compose 配置文件，每段配置附简要注释说明作用。
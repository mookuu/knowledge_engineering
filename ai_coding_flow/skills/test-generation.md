---
name: test-generation
description: 自动生成单元测试和集成测试。使用场景：功能代码完成后，需要补充测试覆盖时。
---

# 测试自动生成

## Quick Start

1. 读取目标代码，分析输入/输出和依赖关系
2. 识别需要 Mock 的外部依赖（DB、API、文件系统）
3. 生成测试用例：正常路径 + 异常路径 + 边界值
4. 生成 Mock/Stub 数据
5. 运行测试验证所有用例通过
6. 补充覆盖率分析，填补盲区

## 测试覆盖策略

| 类型 | 说明 | AI 生成优先级 |
|---|---|---|
| **正常路径** | 标准输入 → 期望输出 | ✅ 高 |
| **异常路径** | 错误输入 → 错误处理 | ✅ 高 |
| **边界值** | 空值、极值、特殊值 | ✅ 高 |
| **状态转换** | 状态机/流程的状态流转 | ⚠️ 中 |
| **错误回滚** | 部分失败时的一致性 | ⚠️ 中 |
| **并发冲突** | 竞态条件、死锁 | ❌ 低（需人工） |

## 常见 Mock 模式

| 依赖类型 | Mock 方式 | 示例 |
|---|---|---|
| 数据库 | mock DB session / 使用内存 DB | `mock_sqlalchemy` |
| HTTP API | responses / httpx mock | `responses` / `httpx.MockTransport` |
| 文件系统 | tmp_path / mock open | `pyfakefs` / `unittest.mock.mock_open` |
| 时间 | freeze time | `freezegun` / `pytest-time-machine` |
| 环境变量 | monkeypatch | `monkeypatch.setenv()` |

## Checklist

- [ ] 每个测试有明确的 Assertion
- [ ] 覆盖正常 + 异常 + 边界
- [ ] 测试独立（不依赖其他测试的状态）
- [ ] Mock 范围合理（不 Mock 掉测试目标的逻辑）
- [ ] 测试命名清晰（test_当XX时_应返回XX）
- [ ] 运行全部通过

## Output Format

按测试框架（pytest / vitest / go test）生成标准格式测试文件。每个测试包含 docstring 说明测试场景。
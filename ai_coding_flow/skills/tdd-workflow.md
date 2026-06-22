---
name: tdd-workflow
description: 测试驱动开发流程。使用场景：开始实现新功能时，遵循"先写测试再写实现"的 TDD 模式。
---

# TDD 工作流程

## Quick Start

1. 理解需求：明确输入/输出/边界条件
2. 先写测试：为期望行为编写一个会 FAIL 的测试（Red）
3. 运行测试：确认测试因"没有实现"而失败
4. 生成实现：写最少代码让测试通过（Green）
5. 运行测试：确认通过
6. 重构优化：在测试保护下重构代码（Refactor）
7. 重复 1-6 直到所有需求完成

## 循环：Red → Green → Refactor

```
写测试 → 运行(红) → 写最少实现 → 运行(绿) → 重构 → 重复
  ↑                                                    │
  └────────────────────────────────────────────────────┘
```

## 示例

```
Task: 实现 is_palindrome(s: str) -> bool

Step 1 (Red): 
def test_is_palindrome():
    assert is_palindrome("") == True
    assert is_palindrome("a") == True
    assert is_palindrome("aa") == True
    assert is_palindrome("ab") == False
    assert is_palindrome("racecar") == True
    assert is_palindrome("A man a plan a canal Panama") == True

Step 2 (Green):
def is_palindrome(s: str) -> bool:
    s = ''.join(c.lower() for c in s if c.isalnum())
    return s == s[::-1]
```

## Checklist

- [ ] 测试是否先于实现代码
- [ ] 测试在实现前是否 FAIL（确认测试有效）
- [ ] 每个测试是否独立、可重复
- [ ] 是否覆盖正常路径 + 异常路径 + 边界值
- [ ] 是否只写了"让测试通过"的最少代码

## Rules

- 没有测试的新功能 = 默认不接受
- 先 Red 再 Green：没看到测试失败就直接写实现 = 不是 TDD
- 重构阶段不改变外部行为：确保所有测试保持 Green
---
name: code-review
description: Review code for quality, security, and maintainability following team standards. Use when reviewing pull requests, examining code changes, or when the user asks for a code review.
---

# Code Review：主题锚点

## Quick Start：Skill的最短操作手册，最小可执行流程

When reviewing code:

1. Check for correctness and potential bugs：正确性
2. Verify security best practices：安全性，最佳安全实践
3. Assess code readability and maintainability：可读性，可维护性
4. Ensure tests are adequate：测试充分性

## Review Checklist：把抽象要求变成检查项

- [ ] Logic is correct and handles edge cases
- [ ] No security vulnerabilities (SQL injection, XSS, etc.)
- [ ] Code follows project style conventions
- [ ] Functions are appropriately sized and focused
- [ ] Error handling is comprehensive
- [ ] Tests cover the changes

## Providing Feedback：规定输出风格

Format feedback as:
- 🔴 **Critical**: Must fix before merge
- 🟡 **Suggestion**: Consider improving
- 🟢 **Nice to have**: Optional enhancement

## Additional Resources：逐渐展开Progressive Disclosure

- For detailed coding standards, see [STANDARDS.md](STANDARDS.md)
- For example reviews, see [examples.md](examples.md)
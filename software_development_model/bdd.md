# BDD (行为驱动开发 — Behavior-Driven Development)

> **2003 年** Dan North 提出。BDD 是 TDD 的演化——把测试语言从代码术语升级为**业务语言**，让非技术人员也能参与验证。

---

## 核心思想

**用自然语言描述系统应有的行为**，然后自动化执行这些描述作为验收测试。

```
TDD 回答：  "代码写得对吗？"
BDD 回答：  "系统行为对吗？"
```

---

## Given-When-Then 格式

```
Given    [前置条件 / 上下文]
When     [触发行为 / 事件]
Then     [预期结果 / 输出]
```

### 示例

```gherkin
Feature: 用户登录

  Scenario: 有效账号登录成功
    Given 用户"张三"已注册且密码为"abc123"
    When  用户输入用户名"张三"和密码"abc123"并点击登录
    Then  显示"欢迎回来，张三"
    And   跳转到首页

  Scenario: 密码错误登录失败
    Given 用户"张三"已注册
    When  用户输入用户名"张三"和密码"wrong_password"并点击登录
    Then  显示"用户名或密码错误"
    And   停留在登录页面
```

---

## BDD 三层

```
业务层 ─── Feature / Story ─── 业务人员、PO 编写
         Given-When-Then 场景
              │
              ↓
功能层 ─── Step Definitions ─── 自动化工程师编写
         将每个 Step 映射到代码
              │
              ↓
实现层 ─── 生产代码 ─── 开发者编写
         让 Steps 全部通过
```

---

## 常用 BDD 工具

| 语言/平台 | 工具 |
|-----------|------|
| Java | Cucumber-JVM, JBehave |
| JavaScript/TS | Cucumber.js, Jest + custom matchers |
| Python | Behave, pytest-bdd |
| Ruby | Cucumber (元祖) |
| .NET | SpecFlow |

---

## BDD vs TDD vs ATDD

| | TDD | BDD | ATDD (验收测试驱动开发) |
|---|:--:|:--:|:--:|
| **关注点** | 单元 — 代码正确性 | 行为 — 系统该做什么 | 验收标准 — 业务需求满足否 |
| **语言** | 代码 (assert) | 自然语言 (Given/When/Then) | 自然语言或 DSL |
| **谁写** | 开发者 | 三者协作（业务+开发+测试） | 业务/测试 + 开发实现 |
| **粒度** | 函数/类级 | 场景/功能级 | 特性/需求级 |
| **产出** | 单元测试套件 | 可执行的规格文档 | 验收测试套件 |

---

## BDD 的价值

| 价值 | 说明 |
|------|------|
| **共同语言** | 业务、开发、测试三种角色用同一个 Given-When-Then 对话 |
| **活文档** | 场景即文档，而且自动化运行，永远不会过时 |
| **减少返工** | 写场景时就能发现需求歧义（而不是编码完成后） |
| **验收自动化** | 把手动回归测试变成可重复执行的 Spec |

---

## 适用场景

- ✅ 业务规则复杂的系统
- ✅ 跨角色沟通频繁的团队
- ✅ 需要可读验收文档（合规/外包交接）
- ✅ TDD 已建立基础，想进一步打通业务
- ❌ 纯技术性项目（如 SDK/CLI 工具）
- ❌ 团队没有业务人员能参与写场景

---

## 相关词汇

见 [glossary.md](glossary.md) — Acceptance Test / Given-When-Then / Cucumber / Gherkin / Specification by Example

## 智能体框架

### 智能体系统的解耦和可扩展性

- 模型层Model Layer

  负责与LLM交流，可轻松替换不同的模型，如DeepSeek、Gemini、Claude等。

- 工具层Tool Layer

  提供标准化的工具定义、注册和执行接口，添加新工具不影响其他代码

- 记忆层Memory Layer

  处理短期记忆和长期记忆，可根据需求切换不同的记忆策略(如滑动窗口、摘要记忆)

这种模块化的设计使得整个系统极具扩展性，更换或升级任何一个组件都变得简单

### 主流框架

- 第一代通用LLM应用框架
  - LangChain
  - LlamaIndex

- 新一代框架

      + 多智能体协作Multi-Agent Collaboration
      + 复杂工作流控制Complex Workflow Control

  ![agent_framework.png](./images/agent_framework.png)

1. AutoGen

   核心思想：通过对话实现协作

   将多智能体系统抽象为一个由多个"可对话"智能体组成的群聊

   开发者可以定义不同角色(如Code、ProductManager、Tester)，设定他们之间的交互规则(如Coder写完代码后由Tester自动接管)

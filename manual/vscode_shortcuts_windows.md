# VS Code / Cursor 快捷键备忘（Windows）

> **适用**：Visual Studio Code、Cursor（基于 VS Code，快捷键大体一致）。  
> **平台**：Windows；macOS 请将 `Ctrl` 换为 `Cmd`，`Alt` 换为 `Option`。  
> **官方**：编辑器内 `Ctrl+K Ctrl+S` 打开快捷键表；[VS Code 默认键位](https://code.visualstudio.com/docs/configure/keybindings)。

---

## 本机自定义（Cursor）

| 按键 | 作用 |
|------|------|
| `Ctrl+Alt+Q` | 在 **Cursor Tab 开/关** 之间切换（扩展 `vscode-settings-cycler`，对应设置 `cursor.cpp.disabledLanguages`） |

恢复或迁移设置时，见 `keybindings.json` 与 `settings.json` 中的 `settings.cycle`。

---

## 一、最先记住的 10 个

| 按键 | 作用 | 记忆提示 |
|------|------|----------|
| `Ctrl+Shift+P` | **命令面板**（几乎所有功能都能搜） | P = Palette |
| `Ctrl+P` | **快速打开文件**（输入文件名） | P = 跳转 |
| `Ctrl+Shift+F` | 在整个工作区**搜索文字** | F = Find |
| `Ctrl+/` | 行注释 / 取消注释 | 斜杠像注释符 |
| `Ctrl+S` | 保存 | — |
| `Ctrl+Z` / `Ctrl+Y` | 撤销 / 重做 | — |
| `Ctrl+B` | 显示/隐藏**左侧栏** | B = Bar |
| `Ctrl+反引号` | 显示/隐藏**终端** | 反引号键在 Esc 下方 |
| `F2` | **重命名**符号（变量、函数等） | — |
| `F12` | **跳转到定义** | — |

---

## 二、编辑与多光标

| 按键 | 作用 |
|------|------|
| `Ctrl+D` | 选中下一个相同词（可连按多选） |
| `Ctrl+Shift+L` | 选中文件中所有相同词 |
| `Alt+单击` | 增加一个光标 |
| `Ctrl+Alt+↑` / `Ctrl+Alt+↓` | 在上/下行增加光标 |
| `Alt+↑` / `Alt+↓` | 上/下移动当前行 |
| `Shift+Alt+↑` / `Shift+Alt+↓` | 向上/下复制当前行 |
| `Ctrl+Shift+K` | 删除当前行 |
| `Ctrl+Enter` | 在下方插入新行（光标跟过去） |
| `Ctrl+Shift+Enter` | 在上方插入新行 |
| `Ctrl+]` / `Ctrl+[` | 增加 / 减少缩进 |
| `Shift+Alt+A` | 块注释（`/* */`） |
| `Ctrl+.` | **快速修复**（灯泡菜单：导入、修 lint 等） |
| `Ctrl+Space` | 触发**自动补全** |
| `Tab` / `Shift+Tab` | 接受建议 / 反缩进 |

---

## 三、查找与跳转

| 按键 | 作用 |
|------|------|
| `Ctrl+F` | 当前文件内查找 |
| `Ctrl+H` | 当前文件内替换 |
| `Ctrl+Shift+H` | 整个工作区替换 |
| `F3` / `Shift+F3` | 查找下一个 / 上一个 |
| `Ctrl+G` | 跳到指定**行号** |
| `Ctrl+Shift+O` | 当前文件内按**符号**跳转（函数、类） |
| `Ctrl+T` | 整个工作区按符号跳转 |
| `Alt+F12` | **预览定义**（小窗，不离开当前文件） |
| `Shift+F12` | 查找所有**引用** |
| `Alt+←` / `Alt+→` | 后退 / 前进（跳转历史） |

---

## 四、文件与编辑器布局

| 按键 | 作用 |
|------|------|
| `Ctrl+N` | 新建文件 |
| `Ctrl+W` | 关闭当前标签页 |
| `Ctrl+K` `W` | 关闭所有标签（先按 `Ctrl+K`，松手再按 `W`） |
| `Ctrl+Tab` | 在已打开文件间切换 |
| `Ctrl+\` | 拆分编辑器（左右分屏） |
| `Ctrl+1` / `Ctrl+2` / `Ctrl+3` | 聚焦第 1 / 2 / 3 个编辑组 |
| `Ctrl+K` `←`/`→`/`↑`/`↓` | 将当前编辑器移到相邻分屏 |
| `Ctrl+Shift+E` | 聚焦**资源管理器** |
| `Ctrl+Shift+G` | 聚焦 **Git** 视图 |
| `Ctrl+Shift+X` | **扩展**市场 |
| `Ctrl+J` | 显示/隐藏**底部面板**（终端、输出、问题） |

---

## 五、终端与运行

| 按键 | 作用 |
|------|------|
| `Ctrl+反引号` | 切换终端 |
| `Ctrl+Shift+反引号` | 新建终端 |
| `Ctrl+Shift+5` | 拆分终端 |
| `Ctrl+Shift+D` | 打开**运行和调试**侧栏 |
| `F5` | 开始调试 / 继续 |
| `F9` | 切换断点 |
| `F10` | 单步跳过 |
| `F11` | 单步进入 |
| `Shift+F5` | 停止调试 |

---

## 六、Git（源代码管理）

| 按键 | 作用 |
|------|------|
| `Ctrl+Shift+G` | 打开 Git 侧栏 |
| 侧栏内 `+` | 暂存（Stage）文件 |
| 输入消息后 `Ctrl+Enter` | 提交（Commit） |
| `…` 菜单 | 拉取、推送、同步、分支等 |

命令面板可搜：`Git: Pull`、`Git: Push`、`Git: Sync`。

命令行版流程见 [github_git_commands.md](github_git_commands.md)。

---

## 七、Markdown 与预览

| 按键 | 作用 |
|------|------|
| `Ctrl+Shift+V` | 打开 Markdown **预览** |
| `Ctrl+K` `V` | 侧边打开预览 |
| `Ctrl+K` `Z` | **禅模式**（全屏写作） |
| `Esc` `Esc` | 退出禅模式 |

---

## 八、Cursor 常用（AI）

| 按键 / 操作 | 作用 |
|-------------|------|
| `Ctrl+L` | 打开 **Chat**（以当前 Cursor 版本为准） |
| `Ctrl+K` | 行内 **Edit**（选中代码后改写） |
| `Ctrl+I` | **Composer / Agent** 面板（版本可能合并到 Chat） |
| `Ctrl+Shift+P` → 搜 `Cursor` | 所有 Cursor 相关命令 |
| `Ctrl+Alt+Q` | **本机**：Cursor Tab 开/关循环 |

> 不同 Cursor 版本键位可能调整，以 **File → Preferences → Keyboard Shortcuts** 中实际绑定为准。

---

## 九、组合键怎么按（`Ctrl+K` 系列）

VS Code 里很多快捷键是 **和弦键**：先按 `Ctrl+K`，松开后再按第二个键。

示例：

1. 按住 `Ctrl`，点一下 `K`，松开
2. 再按 `S` → 打开快捷键设置表

不要同时按住 `K` 和 `S` 与 `Ctrl` 不松。

---

## 十、自己查、自己改

| 操作 | 方法 |
|------|------|
| 打开快捷键表 | `Ctrl+K` `Ctrl+S`，或命令面板搜 **Preferences: Open Keyboard Shortcuts** |
| 查某命令的键位 | 快捷键表右上角搜索命令名（如 `Format Document`） |
| 改键位 | 点击左侧铅笔图标，按新键 |
| 导出键位 | 快捷键表右上角 `…` → **Export**；或复制 `%APPDATA%\Cursor\User\keybindings.json` |
| 命令面板 | `Ctrl+Shift+P`，输入英文或中文关键词 |

配置文件路径（Windows）：

- 用户设置：`%APPDATA%\Cursor\User\settings.json`
- 快捷键：`%APPDATA%\Cursor\User\keybindings.json`
- 工作区设置：项目根目录 `.vscode/settings.json`

---

## 十一、与本仓库相关的习惯

| 场景 | 建议 |
|------|------|
| 多仓库工作区 | `Ctrl+P` 输入文件名；侧栏切换根目录；Git 命令见 [github_git_commands.md](github_git_commands.md) |
| Python 格式化 | 本机已配 **Ruff**，保存时自动格式化（`formatOnSave`） |
| 主题 | 本机主题为 **3024 Day**（`ms-vscode.theme-3024kit`） |
| 扩展列表备份 | 见本机 `cursor-settings-export-*/extensions.txt` |

---

## 参考链接

- [Key Bindings for Visual Studio Code](https://code.visualstudio.com/docs/configure/keybindings)
- [Windows 快捷键 PDF（官方）](https://code.visualstudio.com/shortcuts/keyboard-shortcuts-windows.pdf)
- [Cursor 文档](https://cursor.com/docs)

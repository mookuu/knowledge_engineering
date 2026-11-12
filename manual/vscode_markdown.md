# VS Code Markdown 编辑与预览（Windows）

> **适用**：Visual Studio Code（Windows）。本机配置实测日期：2026-11-10。
> **定位**：专讲「Markdown 怎么写得快、怎么看效果」；通用快捷键见 [vscode_shortcuts_windows.md](vscode_shortcuts_windows.md)。

---

## 一、插件与分工

| 插件                          | 版本   | 作用                                                   |
| ----------------------------- | ------ | ------------------------------------------------------ |
| Markdown Preview Enhanced     | 0.8.40 | **预览引擎**：mermaid 图表、数学公式、代码块、导出/演示 |
| Markdown All in One           | 3.6.3  | **编辑快捷键**：加粗/斜体/标题/列表/目录                |
| markdownlint                  | 0.62.1 | 语法检查，有问题在编辑器里画波浪线                     |
| Prettier（非 md 专用）        | 12.4.0 | 保存时格式化，`[markdown]` 已指定它                    |

**原则：只让 MPE 负责渲染。** 已卸载 `bierner.markdown-mermaid`——MPE 自带 mermaid，重复了。

> 易混淆的三种「预览」：
>
> 1. **MPE 预览**（本手册使用的）——右侧实时渲染，支持 mermaid/公式；
> 2. **VSCode 内置预览**（`vscode.markdown.preview.editor`）——样式不同、不渲染 mermaid；
> 3. **把 `*.md` 关联成预览器打开**——双击只有预览、没有编辑器，**不要这么配**（见「七、常见问题」）。

---

## 二、默认工作流：左源码 + 右预览

打开任意 `.md` 文件 → 左边是源码编辑器，右边自动弹出实时预览，滚动同步。

靠的是这条设置（`settings.json`）：

```jsonc
"markdown-preview-enhanced.automaticallyShowPreviewOfMarkdownBeingEdited": true,
"markdown-preview-enhanced.scrollSync": true,
```

| 设置                                                              | 值     | 说明                                        |
| ----------------------------------------------------------------- | ------ | ------------------------------------------- |
| `markdown-preview-enhanced.automaticallyShowPreviewOfMarkdownBeingEdited` | `true` | 打开/编辑 md 时自动开侧边预览               |
| `markdown-preview-enhanced.scrollSync`                            | `true` | 源码与预览滚动同步                          |
| `markdown-preview-enhanced.enablePreviewZenMode`                  | `true` | 保留预览里的 Zen 沉浸模式按钮               |
| `[markdown].editor.wordWrap`                                      | `"on"` | 长段落自动折行，不用横向滚动                |
| `[markdown].editor.tabSize`                                       | `2`    | Markdown 缩进用 2 空格                      |

如果觉得每个 md 都自动弹预览太吵，可加黑名单：

```jsonc
"markdown-preview-enhanced.disableAutoPreviewForFilePatterns": ["**/CHANGELOG.md"]
```

---

## 三、快捷键总表

### 3.1 视图：一体 / 纯一览

| 按键         | 作用                                                       |
| ------------ | ---------------------------------------------------------- |
| `Ctrl+K` `V` | 在**右侧**打开预览（左右分屏，一体视图）                   |
| `Ctrl+Alt+P` | **最大化当前编辑器组**：在预览上按 → 预览铺满（纯一览）；再按一次 → 恢复左右分屏 |
| `Ctrl+Alt+P` | 在源码编辑器上按 → 只留源码（预览被收起），再按还原        |

`Ctrl+Alt+P` 的作用是「放大你现在待的那个格子」。所以：

- 想**只看排版效果** → 鼠标点一下预览，按 `Ctrl+Alt+P`
- 想**回到分屏** → 再按一次 `Ctrl+Alt+P`
- 想**专心码字** → 鼠标点一下源码区，按 `Ctrl+Alt+P`

对应命令：`workbench.action.toggleMaximizeEditorGroup`（键盘快捷方式里搜「最大化编辑器组」可确认）。

### 3.2 编辑快捷键（Markdown All in One，开箱即用）

| 按键                     | 作用                       |
| ------------------------ | -------------------------- |
| `Ctrl+B`                 | **加粗**                   |
| `Ctrl+I`                 | *斜体*                     |
| `Alt+S`                  | ~~删除线~~                 |
| `Ctrl+Shift+]`           | 标题升级（H2 → H1）        |
| `Ctrl+Shift+[`           | 标题降级（H1 → H2）        |
| `Ctrl+M`                 | 行内数学公式 `$...$`       |
| `Alt+C`                  | 勾选 / 取消任务列表 `- [ ]` |
| `Alt+↑` / `Alt+↓`        | 上/下移动当前行            |
| `Ctrl+]` / `Ctrl+[`      | 增加 / 减少缩进            |
| `Enter`                  | 自动续写列表项、列表符号   |

> 这些是扩展自带的默认绑定，**不用写进 `keybindings.json`**。

### 3.3 本机自定义（写在 `keybindings.json`）

| 按键            | 作用                  |
| --------------- | --------------------- |
| `Ctrl+Alt+P`    | 最大化/还原当前编辑器组（纯一览 ⇄ 分屏） |
| `Ctrl+Alt+C`    | 行内代码 `` `code` ``  |
| `Ctrl+Alt+T`    | 插入表格（MPE 表格构建器） |
| `Ctrl+Alt+U`    | 更新目录（TOC）       |
| `Ctrl+K` `V`    | 强制走 MPE 的侧边预览（避免和内置预览抢键） |

源码（可直接粘到 `keybindings.json`）：

```jsonc
[
  { "key": "ctrl+alt+p", "command": "workbench.action.toggleMaximizeEditorGroup" },
  {
    "key": "ctrl+k v",
    "command": "markdown-preview-enhanced.openPreviewToTheSide",
    "when": "editorLangId =~ /^(markdown|quarto|prompt|instructions|chatagent|skill)$/"
  },
  {
    "key": "ctrl+alt+c",
    "command": "markdown.extension.editing.toggleCodeSpan",
    "when": "editorTextFocus && !editorReadonly && editorLangId == markdown"
  },
  {
    "key": "ctrl+alt+t",
    "command": "markdown-preview-enhanced.insertTable",
    "when": "editorTextFocus && editorLangId == markdown"
  },
  {
    "key": "ctrl+alt+u",
    "command": "markdown.extension.toc.update",
    "when": "editorTextFocus && editorLangId == markdown"
  }
]
```

---

## 四、典型操作

| 想做的事             | 做法                                                             |
| -------------------- | ---------------------------------------------------------------- |
| 写标题               | `Ctrl+1`…`Ctrl+6` 不是标题（那是编辑器分栏），用 `Ctrl+Shift+]` 升、`Ctrl+Shift+[` 降 |
| 插表格               | `Ctrl+Alt+T`，弹窗里选行列；也可手打管道符                       |
| 改表格列宽           | 光标停在表格里 → `Ctrl+Shift+P` → 搜 `Format Document`（Prettier 对齐） |
| 生成/更新目录        | `Ctrl+Alt+U`（首次用「Markdown All in One: Create Table of Contents」） |
| 插图片               | 直接粘贴图片：MPE 会存到 `assets/` 并插入链接（设置 `markdown-preview-enhanced.imageFolderPath` 可改） |
| 画流程图 / 时序图    | 代码块标 ` ```mermaid `，右侧预览直接出图                       |
| 写数学公式           | `Ctrl+M` 插 `$...$`，块级用 `$$...$$`                            |
| 只看排版             | 点预览 → `Ctrl+Alt+P`                                           |
| 导出 PDF / HTML      | 预览右上角工具栏 → 选 Pandoc/Chrome 导出（需本机装 Pandoc）      |

---

## 五、格式与规范

- 缩进：2 空格；无序列表统一 `-`；行尾不加多余空格（否则会被 `trimTrailingWhitespace` 吃掉，硬换行请用 `\` 或空行分段）。
- 保存时 Prettier 会自动格式化 md（`formatOnSave: true` + `[markdown].editor.defaultFormatter = prettier`）。它默认 `proseWrap: preserve`，**不会把段落重新折行**，只会规整列表符号、表格对齐。
- 语法错误看 markdownlint 的波浪线，悬停有说明，`Ctrl+.` 快速修复。

---

## 六、配置位置

| 文件 | 路径 |
| --- | --- |
| 全局设置 | `%APPDATA%\Code\User\settings.json` |
| 快捷键 | `%APPDATA%\Code\User\keybindings.json` |
| 已装插件 | `%USERPROFILE%\.vscode\extensions` |

本次修改的备份（2026-11-10）：

- `settings.json.bak-20261110-234634`
- `keybindings.json.bak-20261110-234634`

回滚：把备份改回原文件名覆盖，然后 `Ctrl+Shift+P` → **Reload Window**。

---

## 七、常见问题

**Q1. 双击 `.md` 只有预览，没有源码编辑器。**
`settings.json` 里的 `workbench.editorAssociations` 把 `*.md` 关联到预览器了。删掉这一行：

```jsonc
"*.md": "markdown-preview-enhanced",   // ← 删掉
```

**Q2. `Ctrl+Alt+P` 没反应。**
命令名可能随版本变化。`Ctrl+K` `Ctrl+S` 打开快捷键表，搜「最大化」，看实际绑定；或把那条自定义绑定改成表里显示的命令 ID。

**Q3. 改了设置不生效。**
`Ctrl+Shift+P` → **Reload Window**。

**Q4. 打开 md 时右侧预览没自动出现。**
确认 `markdown-preview-enhanced.automaticallyShowPreviewOfMarkdownBeingEdited` 是 `true`；确认当前文件被识别成 `markdown`（右下角语言模式），不是 `Plain Text`。

**Q5. 按 `Ctrl+Shift+V` 出来的预览「长得不一样」。**
那是 VSCode **内置预览**，不是 MPE——不渲染 mermaid。统一用 `Ctrl+K` `V` 或 `Ctrl+Alt+P`。

**Q6. Mermaid 图不显示。**
确认代码块语言写成 `mermaid`（不是 `mermaidjs`），且用的是 MPE 预览。

**Q7. 打开 md 就报 `command 'markdown-preview-enhanced.openPreviewToTheSide' not found`。**
不是没装，也不是插件坏了——窗口进了**受限模式（Restricted Mode）**。MPE 0.8.40 的 `package.json` 里没有
`capabilities.untrustedWorkspaces` 声明，受限模式下会被**整体禁用**，命令根本没注册，所以报「命令不存在」而不是「未安装」。

判定（三条同时成立就是它）：

- 左下角状态栏有「受限模式」字样；
- `Ctrl+K` `V`、`Ctrl+Alt+T`、`Ctrl+Alt+C`、`Ctrl+Alt+U` **一起**失灵（Markdown All in One 同样没声明）；
- 而 markdownlint（声明了 `untrustedWorkspaces: limited`）、Prettier、主题类插件照常工作。

修复：点状态栏「受限模式」→ **管理工作区信任** → 信任该工作区；或 `Ctrl+Shift+P` → **工作区信任: 管理受信任文件夹和设置**，
把工作区里的**每个**文件夹都加进受信任列表。之后 `Ctrl+Shift+P` → **Reload Window**。

> 多根工作区**只要有一个文件夹没被信任，整窗就是受限的**。本例 2026-11-11 01:09 把
> `../30.knowledge/knowledge_engineering` 加进 `10.basic.code-workspace`，该文件夹此前没信任过，
> 于是整个工程降级为受限模式，MPE 随之被卸载出该窗口（日志里 MPE 在 01:06 还激活过，01:09 重启扩展宿主后就不再加载）。

不想信任那份文档目录时，另一条路是**拆开用**：`10.basic.code-workspace` 只留 Java + Python，
写文档时单独用窗口打开 `30.knowledge\knowledge_engineering`。

---

## 参考链接

- [Markdown Preview Enhanced 文档](https://shd101wyy.github.io/markdown-preview-enhanced/)
- [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one)
- [VS Code 键盘快捷方式文档](https://code.visualstudio.com/docs/configure/keybindings)

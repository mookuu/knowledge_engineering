# Hyper 隐藏滚动条（Windows）

> Hyper v3.2.0（Electron）  
> 配置文件：`C:\Users\moku\AppData\Roaming\Hyper\.hyper.js`  
> 安装目录：`C:\Users\moku\AppData\Local\Programs\Hyper`

## 目标

终端内容可滚动，但滚动条不可见。

## 现象与排查

DevTools 中对 `.xterm .xterm-viewport` 执行：

```js
const vp = document.querySelector('.xterm .xterm-viewport');
console.log('::-webkit-scrollbar display:', getComputedStyle(vp, '::-webkit-scrollbar').display);
console.log('scrollbar-width:', getComputedStyle(vp).scrollbarWidth);
```

若输出为 `display: inline`、`scrollbarWidth: undefined`，说明**自定义 CSS 根本没有注入**，不是选择器写错。

## 推理过程

### 1. 排除配置路径错误

Windows 上 Hyper 3 通过 `electron.app.getPath('userData')` 读取配置，即：

```
C:\Users\moku\AppData\Roaming\Hyper\.hyper.js
```

**不要**写到 WSL 内的 `/home/xxx/.hyper.js`，Hyper 不会读那个路径。

### 2. 排除选择器错误

xterm.js 生成的 DOM 是 `<div class="xterm">`，滚动容器是 `.xterm-viewport`。选择器应使用 `.xterm .xterm-viewport`（类选择器），不是标签 `xterm`。

### 3. 根因：Hyper 3.2.0 的 `termCSS` 注入 bug

反查 `app.asar` 中 renderer bundle 发现两条 CSS 注入路径：

| 配置字段 | 注入路径 | 是否生效 |
|---------|---------|---------|
| `css` | 主窗口 `App` 组件 → `stylis('#hyper', customCSS)` | ✅ 会注入 |
| `termCSS` | Redux `ui.termCSS` → `Terms` → `StyleSheet` 的 `customCSS` prop | ❌ 不生效 |

`StyleSheet` 组件虽然接收了 `customCSS`，但 `render()` 里只使用了 `backgroundColor`、`fontFamily` 等内置样式，**从未把 `customCSS` 写入 DOM**。内置样式里还有：

```css
::-webkit-scrollbar { width: 5px; }
```

因此写在 `termCSS` 里的隐藏规则完全无效，DevTools 里看到的是浏览器默认值（`display: inline`）。

**结论：在 Hyper 3.2.0 上，终端滚动条样式必须写在 `css` 字段，不能依赖 `termCSS`。**

## 解决方案

编辑 `C:\Users\moku\AppData\Roaming\Hyper\.hyper.js`：

```js
// css 经 stylis 作用域为 #hyper …，这是 Hyper 3.2.0 唯一会注入的字段
css: `
  .xterm .xterm-viewport {
    overflow-y: auto !important;
    scrollbar-width: none !important;
    -ms-overflow-style: none !important;
  }
  .xterm .xterm-viewport::-webkit-scrollbar,
  .xterm .xterm-viewport::-webkit-scrollbar-thumb,
  .xterm .xterm-viewport::-webkit-scrollbar-track {
    display: none !important;
    width: 0 !important;
    height: 0 !important;
    background: transparent !important;
  }
`,
// termCSS 在 Hyper 3.2.0 被 StyleSheet 忽略，留空即可
termCSS: '',
```

要点：

- **`css` 而非 `termCSS`**：`css` 经 `stylis('#hyper', …)` 作用到 `#hyper .xterm .xterm-viewport`，能覆盖内置 5px 滚动条
- **保留 `overflow-y: auto`**：只隐藏滚动条，不禁止滚动
- **覆盖 thumb / track 伪元素**：有时只隐藏 `::-webkit-scrollbar` 不够
- **`termCSS` 留空**：避免误以为已生效

## 生效步骤

1. **完全退出 Hyper**（`Ctrl+Q` 或托盘图标退出，不要只关窗口）
2. 重新启动 Hyper
3. DevTools 验证：

```js
const vp = document.querySelector('.xterm .xterm-viewport');
getComputedStyle(vp, '::-webkit-scrollbar').width  // 应为 "0px"
```

可选：确认 `css` 已注入：

```js
[...document.querySelectorAll('style')].some(s => s.textContent.includes('xterm-viewport'))
```

## 仍不生效时

1. 确认改的是 `AppData\Roaming\Hyper\.hyper.js`，不是 WSL 路径
2. 确认 `css` 非空、`termCSS` 里的旧规则已移除
3. DevTools → Elements → `.xterm-viewport` → Styles，检查是否有 `#hyper .xterm .xterm-viewport` 规则
4. 必要时清除 `%AppData%\Hyper\Cache`、`Code Cache`、`GPUCache` 后重启

## 验证配置可读

```bash
node -e "const m = require('C:/Users/moku/AppData/Roaming/Hyper/.hyper.js'); console.log(m.config.css)"
```

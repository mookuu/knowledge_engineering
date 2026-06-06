# Hyper 启动窗口大小与初始目录设置（Windows / WSL）

> Hyper v3.2.0（Electron）  
> 配置文件：`C:\Users\moku\AppData\Roaming\Hyper\.hyper.js`  
> 窗口状态（自动保存）：`C:\Users\moku\AppData\Roaming\Hyper\config.json`

## 目标

1. **窗口初始大小**：启动时窗口为合适的像素大小（由 `config.json` 自动保存）
2. **初始目录**：默认为 `C:\Workspace\program`
3. **分屏继承**：分屏（split pane）时也初始为该目录

## 推理过程

### 1. 窗口大小的坑：windowSize 被当成像素值

查看 Hyper 源码 `app/index.ts` 中窗口尺寸的取值逻辑：

```ts
const [width, height] = options.size ? options.size : cfg.windowSize || winSet.size;
```

| 来源 | 字段 | 说明 |
|------|------|------|
| `options.size` | — | 首次启动时没有 |
| `cfg.windowSize` | `.hyper.js` 中的 `windowSize` | **列×行数**（Hyper 3 格式），但代码把它当像素值用 |
| `winSet.size` | `config.json` 中的 `windowSize` | **真正的像素值**，由 electron-store 自动保存 |

**问题**：`.hyper.js` 里的 `windowSize` 是列×行数（如 `[170, 50]`），但源码直接把它当像素值传给 `BrowserWindow`。170×50 像素当然非常小。

**结论**：不要在 `.hyper.js` 中设置 `windowSize`，让 `config.json` 中保存的像素值生效。

### 2. 初始目录：两个配置字段

| 字段 | 作用范围 | 说明 |
|------|---------|------|
| `workingDirectory` | **仅影响 Windows cmd/PowerShell 启动** | 设置终端启动时的 `cwd` |
| `shellArgs` | **传给 shell 的参数** | WSL 需通过 `wsl --cd <dir>` 指定初始目录 |

#### WSL 工作目录

Hyper 的 shell 是 `C:\Windows\System32\wsl.exe`，默认 `shellArgs: ['~']` 会让 WSL 进入 Linux home 目录（`/home/moku`）。

`workingDirectory` 对 WSL **无效**，因为 WSL 有自己的独立文件系统。WSL 命令行参数 `--cd` 可以设置 WSL 启动的初始目录：

```bash
wsl --cd "C:\Workspace\program"
```

这样进入 WSL 后 `pwd` 就是 `/mnt/c/Workspace/program`。

#### 验证 `wsl --cd` 可用性

```powershell
wsl --cd "C:\Workspace\program" -e pwd
# 输出：/mnt/c/Workspace/program
```

所以方案是将 `shellArgs` 从 `['~']` 改为 `['--cd', 'C:\\Workspace\\program']`。

### 3. 分屏继承：preserveCWD

Hyper 已有 `preserveCWD: true` 配置项，其行为是：

- **分屏时**：新 pane 继承当前 pane 的工作目录（即 `wsl --cd <当前目录>`）
- **新标签页时**：使用默认 `shellArgs` 启动（即 `wsl --cd "C:\Workspace\program"`）

因此只要启动时进入了正确目录，分屏就会自动继承，无需额外配置。

## 解决方案

### 窗口大小：注释掉 windowSize

编辑 `C:\Users\moku\AppData\Roaming\Hyper\.hyper.js`，**注释掉** `windowSize` 行：

```diff
-         // window initial size [columns, rows]
-         windowSize: [140, 45],   // 或 [170, 50]，列×行数会被当成像素值，导致窗口极小
+         // window initial size — 注释掉，由 config.json 的像素值控制
+         // windowSize: [140, 45],
```

这样启动时会走 `cfg.windowSize || winSet.size` 路径：
- `.hyper.js` 里 `windowSize` 被注释掉 → `undefined`
- 取 `config.json` 中的像素值（如 `[1514, 966]`）→ 窗口恢复正常大小

`config.json` 由 electron-store 自动保存，关闭 Hyper 时窗口位置和大小会自动写入。

### 初始目录：修改 shellArgs

```diff
-         shellArgs: ['~'],
+         shellArgs: ['--cd', 'C:\\Workspace\\program'],
```

### 最终配置

```js
config: {
    updateChannel: 'stable',
    // window initial size — 注释掉，由 config.json 的像素值控制
    // windowSize: [140, 45],

    workingDirectory: 'C:\\Workspace\\program',
    shell: 'C:\\Windows\\System32\\wsl.exe',
    shellArgs: ['--cd', 'C:\\Workspace\\program'],
    preserveCWD: true,
}
```

## 窗口大小相关文件总结

| 文件 | 用途 | 关键内容 |
|------|------|---------|
| `.hyper.js` | 用户配置（Hyper 3 格式） | ~~`windowSize: [170, 50]`~~（已注释，列×行被当成像素导致窗口极小） |
| `config.json` | electron-store 自动保存的窗口状态 | `windowSize: [1514, 966]`（正确的像素值，但被 `.hyper.js` 覆盖） |

## 验证

重启 Hyper 后生效。

```powershell
Select-String -Path "$env:APPDATA\Hyper\.hyper.js" -Pattern 'windowSize|workingDirectory|shellArgs|preserveCWD'
```

预期输出：

```
        // windowSize: [140, 45],
        workingDirectory: 'C:\Workspace\program',
        shellArgs: ['--cd', 'C:\Workspace\program'],
        preserveCWD: true,
```

### 验证 WSL 初始目录

```powershell
wsl --cd "C:\Workspace\program" -e pwd
# 应输出：/mnt/c/Workspace/program
```

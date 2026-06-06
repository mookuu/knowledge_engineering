---
name: wsl-environment
description: "WSL/Windows 跨环境开发约束指南。当 Codex 需要在 WSL（Linux）和 Windows（/mnt/c）之间进行文件操作时使用此技能。包含写入/读取 C: 盘的方案、权限说明和常见陷阱。"
---

# WSL Environment

## 环境约束

这套环境运行在 WSL2 (Ubuntu) + Windows Terminal + tmux 下，Codex 运行在 bwrap sandbox 中。sandbox 默认 `--unshare-net` 阻断网络，vsock 通信不可用，`powershell.exe`、`wsl.exe` 在 sandbox 内也无法运行。

### 1. 可写目录与旧版 flag 变更

**历史**：`~/.zshrc` 中 codex alias 曾用 `--writable-roots /mnt/c/Workspace/program`，该 flag 从 Codex v0.136.0 起被移除。替代选项：

- `--add-dir <DIR>` — sandbox 模式下添加额外可写目录
- `-s workspace-write` — sandbox 模式级别
- `sandbox_permissions` — 配置文件中通过 `writable_roots` 声明可写路径

当前 alias 已更新为：
```
alias codex="codex --add-dir /mnt/c/Workspace/program -a never"
```

### 2. `/mnt/c` 写权限判定

能否直接用文件工具写入 `/mnt/c` 下的路径，取决于 **sandbox_permissions 配置**。当前配置已将 `/mnt/c/Workspace/program` 列为可写根目录，所以文件工具（如 `apply_patch`、`cat >`）可以直接写入该目录下的文件。

**如果目标目录不在可写根目录列表中**，依然需要用 `require_escalated` 配合 PowerShell 写入。`--unshare-net` 阻断 vsock 导致 sandbox 内无法直接调用 `powershell.exe`，必须提权。

### 3. 写入 C: 盘（非白名单目录）

#### A) -EncodedCommand（推荐）

将 PowerShell 命令编码为 UTF-16LE base64 传入，完全避开 shell 变量展开问题：

```bash
# 准备内容
cat > /tmp/src.txt << 'EOF'
... content ...
EOF

# 构造 PowerShell 命令（base64 内嵌在单引号中）
printf "[IO.File]::WriteAllBytes('C:\\path\\to\\target', [Convert]::FromBase64String('" > /tmp/ps_cmd.ps1
base64 -w0 /tmp/src.txt >> /tmp/ps_cmd.ps1
echo "'))" >> /tmp/ps_cmd.ps1

# 转为 UTF-16LE base64 并执行
PS_CMD=$(iconv -f UTF-8 -t UTF-16LE /tmp/ps_cmd.ps1 | base64 -w0)
powershell.exe -EncodedCommand "$PS_CMD"
```

#### B) Pipeline + 转义变量

通过管道传递 base64 字符串，用 `\$` 防止 zsh 展开 PowerShell 变量：

```bash
base64 -w0 /tmp/src.txt | powershell.exe -Command "\$data = \$input | Out-String; [IO.File]::WriteAllBytes('C:\\path\\to\\target', [Convert]::FromBase64String(\$data.Trim()))"
```

#### C) 直接嵌入（短内容适用）

```bash
powershell.exe -Command "[IO.File]::WriteAllBytes('C:\\path\\to\\target', [Convert]::FromBase64String('BASE64STR'))"
```

### 4. 常见陷阱

- **byte[] 管道枚举**：`[Convert]::FromBase64String()` 返回 `byte[]`，用 `| % { WriteAllBytes }` 会逐个枚举字节，多次互相覆盖，文件为空。应直接传入整个数组。
- **zsh 展开 `$`**：`powershell.exe -Command "$c = ..."` 中 zsh 会把 `$c` 展开为空字符串。用 `\$c` 转义，或用 `-EncodedCommand` 彻底规避。
- **vsock 阻断**：sandbox 内 `--unshare-net` 阻断 vsock，`powershell.exe` 返回 `UtilBindVsockAnyPort:307`。必须用 `require_escalated`。

### 5. 读取 C: 盘文件

```bash
# 读取内容
powershell.exe -Command "Get-Content 'C:\\path\\to\\file.txt'"

# 同时检查大小和内容
powershell.exe -Command "Write-Host '---SIZE:'; (Get-Item 'C:\\path\\to\\file.txt').Length; Write-Host '---CONTENT:'; [IO.File]::ReadAllText('C:\\path\\to\\file.txt')"
```

### 6. 运行环境细节

- 操作系统：Ubuntu 20.04 LTS (focal)
- Shell：zsh + tmux
- 终端：Windows Terminal
- Codex 版本：0.136.0
- 模型：deepseek-v4-flash（自定义代理，通过 http://172.27.128.1:15721/v1 接入）

## 核心原则

- 不要用文件工具直接写 `/mnt/c` 下非白名单的路径
- 所有外部工具调用需要 `require_escalated`
- 用 `\$` 或 `-EncodedCommand` 避免 zsh 展开 PowerShell 变量
- 不要在管道里枚举 `byte[]`，直接传整个数组

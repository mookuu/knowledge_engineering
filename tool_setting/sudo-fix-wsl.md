---
name: sudo-fix-wsl
title: WSL sudo 修复指南
description: sudo 在 WSL 下损坏的修复方法（含完整诊断+恢复+备份路径）
metadata:
  type: reference
---

# WSL sudo 修复指南

适用环境：WSL2 Ubuntu。根文件系统 owner 为 nobody:nogroup 是正常的。

## 常见故障原因

### 1. `/usr/bin/sudo` 丢失 setuid 位（最常见）
- 正确权限：`-rwsr-xr-x` (4755, setuid)
- 错误权限：`-rwxr-xr-x` (755, 丢失 setuid)
- 后果：`sudo: effective uid is not 0`，无法提权
- 原因：`chmod 755 /usr/bin/sudo` 或 `chmod u-s /usr/bin/sudo`

### 2. `/etc/sudoers` 权限错误
- 正确：`-r--r-----` (440, owner root)
- 错误：644、600 等
- 后果：`sudo: /etc/sudoers is world writable` 或 `sudo: /etc/sudoers is mode 0644, should be 0440`

### 3. `/etc/sudoers` 语法错误
- 原因：直接编辑（未用 `visudo`）导致语法损坏

## 诊断命令
```bash
ls -la /usr/bin/sudo           # 检查 setuid 位
stat /etc/sudoers               # 检查权限
ls -la /etc/sudoers.d/          # 检查目录
sudo echo "works"               # 测试
```

## 修复方法

### 方法 A：`wsl -u root`（最推荐）
WSL 特有恢复手段，不依赖 sudo。在 PowerShell 执行：
```powershell
wsl -u root -e bash -c "chmod u+s /usr/bin/sudo && chmod 440 /etc/sudoers && visudo -c"
```
或进入交互式 root shell：
```powershell
wsl -u root
```
然后在 root shell 中执行：
```bash
chmod u+s /usr/bin/sudo
chown root:root /usr/bin/sudo
chmod 440 /etc/sudoers
chown root:root /etc/sudoers
chmod 750 /etc/sudoers.d/
chown root:root /etc/sudoers.d/
visudo -c
```

### 方法 B：`pkexec`（如果可用）
```bash
pkexec chmod u+s /usr/bin/sudo
pkexec chmod 440 /etc/sudoers
```

### 方法 C：WSL 重启（临时恢复）
```powershell
wsl --shutdown
wsl
```

## 预防性备份

备份位于 `.reasonix/sudo-backup/`（项目级，agent 可读），包含：
- `sudo_binary.bin` — sudo 可执行文件副本
- `sudo_binary_perm.txt` — `4755 65534 65534`（mode uid gid）
- `sudoers_perm.txt` — `440 65534 65534`
- `sudoers_content.txt` — `/etc/sudoers` 全文
- `sudoers_d_perm.txt` — `755 65534 65534`

### 从备份恢复（在 wsl -u root 下执行）
```bash
P=".reasonix/sudo-backup"
chmod $(cat $P/sudo_binary_perm.txt | cut -d' ' -f1) /usr/bin/sudo
chown root:root /usr/bin/sudo
chmod $(cat $P/sudoers_perm.txt | cut -d' ' -f1) /etc/sudoers
cp $P/sudoers_content.txt /etc/sudoers
chown root:root /etc/sudoers
visudo -c
```

**Why:** Codex 常通过 `sudo` 跨越 bwrap 沙箱写入系统目录（`/etc/`），一旦误改 `/usr/bin/sudo` 或 `/etc/sudoers` 的权限，sudo 就彻底不能用了，而修复 sudo 恰好又需要 root 权限——形成死锁。WSL 的 `wsl -u root` 是从 Windows 侧直接提权的手段，是唯一的 recovery path。备份在 `.reasonix/sudo-backup/` 可供恢复参考。

**How to apply:** sudo 报错（setuid/mode/syntax）时，先用 `wsl -u root` 恢复。备份文件在 `.reasonix/sudo-backup/`。

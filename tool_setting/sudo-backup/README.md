# WSL sudo 修复备份文件

## 来源

这些文件是 WSL (Ubuntu) 下 **sudo 损坏时** 的修复备份，最初保存在 `PythonBasic/.reasonix/sudo-backup/`。

## 文件清单

| 文件                   | 原始位置          | 作用                                             |
| ---------------------- | ----------------- | ------------------------------------------------ |
| `sudo_binary.bin`      | `/usr/bin/sudo`   | sudo 二进制文件副本                              |
| `sudo_binary_perm.txt` | —                 | sudo 权限记录 `4755 65534 65534`（mode uid gid） |
| `sudoers_content.txt`  | `/etc/sudoers`    | sudoers 配置文件全文                             |
| `sudoers_perm.txt`     | `/etc/sudoers`    | sudoers 权限记录 `440 65534 65534`               |
| `sudoers_d_perm.txt`   | `/etc/sudoers.d/` | sudoers.d 目录权限记录 `755 65534 65534`         |

> **注意**: 备份中 UID/GID 为 `65534`（nobody），这是出问题时的现场记录。
> 正确的属主应是 `root:root`（UID 0）。修复方法见 [`../sudo-fix-wsl.md`](../sudo-fix-wsl.md)。

## 恢复命令

```bash
# 在 wsl -u root 下执行
P="knowledge_engineering/tool_setting/sudo-backup"
chmod $(awk '{print $1}' $P/sudo_binary_perm.txt) /usr/bin/sudo
chown root:root /usr/bin/sudo
chmod $(awk '{print $1}' $P/sudoers_perm.txt) /etc/sudoers
chown root:root /etc/sudoers
chmod $(awk '{print $1}' $P/sudoers_d_perm.txt) /etc/sudoers.d/
chown root:root /etc/sudoers.d/
cp $P/sudoers_content.txt /etc/sudoers
visudo -c
```

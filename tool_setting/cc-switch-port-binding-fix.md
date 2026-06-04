# CC Switch 端口绑定失败（os error 10048）解决指南

## 问题现象

通过 CC Switch 启动代理时提示：

```
切换路由状态失败: 启动代理服务器失败: 地址绑定失败:
通常每个套接字地址(协议/网络地址/端口)只允许使用一次。 (os error 10048)
```

监听地址默认为 `0.0.0.0:15721`。

## 原因

**上一个 CC Switch 进程没有完全退出**，仍然占用着端口 15721。

CC Switch v3.16.1 的设计行为：

-   点击窗口关闭按钮（X）**默认只是隐藏到系统托盘**，程序仍在后台运行，代理服务器也在继续工作。
-   只有右键托盘 → 退出，才能真正停止代理并释放端口。
-   如果通过任务管理器强行结束进程，代理线程可能残留，端口不会立即释放。
-   某些情况下积累了大量 `CLOSE_WAIT` 状态的连接，也会阻止新实例绑定端口。

## 解决方法

### 方法一：杀掉残留进程（最快）

```cmd
:: 查看 15721 端口被谁占用
netstat -ano | findstr :15721

:: 杀掉占用进程（用查到的 PID 替换 5736）
taskkill /PID 5736 /F

:: 确认端口已释放
netstat -ano | findstr :15721

:: 重新启动 CC Switch
```

### 方法二：一键清理脚本

建一个 `cc-switch-start.bat`，放在 CC Switch 安装目录或桌面：

```bat
@echo off
chcp 65001 >nul
echo 正在清理残留的 CC Switch 进程...
taskkill /F /IM "cc-switch*" 2>nul
timeout /t 2 >nul
echo 正在启动 CC Switch...
start "" "C:\Program Files\CC-Switch\CC-Switch.exe"
```

> 如果安装路径不同，请将上面的路径替换为实际的 CC-Switch.exe 位置。

### 方法三：重启电脑

如果连 `taskkill` 也无法释放端口，说明 Windows 内核仍保留了该端口。重启电脑可彻底释放。

## 如何避免再次发生

### 1. 正确关闭 CC Switch

**避免：** 直接点窗口右上角的 X。
**正确：** 右键系统托盘中的 CC Switch 图标 → **退出**。

![托盘右键退出示意图]

### 2. 修改设置：直接退出而非最小化

如果你希望点 X 就直接退出（而不是隐藏到托盘），在 CC Switch 设置中关闭：

> **设置 → 关闭时最小化到托盘** → 关闭此选项

### 3. 通过任务管理器观察

如果不确定 CC Switch 是否还在后台运行，打开任务管理器检查进程列表中有无 `cc-switch`。

## 命令行速查表

| 用途 | 命令 |
|------|------|
| 查端口占用 | `netstat -ano \| findstr :15721` |
| 按 PID 杀进程 | `taskkill /PID <PID> /F` |
| 按名称杀进程 | `taskkill /F /IM "cc-switch*"` |
| 查看进程名 | `tasklist \| findstr <PID>` |

## 高级排查

如果上述方法无效，可以进一步查看日志：

```cmd
:: CC Switch 日志目录（默认）
%USERPROFILE%\.cc-switch\logs\cc-switch.log

:: 在日志中搜索与端口绑定相关的错误
findstr "BindFailed\|10048\|地址绑定" %USERPROFILE%\.cc-switch\logs\cc-switch.log
```

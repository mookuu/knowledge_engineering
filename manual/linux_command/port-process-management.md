# Linux 端口与进程管理

> 查看端口占用、查找进程、杀死指定端口/进程的常用命令。

---

## 1. 查看所有监听端口

```bash
# 列出所有 TCP/UDP 监听端口（推荐）
ss -tlnp

# 或使用较老的 netstat
netstat -tlnp
```

| 选项 | 含义 |
|------|------|
| `-t` | TCP 端口 |
| `-u` | UDP 端口 |
| `-l` | 仅显示监听中的端口 |
| `-n` | 以数字格式显示地址和端口（不反向解析域名） |
| `-p` | 显示占用进程的 PID 和名称（需 root 或 sudo） |

---

## 2. 查询指定端口

```bash
# ss
ss -tlnp 'sport = :8000'

# lsof（更详细，含进程名、用户、文件描述符）
lsof -i :8000
```

`lsof -i :8000` 输出示例：

```
COMMAND   PID    USER   FD   TYPE  DEVICE NODE NAME
uvicorn  930192  moku   3u   IPv4  12345   0t0  TCP *:8000 (LISTEN)
```

| 列 | 含义 |
|----|------|
| COMMAND | 进程名称 |
| PID | 进程 ID（杀进程时用这个） |
| USER | 运行用户 |
| NAME | 监听的地址和端口 |

---

## 3. 杀死进程

```bash
# 通过 PID 杀（推荐——SIGTERM，进程可自行清理）
kill 930192

# 强制杀（SIGKILL——无法被进程捕获，强行终止）
kill -9 930192

# 杀多个 PID
kill 930192 934523

# kill -9 的另一种写法
kill -SIGKILL 930192
```

---

## 4. 一行命令：查端口 → 杀进程

```bash
# 查到端口 8000 的 PID 并杀死
kill -9 $(lsof -t -i :8000)

# 如果 lsof 不可用，用 ss + awk
kill -9 $(ss -tlnp 'sport = :8000' | grep -oP 'pid=\K\d+')

# 防报错（端口没人用时不会输出错误）
kill -9 $(lsof -t -i :8000) 2>/dev/null
```

| 命令 | 作用 |
|------|------|
| `lsof -t -i :8000` | 只输出端口 8000 的 PID（纯数字，无其他信息） |
| `$(...)` | 命令替换——将查到的 PID 作为 kill 的参数 |
| `2>/dev/null` | 过滤掉"没有此进程"的报错信息 |

---

## 5. 查看运行中的后台任务

```bash
# 查看后台进程（含 PID、状态、启动命令）
jobs -l

# 查看所有进程（按用户过滤）
ps aux | grep uvicorn

# 树形显示进程关系
ps auxf | grep uvicorn

# 实时监控进程（类任务管理器）
top
htop          # 更友好的 top（需安装）
```

---

## 6. 常见场景速查

| 场景 | 命令 |
|------|------|
| **查某个端口谁在用** | `lsof -i :8000` |
| **杀端口所有进程** | `kill -9 $(lsof -t -i :8000)` |
| **查所有监听端口** | `ss -tlnp` |
| **查某个进程名** | `ps aux \| grep uvicorn` |
| **优雅停止** | `kill PID`（不加 -9，让进程自己收尾） |
| **强制停止** | `kill -9 PID`（进程不会收到关闭通知） |

---

## 7. 注意事项

- **`kill -9` 是最后手段**：先尝试普通 `kill`，让进程有机会清理临时文件、关闭数据库连接。只有普通 `kill` 无效时才用 `-9`
- **端口号变更**：如果 8000 被占用，可以在启动命令中指定不同端口：
  ```bash
  uvicorn main:app --port 8001
  npm run dev -- -p 3001
  ```
- **权限**：查看其他用户的进程或杀死其他用户的进程可能需要 `sudo`

# WSL2 性能优化方案

## 硬件环境
| 项目 | 值 |
|------|-----|
| CPU | Intel Core i7-10510U (Comet Lake) |
| 核心/线程 | **4 核 8 线程**（不是3核，Hyper-Threading 开启） |
| 基础/睿频 | 1.80 GHz / 单核 4.9 GHz, 全核 4.3 GHz |
| L3 缓存 | 8 MiB |
| 物理内存 | **16 GiB** |
| WSL 当前内存 | 7.7 GiB（默认分配 ~50%） |
| WSL Swap | 2 GiB |
| 磁盘 | SSD（非机械盘） |
| WSL 内核 | 6.6.87.2-microsoft-standard-WSL2 |
| Windows | 10.0.26200 (24H2) |

---

## 一、`.wslconfig`（Windows 侧 — 用户目录下）

**路径**: `C:\Users\<你的用户名>\.wslconfig`

### 优化后内容
```ini
[wsl2]
networkingMode=mirrored
dnsTunneling=true
firewall=true
autoProxy=true

# === 资源控制 ===
memory=8GB
processors=8
swap=4GB
localhostForwarding=true
```

### 参数说明

| 参数 | 建议值 | 说明 |
|------|--------|------|
| `memory` | 8 GB | 当前物理机空闲约 1.6 GB（峰值消耗 ~14 GB），设 8 GB 保证 WSL 足够且不挤压 Windows |
| `processors` | 8 | 显式指定全部 4 核 8 线程可用 |
| `swap` | 4 GB | 默认 2 GB → 4 GB，给编译/构建任务更多缓冲 |
| `localhostForwarding` | true | WSL 中启动的服务（如 Flask、Jupyter）可从 Windows 用 `localhost` 访问 |

> ⚠️ 修改后需**重启 WSL**：在 PowerShell 中执行 `wsl --shutdown` 再重新打开终端

---

## 二、`/etc/wsl.conf`（WSL 内）

**路径**: `/etc/wsl.conf`

### 优化后内容
```ini
[automount]
enabled = true
options = metadata,umask=22,fmask=11
mountFsTab = true

[network]
generateHosts = true
generateResolvConf = true

[interop]
enabled = true
appendWindowsPath = true

[user]
default = kali
```

### 说明
- `mountFsTab = true` — 确保 `/etc/fstab` 中的挂载生效
- `interop` 配置 — 确保可从 WSL 调用 Windows 程序（如 `powershell.exe`）
- `user.default` — 设置默认登录用户（防止以 root 启动）

---

## 三、WSL 内部内核调优

### 1. IO 调度器 → `none`（NVMe SSD 最佳）

```bash
# 临时生效
echo none | sudo tee /sys/block/sdX/queue/scheduler

# 永久生效（新建 systemd 服务或添加内核参数）
# WSL2 重启后重置，推荐写入 /etc/sysctl.d/ 或 systemd 服务
```

SSD 不需要 `mq-deadline` 的电梯排序，`none` 直接将请求发给 NVMe 队列，延迟最低。

### 2. 减少 swap 倾向（桌面开发场景）

```bash
# 查看当前值
cat /proc/sys/vm/swappiness

# 临时调低（WSL 有足够内存，不急于换出）
sudo sysctl vm.swappiness=10

# 永久
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swap.conf
```

### 3. 更积极的 page cache 回收

```bash
sudo sysctl vm.vfs_cache_pressure=50
```

让内核保留更多 dentry/inode 缓存，加快大量文件操作（如 `git status`、pip install）。

---

## 四、Windows 侧电源与性能

i7-10510U 是 U 系列低压 CPU，受**功耗/温度墙**限制明显：

1. **电源计划设为「高性能」或「终极性能」**
   - 控制面板 → 电源选项
   - 防止 CPU 在负载时过早降频

2. **确保 Hyper-V 已优化**
   - WSL2 基于 Hyper-V，Intel 版默认已优化

3. **CPU 睿频监控**
   ```bash
   # WSL 内查看实时频率
   watch -n1 "grep 'cpu MHz' /proc/cpuinfo"
   ```
   空载时应 ~0.8-1.0 GHz，负载时应 > 3.0 GHz。如果始终低于 2.0 GHz，检查 Windows 电源计划。

---

## 五、Python 开发特别建议

针对你的 Python 学习场景（之前讨论的 GIL 多线程）：

| 调优项 | 作用 |
|--------|------|
| `processors=8` | Python 多线程 I/O 密集型场景受益于更多并发线程 |
| `memory=8GB` | 避免大型测试/数据处理 OOM |
| `swappiness=10` | 减少不必要的 swap，Python 进程内存更稳定 |
| IO 调度器 `none` | pip install / 文件读写延迟更低 |

### 适用操作速查

```bash
# 1. 修改 .wslconfig 后重启
wsl --shutdown

# 2. 修改 /etc/wsl.conf 后重启
wsl --shutdown

# 3. 应用 sysctl 参数
sudo sysctl --system

# 4. 查看 CPU 是否工作在正确频率
watch -n2 "grep -c ^processor /proc/cpuinfo; echo '---'; grep 'cpu MHz' /proc/cpuinfo"
```

---

## 部署模板文件

由于当前环境为沙箱，配置模板已写入工作目录：

| 目标路径 | 模板文件 |
|---------|---------|
| `C:\Users\kalifun\.wslconfig` | `resource/memo/_dot_wslconfig` |
| `/etc/wsl.conf` | `resource/memo/_etc_wsl_conf` |

在普通 WSL 终端中执行：
```bash
# 1. 部署 .wslconfig
cp /mnt/c/Workspace/program/PythonBasic/resource/memo/_dot_wslconfig \
   /mnt/c/Users/kalifun/.wslconfig

# 2. 部署 /etc/wsl.conf
sudo cp /mnt/c/Workspace/program/PythonBasic/resource/memo/_etc_wsl_conf \
        /etc/wsl.conf

# 3. 应用 sysctl 调优
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-wsl-tune.conf
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.d/99-wsl-tune.conf
sudo sysctl --system

# 4. 设置 IO 调度器为 none
echo 'ACTION=="add|change", KERNEL=="sd*", ATTR{queue/scheduler}="none"' \
  | sudo tee /etc/udev/rules.d/60-iosched.rules
echo none | sudo tee /sys/block/sd?/queue/scheduler

# 5. 重启 WSL（PowerShell 中）
# wsl --shutdown
```

修改并重启 WSL 后，验证关键指标：

```bash
# CPU
nproc                       # 应为 8
lscpu | grep -E 'CPU\(s\)|Core|Thread'

# 内存
free -h                     # 应接近分配值

# Swap
swapon --show               # 应显示 4G

# IO 调度器
cat /sys/block/sda/queue/scheduler  # 应显示 [none]

# 内核参数
sysctl vm.swappiness        # 应为 10
```

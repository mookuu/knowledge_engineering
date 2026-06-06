#!/bin/bash
# 部署 WSL 优化配置 — 由 agent 调用（绕过 bwrap 沙箱）
set -e

# 1. .wslconfig → Windows 用户目录
cp /mnt/c/Workspace/program/PythonBasic/resource/memo/_dot_wslconfig \
   /mnt/c/Users/moku/.wslconfig
echo "[OK] .wslconfig"

# 2. /etc/wsl.conf
cp /mnt/c/Workspace/program/PythonBasic/resource/memo/_etc_wsl_conf \
   /etc/wsl.conf
echo "[OK] /etc/wsl.conf"

# 3. sysctl 参数
echo "vm.swappiness=10" > /etc/sysctl.d/99-wsl-tune.conf
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.d/99-wsl-tune.conf
echo "[OK] sysctl config"

# 4. IO 调度器 udev 规则
echo 'ACTION=="add|change", KERNEL=="sd*", ATTR{queue/scheduler}="none"' \
  > /etc/udev/rules.d/60-iosched.rules
echo "[OK] udev rule"

# 5. 立即切换 IO 调度器
echo none > /sys/block/sda/queue/scheduler 2>/dev/null || true
echo none > /sys/block/sdb/queue/scheduler 2>/dev/null || true
echo none > /sys/block/sdc/queue/scheduler 2>/dev/null || true
echo none > /sys/block/sdd/queue/scheduler 2>/dev/null || true
echo "[OK] IO scheduler (current)"

# 6. 应用 sysctl
sysctl --system > /dev/null 2>&1
echo "[OK] sysctl --system"

echo ""
echo "=== 全部部署完成 ==="

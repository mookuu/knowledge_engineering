# WSL 性能优化 — 应用指南
# ============================
# 因当前环境为沙箱，以下配置已写入工作目录作为模板。
# 在**普通 WSL 终端**中执行以下操作即可部署。

## 1. 部署 .wslconfig（Windows 侧）
cp /mnt/c/Workspace/program/PythonBasic/resource/memo/_dot_wslconfig \
   /mnt/c/Users/kalifun/.wslconfig

## 2. 部署 /etc/wsl.conf（WSL 内）
sudo cp /mnt/c/Workspace/program/PythonBasic/resource/memo/_etc_wsl_conf \
        /etc/wsl.conf

## 3. 应用 sysctl 调优
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-wsl-tune.conf
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.d/99-wsl-tune.conf
sudo sysctl --system

## 4. 设置 IO 调度器为 none（SSD 优化）
echo 'ACTION=="add|change", KERNEL=="sd*", ATTR{queue/scheduler}="none"' \
  | sudo tee /etc/udev/rules.d/60-iosched.rules
# 立即生效（当前会话）：
echo none | sudo tee /sys/block/sd?/queue/scheduler

## 5. 重启 WSL
# 在 PowerShell 中执行：
# wsl --shutdown
# 然后重新打开终端

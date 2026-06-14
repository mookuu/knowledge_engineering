# Debian 网络管理统一配置

## 背景

Debian 13 (trixie) 笔记本（Sony VAIO SVP1321）作为服务器使用，网络管理经历了一系列问题：

1. 合盖休眠 → 开盖黑屏卡死（iwlwifi 模块挂起）
2. 开盖恢复后 inet 丢失（只有 IPv6）
3. Docker 启动容器后 SSH 断连（网络管理器冲突导致路由混乱）

## 根因

| 问题 | 原因 |
|------|------|
| 合盖卡死 | iwlwifi 模块在关机/休眠时挂起，systemd 等待超时 |
| 开盖 inet 丢失 | WiFi 恢复后未自动重新获取 IP |
| SSH 断连 | **两个网络管理器（dhcpcd + ifupdown）同时管理同一个网卡 wlp1s0**，Docker 的 iptables 规则介入后路由混乱 |

## 最终方案

### 网络管理器统一

停用 dhcpcd，仅使用 ifupdown（networking.service）管理网络。

**`/etc/network/interfaces` 配置：**
```nginx
auto lo
iface lo inet loopback

auto wlp1s0
iface wlp1s0 inet static
address 192.168.0.111
netmask 255.255.255.0
gateway 192.168.0.1
dns-nameservers 8.8.8.8 114.114.114.114
wpa-ssid ArcherKn_5G
wpa-psk 密码
```

### systemd 服务

| 服务文件 | 作用 | 触发条件 |
|---------|------|---------|
| `unload-wifi.service` | 休眠前卸载 iwlwifi，防止卡死 | `shutdown.target reboot.target halt.target` |
| `dhcpcd-resume.service` | 唤醒后重启 networking.service，恢复 inet | `suspend.target hibernate.target` |

**完整链路：**
```
合盖 → unload-wifi.service (卸载iwlwifi) → 系统休眠
开盖 → dhcpcd-resume.service (restart networking) → iwlwifi自动加载 → inet恢复
```

### Docker 网络

Docker 容器使用**桥接模式**（bridge），通过端口映射暴露服务。

```bash
docker run -d --name nginx \
  -p 8080:80 \
  -v /home/moku/projects/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v /home/moku/projects/nginx/conf.d:/etc/nginx/conf.d:ro \
  -v /home/moku/projects/nginx/html:/usr/share/nginx/html:ro \
  nginx:alpine
```

**端口映射**：`-p 主机端口:容器端口`
- 外部访问 `http://192.168.0.101:8080` → 容器内 nginx 80 端口
- 如果出现网络冲突，可改为主机网络模式 `--network host`

## 解决链路：systemctl ↔ networking ↔ ifupdown

```
systemctl（服务管理器）
    │  systemctl start/stop/restart networking
    ▼
networking.service（systemd 的服务单元）
    │  执行 /usr/sbin/ifup -a
    ▼
ifup/ifdown（ifupdown 工具集）
    │  读取 /etc/network/interfaces
    ▼
配置网卡（ip addr add / ip link set）
```

| 层 | 角色 | 命令 |
|----|------|------|
| **systemd** | 服务管理器 | `systemctl restart networking` |
| **networking.service** | systemd 的一个服务单元 | 开机自动运行 `ifup -a` |
| **ifupdown** | 网络配置工具 | `ifup wlp1s0` / `ifdown wlp1s0` |
| **/etc/network/interfaces** | 配置文件 | 定义网卡、IP、网关、WiFi |

**平时只需记住：**
```bash
# 修改 interfaces 文件后重启网络
sudo systemctl restart networking

# 查看网络服务状态
sudo systemctl status networking
```

## DHCPCD 相关命令

```bash
# 查看 dhcpcd 状态
systemctl status dhcpcd

# 停用 dhcpcd
sudo systemctl stop dhcpcd
sudo systemctl disable dhcpcd

# 删除 dhcpcd 服务文件（永久移除）
sudo rm /etc/systemd/system/dhcpcd.service
sudo systemctl daemon-reload

# 使用 ifupdown 接管并验证
sudo systemctl restart networking
ip addr show wlp1s0 | grep inet
ping -c 2 192.168.0.1
```

## 相关文件路径

| 文件 | 路径 |
|------|------|
| 网络接口配置 | `/etc/network/interfaces` |
| 卸载 WiFi 服务 | `/etc/systemd/system/unload-wifi.service` |
| 唤醒网络恢复服务 | `/etc/systemd/system/dhcpcd-resume.service` |
| Docker 数据目录 | `/home/docker-data` |
| nginx 配置 | `/home/moku/projects/nginx/` |
| 本归档 | `knowledge_engineering/tool_setting/debian-network-management.md` |

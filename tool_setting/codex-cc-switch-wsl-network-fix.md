# Codex + CC Switch WSL2 镜像网络模式连通性修复

## 问题现象

通过 cc-switch 在 Codex (hyper) 连接 DeepSeek 时，持续报错：

```
Unexpected status 502 Bad Gateway: Unknown error
url: http://172.27.128.1:15721/v1/responses
```

在 WSL 中 `curl` 验证：

- 走代理（Clash `127.0.0.1:7897`）→ `502 Bad Gateway`
- 不代理直连 → `Connection timed out`

## 根因

**`config.toml` 中的 `base_url` 指向了一个已经不存在的 IP。**

```
base_url = "http://172.27.128.1:15721/v1"   ← 旧配置（失效）
```

`172.27.128.1` 是 **WSL2 早期 NAT 网络模式下** Windows 端的 `vEthernet (WSL)` 虚拟网卡 IP。当 WSL2 切换到**镜像网络模式（Mirrored Mode）**后，这个虚拟网卡及其 `172.x.x.x` 地址段不再存在：

```
Windows 当前 IP（powershell）：
- WLAN           192.168.0.111     ← 唯一非 169.254 的 IPv4 地址
- 无任何 172.x.x.x 接口

WSL 当前路由：
- default via 192.168.0.1 dev eth0
- nameserver 10.255.255.254
```

cc-switch（v3.16.1，`C:\Users\moku\AppData\Local\Programs\CC Switch\cc-switch.exe`）监听在 `0.0.0.0:15721`。在镜像网络模式下，WSL 可以通过 `127.0.0.1` 直接访问 Windows 上的服务。

## 解决方法

编辑 `/home/mooku/.codex/config.toml`，将 `base_url` 中的 IP 从 `172.27.128.1` 改为 `127.0.0.1`：

```diff
-base_url = "http://172.27.128.1:15721/v1"
+base_url = "http://127.0.0.1:15721/v1"
```

## 验证

```bash
# 关掉代理测试直连
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy ALL_PROXY
curl -v http://127.0.0.1:15721/v1/responses

# 应返回 405 Method Not Allowed (allow: POST) — 说明服务正常在响应
```

`codex doctor` 也从之前的 "request timed out" 变为 "reachable (HTTP 404)"（404 只是因为 `/v1/models` GET 不在 cc-switch 的路由表中，实际 POST /v1/responses 正常）。

## 关于 no_proxy 的踩坑记录

`~/.zshrc` 中 `proxy_on()` 的 `no_proxy` 用了 `172.27.,` 后缀点格式，注释说是「curl 7.68 用尾缀点匹配 IP 段」——但 curl 的后缀点匹配是**域名后缀匹配**（如 `.example.com` 匹配 `foo.example.com`），**不是 IP 前缀匹配**（已用 curl 7.68 实测确认）。所以 `172.27.,` 不会命中 `172.27.128.1`，请求仍然被发往代理（Clash），再由 Clash 返回 502。

## 不过 no_proxy 不是这次问题的关键——即使旁路了代理，`172.27.128.1` 本身也是连不上的。codex 内部的 HTTP 客户端有硬编码的专用地址 CIDR 旁路规则（`127.0.0.0/8`、`172.16.0.0/12`、`192.168.0.0/16` 等），不会受影响

# Reasonix 代理 + DNS 问题修复

## 问题现象

在 Hyper (zsh) 中运行 `reasonix chat` 报错：

```
# 阶段一：代理错误
error: deepseek-flash: request failed: Post "https://api.deepseek.com/chat/completions":
proxyconnect tcp: dial tcp 127.0.0.1:7897: connect: connection refused

# 阶段二：DNS 错误（代理绕过后）
error: deepseek-flash: request failed: Post "https://api.deepseek.com/chat/completions":
dial tcp: lookup api.deepseek.com on [::1]:53: read udp [::1]:40651->[::1]:53: read: connection refused
```

Hyper 启动时有以下警告和提示：

```
wsl: 检测到 localhost 代理配置，但未镜像到 WSL。NAT 模式下的 WSL 不支持 localhost 代理。
<3>WSL (1527 - Relay) ERROR: CreateProcessParseCommon:996: getpwnam(kali) failed 0
Proxy enabled (127.0.0.1:7897)
```

## 环境信息

| 项目             | 值                                                 |
| ---------------- | -------------------------------------------------- |
| WSL 发行版       | Kali Linux（`/etc/wsl.conf` 中 `default = kali`）  |
| WSL 版本         | 2.6.3.0                                            |
| 内核版本         | 6.6.87.2-1                                         |
| Hyper shell      | `/bin/zsh`                                         |
| HOME             | `/home/mooku`                                      |
| `.zshrc` 路径    | `/home/mooku/.zshrc`                               |
| Windows 系统代理 | `127.0.0.1:7897`（Clash Verge 设置）               |
| 网络模式         | WSL2 NAT（Windows 系统代理**不会**自动镜像到 WSL） |

> ⚠️ **注意**：Hyper 的 shell 是 **zsh**，`$HOME=/home/mooku`（WSL Linux home），**不是** `/c/Users/moku/`（Windows home）。.zshrc 的正确路径是 `/home/mooku/.zshrc`，不是 `/c/Users/moku/.zshrc`。

## 根因分析

### 问题一：代理错误

`~/.zshrc` 末尾有 `proxy_on` 函数，在 shell 启动时被调用：

```zsh
proxy_on() {
  export HTTP_PROXY="http://127.0.0.1:7897"
  export HTTPS_PROXY="http://127.0.0.1:7897"
  export http_proxy="$HTTP_PROXY"
  export https_proxy="$HTTPS_PROXY"
  export no_proxy="172.31.,172.30.,...,localhost,<local>"
  export NO_PROXY="$no_proxy"
  echo "Proxy enabled (127.0.0.1:7897)"
}
proxy_on   # ← shell 启动时自动调用
```

这些环境变量被 Go 编写的 reasonix 读取，导致它尝试通过 `127.0.0.1:7897` 建立 HTTP CONNECT 隧道。但：

1. **WSL2 NAT 模式下**，WSL 的 `127.0.0.1` 是 WSL **自身**的 loopback，不是 Windows 的 loopback
2. Clash Verge 运行在 Windows 端（监听 Windows 的 `127.0.0.1:7897`）
3. 即使 Clash 在运行，WSL NAT 模式也无法通过 `127.0.0.1` 访问 Windows 服务（除非开启镜像网络或 localhostForwarding）

### 问题二：DNS 错误

绕过代理后，DNS 解析失败。`/etc/resolv.conf` 原本是到 `/mnt/wsl/resolv.conf` 的 symlink，但目标文件不存在（WSL 自动生成失败），导致 DNS 完全不可用。

## 解决方法

### 1. 代理绕过（`~/.zshrc` 包装函数）

在 `~/.zshrc` 末尾添加 reasonix 包装函数，运行前清除所有代理环境变量：

```zsh
# reasonix: strip proxy (WSL NAT mode can't reach Windows proxy)
function reasonix() {
    env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy \
        -u ALL_PROXY -u all_proxy /usr/local/bin/reasonix "$@"
}
```

函数定义必须在 `proxy_on` 调用**之后**（因为 `proxy_on` 设置代理，函数在运行时读取当前 env 并清除）。

验证函数加载：

```bash
type reasonix
# 应输出: reasonix is a shell function
```

### 2. DNS 恢复（`wsl --shutdown` 重启 WSL）

代理绕过后，如果遇到 DNS 解析失败（`lookup api.deepseek.com:53: connection refused`），说明 `/etc/resolv.conf` 已损坏。原因是 WSL 的 `generateResolvConf = true` 本应自动生成，但 symlink 目标 `/mnt/wsl/resolv.conf` 不存在。

解决方案：**重启整个 WSL 实例**，让 WSL 重新自动生成 DNS 配置。

```powershell
# 在 PowerShell / CMD 中执行
wsl --shutdown
```

然后重新打开 Hyper，WSL 会自动重建 `/etc/resolv.conf`（通常指向 `10.255.255.254` 或 `127.0.0.1`，由 WSL 管理）。

> ⚠️ 不要手动创建 `/etc/resolv.conf`，因为 WSL 的 `generateResolvConf = true` 会覆盖它。如果必须手动设置，需先在 `/etc/wsl.conf` 中设置 `generateResolvConf = false`，然后重启 WSL。

### 3. 验证步骤

```bash
# 1. 确认 reasonix 函数加载
type reasonix

# 2. 检查 DNS
cat /etc/resolv.conf

# 3. 测试 DNS 解析
nslookup api.deepseek.com

# 4. 测试直连
curl -v https://api.deepseek.com

# 5. 启动 reasonix
reasonix chat
```

## 知识点总结

| 知识点           | 说明                                                                                            |
| ---------------- | ----------------------------------------------------------------------------------------------- |
| WSL NAT 模式     | WSL2 默认网络模式，WSL 的 `127.0.0.1` ≠ Windows 的 `127.0.0.1`                                  |
| WSL 镜像模式     | 可让 WSL 通过 `127.0.0.1` 访问 Windows 服务，需在 `.wslconfig` 中配置 `networkingMode=mirrored` |
| Go proxy 检测    | Go 的 `http.ProxyFromEnvironment` 读取 `HTTP_PROXY`/`HTTPS_PROXY` 环境变量                      |
| `env -u` 命令    | 启动子进程时移除指定环境变量，比 `unset` 更彻底                                                 |
| WSL 自动 DNS     | `wsl.conf` 中 `generateResolvConf = true` 让 WSL 管理 `/etc/resolv.conf`                        |
| `wsl --shutdown` | 彻底关闭 WSL 实例，重启后可修复 auto-generate 失败的 DNS                                        |

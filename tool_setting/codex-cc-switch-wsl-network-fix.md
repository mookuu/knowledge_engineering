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

不过 no_proxy 不是这次问题的关键——即使旁路了代理，`172.27.128.1` 本身也是连不上的。codex 内部的 HTTP 客户端有硬编码的专用地址 CIDR 旁路规则（`127.0.0.0/8`、`172.16.0.0/12`、`192.168.0.0/16` 等），不会受影响。

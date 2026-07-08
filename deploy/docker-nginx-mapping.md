# Docker 端口映射 & Nginx 配置关系

## 架构总览

```
浏览器 → http://192.168.0.101:8080/xxx
                    │
                    ▼
          ═══ Debian 主机 ═══════
          主机端口 8080
                    │
           docker -p 8080:80
                    │
                    ▼
          ═══ Docker 容器 ═══════
          容器内 nginx listen 80
                    │
          匹配 conf.d/*.conf
                    │
          返回 /usr/share/nginx/html/xxx
                    │
          通过 -v 挂载映射回本机
                    ▼
          /home/moku/projects/nginx/html/xxx
```

## 端口映射 `-p`

```bash
docker run -d --name nginx \
  -p 8080:80 \     # 主机端口:容器端口
  ...
```

| 位置           | 端口      | 说明                               |
| -------------- | --------- | ---------------------------------- |
| 主机（Debian） | 8080      | 外部访问的入口                     |
| 容器（nginx）  | 80        | nginx 实际监听的端口               |
| 映射关系       | 8080 → 80 | 请求到主机 8080，自动转发到容器 80 |

## 配置挂载 `-v`

```bash
docker run -d --name nginx \
  -v /home/moku/projects/nginx/conf.d:/etc/nginx/conf.d:ro \
  -v /home/moku/projects/nginx/html:/usr/share/nginx/html:ro \
  -v /home/moku/projects/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v /home/moku/projects/nginx/logs:/var/log/nginx \
  ...
```

| 本机路径         | 容器路径                 | 说明                           |
| ---------------- | ------------------------ | ------------------------------ |
| `.../conf.d/`    | `/etc/nginx/conf.d/`     | 站点配置（nginx include 目录） |
| `.../html/`      | `/usr/share/nginx/html/` | 网页静态文件                   |
| `.../nginx.conf` | `/etc/nginx/nginx.conf`  | nginx 主配置                   |
| `.../logs/`      | `/var/log/nginx/`        | 日志                           |

## 完整请求路径示例

```
访问 http://192.168.0.101:8080/flags/cn/
                    │
           主机 8080 → 容器 80
                    │
           nginx 收到请求
                    │
           匹配 conf.d/default.conf:
           location /flags/ {
               root /usr/share/nginx/html;
           }
                    │
           文件路径 = root + /flags/cn/
                    = /usr/share/nginx/html/flags/cn/
                    │
           通过 -v 挂载
                    │
           实际文件 = /home/moku/projects/nginx/html/flags/cn/
                    │
           nginx 读取文件内容返回给浏览器
```

> 💡 **Docker Nginx 常用命令已统一整理到 [`nginx_commands.md`](./nginx_commands.md#二docker-下-nginx-命令)**，包括启动容器、重载配置、查看日志、查看挂载等。

## 多个项目共存

```
conf.d/
├── default.conf     → listen 80;      站点1
├── blog.conf        → listen 8081;    站点2
└── api.conf         → listen 8082;    站点3

启动时需分别映射端口:
docker run -d --name nginx \
  -p 8080:80 \    # default.conf
  -p 8081:80 \    # blog.conf   (容器内也 listen 80)
  ...
```

> 注意：多个 server 块如果在同一个容器内 listen 不同端口，Docker 启动时要加多个 `-p` 映射。

### 多容器同端口的意义

桥接模式下，每个容器内部统一用标准端口（如80），Docker 在外部分配不同端口，省去改容器配置的麻烦。

```
场景：跑三个不同的 Web 服务

容器1: Nginx    → 内部监听 80  → 主机映射 8080  → http://192.168.0.101:8080
容器2: Python   → 内部监听 5000 → 主机映射 5001  → http://192.168.0.101:5001
容器3: Node.js  → 内部监听 3000 → 主机映射 3001  → http://192.168.0.101:3001
```

每个容器内部用什么端口都行，通过 `-p` 映射到主机不同端口，互不冲突。

**同时访问多个端口：**

```
浏览器1: http://192.168.0.101:8080  → 容器1 Nginx
浏览器2: http://192.168.0.101:5001  → 容器2 Python
浏览器3: http://192.168.0.101:3001  → 容器3 Node.js
```

各端口独立工作，同时访问几百个请求也没问题。

**主机端口 = Debian 服务器的端口。** "主机"和"服务器"在这里是同一个意思。

## 端口转发原理：docker-proxy + iptables DNAT

当你执行 `docker run -p 8080:80 nginx` 时，Docker 同时在主机上创建了两套转发机制。

### ① docker-proxy（用户态代理）

```bash
# 主机上多了一个代理进程
$ ps aux | grep docker-proxy
root  ...  docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 8080 \
                        -container-ip 172.17.0.2 -container-port 80
```

- 一个普通的 TCP 代理进程，在主机上 `listen(0.0.0.0:8080)`
- 收到请求后建立新连接转发给容器 `172.17.0.2:80`
- **主要负责本机回环流量**（如主机内 `curl 127.0.0.1:8080`）

### ② iptables DNAT（内核态转发）

```bash
# Docker 自动添加的 iptables 规则
iptables -t nat -A DOCKER ! -i docker0 -p tcp --dport 8080 \
         -j DNAT --to-destination 172.17.0.2:80
```

- 在 **内核网络栈** 层面直接改写目标地址
- **主要负责外部流量**（局域网其他机器访问 `主机IP:8080`）
- 不经过用户态进程，性能更高

### 两种流量的完整路径

```
外部访问（从局域网另一台机器来）:

  客户端 :8080  ──▶  主机 eth0                     ──▶  容器 nginx:80
                      │
                      ├─ ① iptables PREROUTING DNAT
                      │    主机 IP:8080 → 172.17.0.2:80
                      │
                      └─ ② 路由 docker0 网桥 → 容器

本机访问（主机上 curl http://localhost:8080）:

  主机 curl:8080  ──▶  docker-proxy 进程             ──▶  容器 nginx:80
                       listen(0.0.0.0:8080)
                       收到请求 → 建新 TCP 连接到 172.17.0.2:80
```

### 主机如何精准分辨多个容器的同端口？

主机**不靠容器内部的 80 去分辨**，只认**自己的主机端口号**：

```
主机端口 → 转发目标
8080    → site1 容器:80   (172.17.0.2:80)
8081    → site2 容器:80   (172.17.0.3:80)
```

每一组 `-p` 映射都对应一条独立的 iptables DNAT 规则：

```bash
-p tcp --dport 8080 -j DNAT --to-destination 172.17.0.2:80
-p tcp --dport 8081 -j DNAT --to-destination 172.17.0.3:80
```

> 类比：像一栋楼有多个房间，每个房间门牌号不同（8080、8081），但房间内编号都是 80。访客说"去 8080 号房"，门卫（iptables）就带他去对应的房间。

### 关闭 docker-proxy（可选）

```json
// /etc/docker/daemon.json
{
  "userland-proxy": false
}
```

关闭后，外部访问依然正常（靠 iptables），本机 `curl 127.0.0.1:8080` 则走 iptables OUTPUT 链 DNAT 规则处理。

---

# 桥接模式 vs Host 网络模式

| 对比             | **桥接模式（bridge）**         | **host 网络模式**           |
| ---------------- | ------------------------------ | --------------------------- |
| **隔离性**       | ✅ 容器网络与主机隔离          | ❌ 容器共享主机网络栈       |
| **端口映射**     | ✅ `-p 8080:80` 可随意映射     | ❌ 容器端口直接占主机端口   |
| **安全性**       | ✅ 容器无法直接访问主机网络    | ❌ 容器可监听任意端口       |
| **虚拟网卡**     | ✅ 创建 veth 在 docker0 网桥上 | ❌ **没有虚拟网卡**         |
| **性能**         | ⚠️ 多一层 NAT 转发，微损耗     | ✅ 直接使用主机网络，无损耗 |
| **多容器同端口** | ✅ 可映射不同主机端口          | ❌ 同一端口只能一个容器用   |
| **适用场景**     | 多容器各自暴露不同端口         | 单容器需要高性能/直连网络   |

### 多容器同端口详解

对比表中的 `多容器同端口` 这一行具体意思是：

**桥接模式 ✅** —两个容器内部都用 80 端口，但映射到主机的不同端口：

```bash
docker run -d --name site1 -p 8080:80 nginx   # 容器内部 80 → 主机 8080
docker run -d --name site2 -p 8081:80 nginx   # 容器内部 80 → 主机 8081
# 两个都能跑，互不冲突
```

**host 模式 ❌** —容器直接占主机端口，不能有两个容器同时用同一端口：

```bash
docker run -d --name site1 --network host nginx   # 占主机 80 端口
docker run -d --name site2 --network host nginx   # 启动失败！80 已被占
# 第二个容器说端口被占用
```

### 桥接模式（当前使用）

```bash
docker run -d --name nginx \
  -p 8080:80 \
  -v ... \
  nginx:alpine
```

- 容器在独立网段 `172.17.0.0/16`
- veth 虚拟网卡挂在 docker0 网桥上
- 与主机 WiFi 网段 `192.168.0.0/24` 完全隔离
- 适用于多容器场景

### host 网络模式（备用）

```bash
docker run -d --name nginx --network host \
  -v ... \
  nginx:alpine
```

- 无虚拟网卡，无 NAT 转发
- nginx 直接监听主机端口
- 解决桥接模式可能的路由冲突
- 适用于单容器性能优先场景

### 如何切换

````bash
# 桥接 → host：重建容器加上 --network host，去掉 -p
docker stop nginx && docker rm nginx
docker run -d --name nginx --network host -v ... nginx:alpine

# host → 桥接：去掉 --network host，加上 -p
docker stop nginx && docker rm nginx
docker run -d --name nginx -p 8080:80 -v ... nginx:alpine
```ost → 桥接：去掉 --network host，加上 -p
docker stop nginx && docker rm nginx
docker run -d --name nginx -p 8080:80 -v ... nginx:alpine
````

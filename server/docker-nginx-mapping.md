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

| 位置 | 端口 | 说明 |
|------|------|------|
| 主机（Debian） | 8080 | 外部访问的入口 |
| 容器（nginx） | 80 | nginx 实际监听的端口 |
| 映射关系 | 8080 → 80 | 请求到主机 8080，自动转发到容器 80 |

## 配置挂载 `-v`

```bash
docker run -d --name nginx \
  -v /home/moku/projects/nginx/conf.d:/etc/nginx/conf.d:ro \
  -v /home/moku/projects/nginx/html:/usr/share/nginx/html:ro \
  -v /home/moku/projects/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v /home/moku/projects/nginx/logs:/var/log/nginx \
  ...
```

| 本机路径 | 容器路径 | 说明 |
|---------|---------|------|
| `.../conf.d/` | `/etc/nginx/conf.d/` | 站点配置（nginx include 目录） |
| `.../html/` | `/usr/share/nginx/html/` | 网页静态文件 |
| `.../nginx.conf` | `/etc/nginx/nginx.conf` | nginx 主配置 |
| `.../logs/` | `/var/log/nginx/` | 日志 |

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

# 桥接模式 vs Host 网络模式

| 对比 | **桥接模式（bridge）** | **host 网络模式** |
|------|-------------------|-----------------|
| **隔离性** | ✅ 容器网络与主机隔离 | ❌ 容器共享主机网络栈 |
| **端口映射** | ✅ `-p 8080:80` 可随意映射 | ❌ 容器端口直接占主机端口 |
| **安全性** | ✅ 容器无法直接访问主机网络 | ❌ 容器可监听任意端口 |
| **虚拟网卡** | ✅ 创建 veth 在 docker0 网桥上 | ❌ **没有虚拟网卡** |
| **性能** | ⚠️ 多一层 NAT 转发，微损耗 | ✅ 直接使用主机网络，无损耗 |
| **多容器同端口** | ✅ 可映射不同主机端口 | ❌ 同一端口只能一个容器用 |
| **适用场景** | 多容器各自暴露不同端口 | 单容器需要高性能/直连网络 |

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

```bash
# 桥接 → host：重建容器加上 --network host，去掉 -p
docker stop nginx && docker rm nginx
docker run -d --name nginx --network host -v ... nginx:alpine

# host → 桥接：去掉 --network host，加上 -p
docker stop nginx && docker rm nginx
docker run -d --name nginx -p 8080:80 -v ... nginx:alpine
```

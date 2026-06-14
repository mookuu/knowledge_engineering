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

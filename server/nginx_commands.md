# Nginx 操作备忘

> **适用**：Nginx 日常管理、常用命令与基础配置。
> **平台**：Windows / Linux / macOS；命令在 Linux / macOS 上通常相同，Windows 使用 `nginx.exe`。
> **官方**：[Nginx 文档](https://nginx.org/en/docs/) · [Nginx 中文文档](https://www.nginx.cn/doc/)

---

## 一、常用命令

### 1.1 启动 / 停止 / 重载

```bash
# ── 启动 Nginx ──

# Linux / macOS
nginx

# Windows (Cmd) — 启动新窗口后台运行
start nginx
# 或直接运行（会占用当前终端）
nginx.exe

# Windows (PowerShell) — 启动新进程后台运行
Start-Process nginx
# 或直接运行
nginx.exe
```

```bash
# ── 停止 / 重载（三平台通用）──

# 快速停止（立即终止，不保存当前连接）
nginx -s stop

# 优雅停止（等待当前连接处理完毕再退出）
nginx -s quit

# 重新加载配置（热更新，不中断服务）
nginx -s reload

# 重新打开日志文件（用于日志切割）
nginx -s reopen
```

### 1.2 测试配置

```bash
# 测试配置文件语法是否正确
nginx -t

# 测试并显示具体配置文件的路径
nginx -T

# 指定配置文件测试
nginx -t -c /path/to/nginx.conf
```

### 1.3 查看信息

```bash
# 查看 Nginx 版本
nginx -v

# 查看 Nginx 版本及编译参数
nginx -V

# 查看帮助
nginx -h
```

### 1.4 systemd 管理（Linux）

```bash
# 启停服务
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx

# 重载配置
sudo systemctl reload nginx

# 开机自启
sudo systemctl enable nginx

# 查看状态
sudo systemctl status nginx
```

### 1.5 Docker 中管理 Nginx

```bash
# 启动 Nginx 容器
docker run -d --name nginx -p 80:80 nginx

# 挂载自定义配置
docker run -d --name nginx \
  -p 80:80 \
  -v /host/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v /host/conf.d:/etc/nginx/conf.d:ro \
  nginx

# 重新加载配置（无需重启容器）
docker exec nginx nginx -s reload
```

---

## 二、配置文件结构

### 2.1 主要目录与文件

| 路径                          | 说明                                     |
| ----------------------------- | ---------------------------------------- |
| `/etc/nginx/nginx.conf`       | 主配置文件                               |
| `/etc/nginx/conf.d/`          | 附加配置目录（推荐在此放置站点配置）     |
| `/etc/nginx/sites-available/` | 站点可用配置（Debian/Ubuntu 风格）       |
| `/etc/nginx/sites-enabled/`   | 站点启用配置（软链接到 sites-available） |
| `/var/log/nginx/access.log`   | 访问日志                                 |
| `/var/log/nginx/error.log`    | 错误日志                                 |
| `/usr/share/nginx/html/`      | 默认网站根目录                           |
| `/etc/nginx/ssl/`             | SSL 证书目录                             |

### 2.2 配置上下文层级

```
main                 # 全局设置
└── events           # 事件模型配置
    └── http         # HTTP 核心配置
        ├── upstream     # 上游服务器组（负载均衡）
        ├── server       # 虚拟主机
        │   ├── location     # URI 匹配规则
        │   └── location
        └── server
```

---

## 三、基础配置示例

### 3.1 静态网站

```nginx
server {
    listen 80;
    server_name example.com www.example.com;

    root /var/www/example;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }

    # 静态资源缓存（图片、CSS、JS）
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
    }
}
```

### 3.2 反向代理

```nginx
server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket 支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # 限制请求体大小（例如上传文件最大 10M）
    client_max_body_size 10M;
}
```

### 3.3 HTTPS / SSL

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;

    # SSL 证书
    ssl_certificate     /etc/nginx/ssl/example.com.pem;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;

    # 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    root /var/www/example;
    index index.html;
}

# HTTP 自动跳转 HTTPS
server {
    listen 80;
    server_name example.com;
    return 301 https://$host$request_uri;
}
```

### 3.4 负载均衡

```nginx
upstream backend {
    # 负载均衡算法：默认轮询（round-robin）
    # ip_hash;       # 同一 IP 固定到同一服务器
    # least_conn;    # 转发给连接数最少的服务器
    # hash $uri;     # 按 URI 哈希分配

    server 192.168.1.10:8080 weight=3 max_fails=3 fail_timeout=30s;
    server 192.168.1.11:8080 weight=2;
    server 192.168.1.12:8080 backup;  # 备用实例
}

server {
    listen 80;
    server_name app.example.com;

    location / {
        proxy_pass http://backend;
    }
}
```

### 3.5 URL 重写与重定向

```nginx
server {
    listen 80;
    server_name example.com;

    # 301 永久重定向（SEO 友好）
    location /old-page {
        return 301 /new-page;
    }

    # rewrite 指令（正则匹配）
    rewrite ^/articles/(\d+)$ /post?id=$1 permanent;

    # 强制 www 前缀
    # if ($host !~ ^www\.) {
    #     return 301 https://www.$host$request_uri;
    # }
}
```

### 3.6 访问控制与安全

```nginx
server {
    # IP 白名单（仅允许内网访问）
    location /admin {
        allow 192.168.1.0/24;
        allow 10.0.0.0/8;
        deny all;
    }

    # 限制请求频率（防暴力破解）
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
    location /login {
        limit_req zone=login burst=5 nodelay;
        proxy_pass http://127.0.0.1:3000;
    }

    # 隐藏 Nginx 版本号
    server_tokens off;
}
```

### 3.7 日志配置

```nginx
# 自定义日志格式
log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                '$status $body_bytes_sent "$http_referer" '
                '"$http_user_agent" "$http_x_forwarded_for"';

log_format json escape=json '{'
    '"time":"$time_local",'
    '"remote_addr":"$remote_addr",'
    '"request":"$request",'
    '"status":$status,'
    '"body_bytes":$body_bytes_sent,'
    '"referer":"$http_referer",'
    '"user_agent":"$http_user_agent",'
    '"x_forwarded_for":"$http_x_forwarded_for"'
'}';

server {
    access_log /var/log/nginx/example_access.log main;
    error_log  /var/log/nginx/example_error.log warn;
}
```

---

## 四、运维技巧

### 4.1 日志切割（logrotate）

```bash
# /etc/logrotate.d/nginx
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
    endscript
}
```

### 4.2 常用检查命令

```bash
# 检查哪些端口被 Nginx 监听
ss -tlnp | grep nginx

# 查看 Nginx 进程
ps aux | grep nginx

# 测试 DNS 解析是否正常
curl -I http://example.com

# 查看当前连接数
curl http://127.0.0.1/nginx_status

# 实时监控访问日志
tail -f /var/log/nginx/access.log

# 按状态码统计
awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn
```

### 4.3 常见问题排查

| 问题                                         | 排查方向                                                      |
| -------------------------------------------- | ------------------------------------------------------------- | --------------------- |
| `nginx: [emerg] bind() to 0.0.0.0:80 failed` | 端口被占用，`netstat -ano                                     | findstr :80` 查找进程 |
| `403 Forbidden`                              | 文件权限不足，检查 `index` 文件是否存在，目录是否有 `+x` 权限 |
| `502 Bad Gateway`                            | 后端服务未启动或挂了，检查 proxy_pass 目标                    |
| `413 Request Entity Too Large`               | 增大 `client_max_body_size`                                   |
| `SSL: error:0A000438`                        | 证书文件格式或路径错误                                        |

---

## 五、参考链接

- [Nginx 官方文档](https://nginx.org/en/docs/)
- [Nginx 官方初学者指南](https://nginx.org/en/docs/beginners_guide.html)
- [Nginx Config 在线生成器](https://nginxconfig.io/)
- [DigitalOcean Nginx 配置速查表](https://www.digitalocean.com/community/tools/nginx)

# Web 服务器、HTTP 服务器与应用服务器

## 基本概念

### 什么是 Web 服务器

**Web 服务器** 广义上指提供 Web 服务的软件，狭义上指 **处理 HTTP 请求并返回响应** 的软件。

### 核心功能

1. **监听端口**（默认 80/443），接受 HTTP/HTTPS 请求
2. **解析请求**（方法、路径、头部、正文）
3. **处理请求** — 返回静态文件或转发给应用
4. **返回响应**（状态码、响应头、响应体）

---

## 常见服务器类型

| 类型               | 功能                             | 处理内容                     | 代表软件                   |
| ------------------ | -------------------------------- | ---------------------------- | -------------------------- |
| **HTTP 服务器**    | 处理 HTTP 协议请求，返回静态资源 | 静态文件（HTML/CSS/JS/图片） | Nginx、Apache httpd、Caddy |
| **Web 服务器**     | = HTTP 服务器 + 可能包含动态处理 | 静态 + 动态（需搭配）        | 同上 + IIS                 |
| **应用服务器**     | 运行业务代码，动态生成内容       | 执行后端程序逻辑             | Tomcat、uWSGI、Gunicorn    |
| **反向代理服务器** | 转发请求到后端                   | 分发/过滤/缓存               | Nginx、HAProxy、Traefik    |
| **API 网关**       | 微服务统一入口                   | 路由/认证/限流/熔断          | Kong、APISIX、Ocelot       |

---

## 常用软件对比

### Nginx

- **类型**：HTTP 服务器 + 反向代理 + 负载均衡 + 邮件代理
- **特点**：高并发（epoll 事件驱动）、低内存、配置简洁
- **场景**：静态文件服务、反向代理、负载均衡、API 网关
- **配置文件**：`nginx.conf`

```
events {
    worker_connections 1024;
}
http {
    server {
        listen 80;
        location / {
            proxy_pass http://backend;
        }
    }
}
```

### Apache HTTP Server（httpd）

- **类型**：HTTP 服务器
- **特点**：模块化（可加载几十种模块）、`.htaccess` 目录级配置
- **场景**：传统 LAMP 架构、需要复杂访问控制的场景
- **工作模式**：prefork（进程）/ worker（线程）/ event

### Caddy

- **类型**：HTTP 服务器 + 反向代理
- **特点**：**自动 HTTPS**（Let's Encrypt 自动申请证书）、配置最简单
- **场景**：个人项目、中小型网站、需要快速上线的场景
- **配置**：

```
example.com {
    reverse_proxy localhost:8080
}
```

### Tomcat

- **类型**：Java 应用服务器（Servlet 容器）
- **特点**：运行 Java Web 应用（JSP/Servlet）
- **场景**：Java Web 项目、Spring Boot 内嵌

### IIS（Internet Information Services）

- **类型**：Web 服务器（Windows）
- **特点**：Windows 原生，GUI 管理，支持 ASP.NET
- **场景**：Windows Server + .NET 项目

---

## 常见组合架构

### 经典 LAMP/LEMP

```
Nginx/Apache ──► PHP-FPM ──► MySQL
   ↑                    ↑
 静态文件             PHP 处理
```

### 前后端分离

```
Nginx（前端静态文件 + API 代理）
  ├── / → 静态文件（SPA）
  └── /api → proxy_pass → 后端应用服务器
```

### 微服务架构

```
Nginx / Traefik / API Gateway
  ├── /user → User Service
  ├── /order → Order Service
  └── /payment → Payment Service
```

### 多层反向代理

```
客户端 ──► CDN ──► Nginx ──► 应用服务器 ──► 数据库
             ↑          ↑           ↑
           静态缓存    反向代理    业务逻辑
```

---

## 核心概念对比

| 概念             | HTTP 服务器              | Web 服务器          | 应用服务器                |
| ---------------- | ------------------------ | ------------------- | ------------------------- |
| **处理静态内容** | ✅                       | ✅                  | ❌（不处理）              |
| **处理动态内容** | ❌                       | ❌（需要下游）      | ✅                        |
| **运行代码**     | ❌                       | ❌                  | ✅                        |
| **常见定位**     | Nginx/Apache/Caddy       | 广义称呼            | Tomcat/uWSGI/Gunicorn     |
| **协议支持**     | HTTP/1.1, HTTP/2, HTTP/3 | 同上 + 可能支持更多 | HTTP + 专用协议（如 AJP） |

> ⚠️ **注意**：现代 Nginx 已远远不止是 HTTP 服务器，它同时是反向代理、负载均衡器、缓存服务器、API 网关。同样，Tomcat 本身包含了 HTTP 服务器功能，本质上也可以算作 Web 服务器。

## 常见端口

| 端口 | 服务                              |
| ---- | --------------------------------- |
| 80   | HTTP                              |
| 443  | HTTPS                             |
| 8080 | 常用备用 HTTP 端口 / Tomcat       |
| 8443 | 备用 HTTPS 端口                   |
| 3000 | Node.js / 开发服务器              |
| 8000 | Python 开发服务器（Django/Flask） |
| 5000 | Flask 默认端口                    |

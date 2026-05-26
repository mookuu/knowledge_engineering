### Docker 执行链路

---

```
docker compose up -d --build
│
├─ 阶段一：构建镜像（读 Dockerfile，逐行执行）
│   ├─ FROM python:3.12-slim       ← 拉取基础镜像
│   ├─ ENV ...                      ← 设置环境变量
│   ├─ WORKDIR /app                 ← 创建工作目录
│   ├─ COPY requirements.txt .      ← 复制依赖文件
│   ├─ RUN pip install ...          ← 安装依赖
│   ├─ COPY . .                     ← 复制项目代码
│   ├─ RUN chmod +x entrypoint.sh   ← 加执行权限
│   ├─ ENV DJANGO_DEBUG=0 ...       ← 设置默认环境变量
│   └─ ENTRYPOINT [...]             ← 记录启动命令（此时不执行）
│   → 产出：镜像 django_todo_practice:latest
│
├─ 阶段二：运行容器（读 docker-compose.yml）
│   ├─ 用刚构建好的镜像创建容器
│   ├─ 映射端口 8091:8000           ← ports
│   ├─ 覆盖/补充环境变量            ← environment
│   ├─ 挂载数据卷 /data             ← volumes
│   └─ 启动容器 → 执行 ENTRYPOINT
│       └─ /app/entrypoint.sh
│           ├─ python manage.py migrate
│           └─ exec gunicorn ...    ← 应用运行
```

### 关键区分

| | 构建阶段 (build) | 运行阶段 (run) |
|:---|:---|:---|
| 读取文件 | Dockerfile | docker-compose.yml |
| 做什么 | 安装依赖、复制代码 → 打包成镜像 | 用镜像创建容器 → 启动应用 |
| 执行的指令 | `FROM`, `COPY`, `RUN` | `ENTRYPOINT` / `CMD` |
| 何时触发 | `docker build` 或 `--build` 时 | `docker run` 或 `docker compose up` 时 |
| 产出 | 镜像（可复用、可分发） | 运行中的容器 |

Dockerfile 是"打包菜谱"，`docker build` 按菜谱做出镜像；docker-compose.yml 是"上菜配置"，`docker compose up` 用镜像启动容器并执行 `ENTRYPOINT`。

### 镜像命名规约

Docker Compose 自动生成的镜像名：`<项目名>-<服务名>`

+ 项目名：默认取 docker-compose.yml 所在目录的文件夹名
+ 服务名：docker-compose.yml 中 `services:` 下定义的服务名

自定义方式：
+ 命令行指定项目名：`docker compose -p myproject up`
+ .env 文件：`COMPOSE_PROJECT_NAME=myproject`
+ docker-compose.yml 中加 `image: my-app:latest` 完全控制镜像名

### entrypoint.sh 说明

+ 只在 Docker 容器启动时执行（由 Dockerfile 的 `ENTRYPOINT` 指定）
+ 不会在本地开发、镜像构建阶段、`docker exec` 进入容器时执行
+ 用途：串联多步启动操作（migrate → gunicorn），Dockerfile 的 `ENTRYPOINT`/`CMD` 只能写一条命令

### Docker 常见命令

---

#### 镜像管理 Image

- `docker pull <image>:<tag>` — 拉取镜像，如 `docker pull python:3.13`
- `docker images` — 列出本地所有镜像
- `docker rmi <image>` — 删除镜像
- `docker build -t <name>:<tag> .` — 根据 Dockerfile 构建镜像
- `docker tag <source> <target>` — 给镜像打标签
- `docker push <image>:<tag>` — 推送镜像到仓库
- `docker save -o <file>.tar <image>` — 导出镜像为 tar 文件
- `docker load -i <file>.tar` — 从 tar 文件导入镜像
- `docker image prune` — 清理无用镜像（dangling）
- `docker search <keyword>` — 搜索 Docker Hub 上的镜像

#### 容器生命周期 Container Lifecycle

- `docker run <image>` — 创建并启动容器
  - `-d` — 后台运行（detached）
  - `-it` — 交互式终端
  - `--name <name>` — 指定容器名
  - `-p <host>:<container>` — 端口映射，如 `-p 8080:80`
  - `-v <host_path>:<container_path>` — 挂载卷
  - `-e KEY=VALUE` — 设置环境变量
  - `--rm` — 容器退出后自动删除
  - `--restart=always` — 自动重启策略
  - `--network <name>` — 指定网络
- `docker start <container>` — 启动已停止的容器
- `docker stop <container>` — 优雅停止容器（发送 SIGTERM）
- `docker kill <container>` — 强制停止容器（发送 SIGKILL）
- `docker restart <container>` — 重启容器
- `docker rm <container>` — 删除已停止的容器
- `docker rm -f <container>` — 强制删除运行中的容器

#### 容器信息查看 Container Info

- `docker ps` — 列出运行中的容器
- `docker ps -a` — 列出所有容器（含已停止）
- `docker logs <container>` — 查看容器日志
  - `-f` — 实时跟踪日志（类似 tail -f）
  - `--tail <n>` — 只显示最后 n 行
- `docker inspect <container>` — 查看容器详细信息（JSON）
- `docker stats` — 实时查看容器资源占用（CPU、内存等）
- `docker top <container>` — 查看容器内进程
- `docker port <container>` — 查看端口映射

#### 容器交互 Container Interaction

- `docker exec -it <container> bash` — 进入运行中的容器（启动 bash）
- `docker exec -it <container> sh` — 进入容器（sh，适用于 Alpine 等轻量镜像）
- `docker exec <container> <command>` — 在容器内执行命令
- `docker cp <container>:<path> <local_path>` — 从容器复制文件到宿主机
- `docker cp <local_path> <container>:<path>` — 从宿主机复制文件到容器
- `docker attach <container>` — 附加到容器的标准输入输出（Ctrl+P Ctrl+Q 脱离）

#### 数据卷 Volume

- `docker volume create <name>` — 创建数据卷
- `docker volume ls` — 列出所有数据卷
- `docker volume inspect <name>` — 查看数据卷详情
- `docker volume rm <name>` — 删除数据卷
- `docker volume prune` — 清理未使用的数据卷

#### 网络 Network

- `docker network ls` — 列出所有网络
- `docker network create <name>` — 创建自定义网络
- `docker network inspect <name>` — 查看网络详情
- `docker network connect <network> <container>` — 将容器连接到网络
- `docker network disconnect <network> <container>` — 断开容器与网络的连接
- `docker network rm <name>` — 删除网络

#### Docker Compose

- `docker compose up` — 启动所有服务
  - `-d` — 后台运行
  - `--build` — 强制重新构建镜像
- `docker compose up --build -d <service>` — **单独重建并启动某个服务**（如 `api`、`web`）
- `docker compose down` — 停止并删除所有容器、网络
  - `-v` — 同时删除数据卷
- `docker compose ps` — 查看服务状态
- `docker compose logs` — 查看所有服务日志
  - `-f` — 实时跟踪
- `docker compose logs -f <service>` — 跟踪单个服务的日志
- `docker compose exec <service> bash` — 进入某个服务的容器
- `docker compose build` — 构建或重新构建所有服务镜像
- `docker compose build <service>` — 仅重新构建某个服务的镜像
- `docker compose pull` — 拉取服务镜像
- `docker compose restart` — 重启服务
- `docker compose stop` — 停止服务（不删除容器）
- `docker compose config` — 验证并查看合并后的配置

#### 系统清理 System Cleanup

- `docker system df` — 查看 Docker 磁盘占用
- `docker system prune` — 一键清理所有未使用资源（容器、网络、镜像、缓存）
  - `-a` — 同时清理所有未被使用的镜像（不仅是 dangling）
  - `--volumes` — 同时清理数据卷
- `docker container prune` — 清理已停止的容器
- `docker image prune -a` — 清理所有未使用的镜像

---

### 常用组合示例

```bash
# 运行 MySQL 容器
docker run -d --name mysql \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=secret \
  -v mysql_data:/var/lib/mysql \
  mysql:8

# 运行 Python 脚本
docker run --rm -v $(pwd):/app -w /app python:3.13 python script.py

# 进入正在运行的容器调试
docker exec -it mysql bash

# 查看容器实时日志
docker logs -f --tail 100 mysql

# 导出/导入镜像（离线部署）
docker save -o myapp.tar myapp:latest
docker load -i myapp.tar

# Compose 常用流程
docker compose up -d --build    # 构建并后台启动
docker compose logs -f          # 跟踪日志
docker compose down -v          # 停止并清理
```

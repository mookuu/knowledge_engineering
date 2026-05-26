### manage.py — Django 命令行管理入口

由 `django-admin startproject` 自动生成，是 Django 项目的**命令分发器**。

本身不含业务逻辑，作用是：
1. 设置环境变量 `DJANGO_SETTINGS_MODULE` 指向项目配置
2. 把命令行参数转发给 Django 的 `execute_from_command_line` 处理

---

### 各阶段使用场景

#### 项目创建时

```bash
django-admin startproject todo_site .   # 创建项目（此时自动生成 manage.py）
python manage.py startapp todos         # 创建应用模块
```

#### 日常开发时

```bash
# 每次修改 models.py 后
python manage.py makemigrations         # 1. 根据模型变更生成迁移文件
python manage.py migrate                # 2. 执行迁移，建表/改表

# 启动开发服务器
python manage.py runserver              # 默认 127.0.0.1:8000
python manage.py runserver 0.0.0.0:8080 # 指定地址和端口

# 调试/查看数据
python manage.py shell                  # 进入 Python shell（可操作 ORM）
python manage.py dbshell                # 进入数据库 shell（如 sqlite3）
```

#### 用户管理时

```bash
python manage.py createsuperuser        # 创建管理员（用于访问 /admin）
python manage.py changepassword <user>  # 修改密码
```

#### 部署时

```bash
python manage.py collectstatic          # 收集静态文件到 STATIC_ROOT
python manage.py check --deploy         # 检查部署安全项（HTTPS、SECRET_KEY 等）
python manage.py migrate --noinput      # 无交互迁移（CI/Docker 用）
```

#### 测试时

```bash
python manage.py test                   # 运行所有测试
python manage.py test todos             # 只测试 todos 应用
```

#### Docker 容器中

entrypoint.sh 里调用的就是 manage.py：

```bash
python manage.py migrate --noinput      # 容器启动时自动迁移
```

容器内不用 runserver，而是用 gunicorn 替代（生产级服务器）。WSGI/ASGI 与 Gunicorn 的关系见 [django_wsgi_asgi.md](./django_wsgi_asgi.md)。

---

### 常用命令速查

| 时间点 | 常用命令 |
|:---|:---|
| 创建项目/应用 | `startproject`, `startapp` |
| 模型变更后 | `makemigrations` → `migrate` |
| 写代码调试 | `runserver`, `shell` |
| 首次部署 | `createsuperuser`, `collectstatic` |
| 每次部署 | `migrate --noinput`, `check --deploy` |
| 跑测试 | `test` |

---

### manage.py vs django-admin

| | manage.py | django-admin |
|:---|:---|:---|
| 自动设置 `DJANGO_SETTINGS_MODULE` | 是 | 否，需手动指定 |
| 使用场景 | 项目目录内日常开发 | 创建新项目 `django-admin startproject` |

日常开发基本只用 `python manage.py ...`，因为它自动知道项目配置在哪。

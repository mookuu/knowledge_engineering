# WSGI 与 ASGI

本文说明 Django 项目中 **WSGI / ASGI** 是什么、二者区别，以及和 `manage.py`、`runserver` 的关系。示例路径对应本仓库 **`AiBasic/django_learn_demo`**（配置包名 `learn_site`）。

---

## 一、它们是什么

**WSGI**（Web Server Gateway Interface）和 **ASGI**（Asynchronous Server Gateway Interface）都是 Python Web 应用与 Web 服务器之间的**标准接口**（协议）：

- 服务器（Gunicorn、Uvicorn 等）按协议把 **HTTP 请求**交给 Django
- Django 处理完后把 **HTTP 响应**交回服务器

项目里对应的入口文件：

| 文件 | 作用 |
|------|------|
| `learn_site/wsgi.py` | WSGI 入口，`application = get_wsgi_application()` |
| `learn_site/asgi.py` | ASGI 入口，`application = get_asgi_application()` |

`application` 是部署时服务器要加载的**可调用对象**。

---

## 二、WSGI 与 ASGI 对比

| | **WSGI** | **ASGI** |
|---|----------|----------|
| 特点 | 同步为主，传统标准 | 支持异步、WebSocket、长连接 |
| Django 支持 | 一直支持 | Django 3.0+ 正式支持 |
| 典型服务器 | Gunicorn、uWSGI、Waitress | Uvicorn、Daphne、Hypercorn |
| 项目文件 | `wsgi.py` | `asgi.py` |
| 适用场景 | 普通页面、表单、REST（同步视图） | WebSocket、SSE、强实时、`async def` 视图 |

**学习阶段**：笔记 CRUD、模板表单等，**WSGI + Gunicorn 即可**；`asgi.py` 多为项目模板自带，便于以后扩展。

---

## 三、请求如何进入 Django

```text
浏览器
  ↓ HTTP
Web 服务器（开发：runserver 内置；生产：Gunicorn / Uvicorn 等）
  ↓ 按 WSGI 或 ASGI 协议调用
application（wsgi.py 或 asgi.py）
  ↓
Django（中间件 → urls → 视图 → 模板）
  ↓
HTTP 响应
```

---

## 四、和 manage.py、runserver 的区别

| 场景 | 使用的入口 |
|------|------------|
| 本地开发 `python manage.py runserver` | **manage.py**（命令行工具，内置开发服务器） |
| 生产部署（同步 HTTP） | **wsgi.py** 的 `application` |
| 生产部署（异步 / WebSocket） | **asgi.py** 的 `application` |

- **manage.py**：日常 `migrate`、`runserver`、`shell` 等，见 [manage_py.md](./manage_py.md)
- **wsgi.py / asgi.py**：**上线**时由 Gunicorn、Uvicorn 等加载，不是 `runserver` 直接读取的文件

开发时几乎只用 `runserver`；理解 WSGI/ASGI 是为了知道**生产环境怎么挂 Django**。

---

## 五、本仓库示例代码

### wsgi.py（同步部署入口）

```python
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "learn_site.settings")
application = get_wsgi_application()
```

### asgi.py（异步部署入口）

```python
import os
from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "learn_site.settings")
application = get_asgi_application()
```

二者都会设置 `DJANGO_SETTINGS_MODULE`，指向同一套 `settings.py`。

---

## 六、生产部署示例（概念）

```bash
# WSGI + Gunicorn（常见）
gunicorn learn_site.wsgi:application --bind 0.0.0.0:8000

# ASGI + Uvicorn（需异步 / WebSocket 时）
uvicorn learn_site.asgi:application --host 0.0.0.0 --port 8000
```

容器或 Nginx 反向代理后，对外仍是 HTTP；差异在**应用进程**用 WSGI 还是 ASGI 栈。

---

## 七、怎么选

| 需求 | 建议 |
|------|------|
| 本地学模板、ORM、表单 | `python manage.py runserver` |
| 简单上线、传统页面/API | **WSGI** + Gunicorn |
| WebSocket、Channels、大量 `async` 视图 | **ASGI** + Uvicorn / Daphne |

`django_learn_demo` 的 `notes` 应用无 WebSocket，以 WSGI 部署为主即可。

---

## 八、三个入口一句话

| 文件 | 一句话 |
|------|--------|
| `manage.py` | 开发命令入口 |
| `wsgi.py` | 生产 HTTP（同步）插头 |
| `asgi.py` | 生产 HTTP + 异步 / WebSocket 插头 |

**记忆**：WSGI/ASGI 是「服务器和 Django 之间的插头」；开发用 `manage.py`，上线用 `wsgi.py` 或 `asgi.py` 里的 `application`。

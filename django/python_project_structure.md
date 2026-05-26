# Python 项目结构与各级目录命名

本文整理自学习笔记：通用结构、Web 项目、以及 Django / FastAPI / Flask 的对比。

---

## 一、两种常见顶层布局

### 1. `src/` 布局（推荐新项目）

把可安装代码放进 `src/`，测试和脚本放在外侧，可减少误 import 旁路文件等问题。

```text
my_project/
├── src/
│   └── my_package/          # 实际包目录（与 import 的包名一致）
├── tests/
├── docs/
├── scripts/                 # 或 tools/
├── pyproject.toml           # 或 setup.cfg + setup.py（老项目）
├── README.md
└── LICENSE
```

- **`src/<包名>/`**：如 `my_package`，全小写、**`snake_case`**（PyPI 项目名可用短横线，但 import 侧须合法标识符）。
- **`tests/`**：unittest / pytest。
- **`docs/`**：Sphinx、MkDocs 等文档。
- **`scripts/`**：一次性脚本、数据处理；偏「项目内部工具」时也有人用 **`tools/`**。

### 2. 扁平布局（小项目常见）

包目录放在仓库根下。

```text
my_project/
├── my_package/
├── tests/
├── pyproject.toml
└── README.md
```

命名规则与上相同。

---

## 二、包内多级目录命名

- **`my_package/`**：一层包。
- **`my_package/submodule/`**：子包；若需作为包导入，目录内放 **`__init__.py`**（namespace 包另说）。
- **模块文件**：**`snake_case.py`**，例如 `cli.py`、`data_loader.py`。

建议避免：

- **`MyPackage/`**、**带空格**、**与标准库冲突**（如 `email/`、`json/`、`test/`）等。

---

## 三、常与各级目录放在一起的文件

| 用途       | 常见文件名 / 目录                          |
|------------|---------------------------------------------|
| 依赖       | `requirements.txt` / `requirements/`     |
| 现代打包   | **`pyproject.toml`**                       |
| 类型检查   | `mypy.ini` 或 pyproject 中 `[tool.mypy]`  |
| 代码风格   | `.flake8`、pyproject 中 ruff/black 配置    |
| 测试       | **`tests/`**、`pytest.ini`、`conftest.py`  |
| 配置       | **`config/`**、或包内 **`settings/`**      |
| 静态数据   | **`data/`**（大文件注意是否入仓、git-lfs） |
| Notebooks | **`notebooks/`** 或 **`analysis/`**       |
| CI         | **`.github/workflows/`**                    |
| 容器       | **`Dockerfile`**、`docker-compose.yml`    |

### 命名速记

1. **目录与 `.py` 文件**：**`snake_case`**，短小清晰。
2. **对外包名**：与 **`import xxx`** 一致。
3. **业务代码**：收进 **`src/<包>/` 或 `<包>/`**，避免根目录铺满散落脚本。
4. **测试**：独立 **`tests/`**，与安装包分开（极小程序可例外）。

---

## 四、Web 项目的目录骨架

### Django

```text
my_site/
├── manage.py
├── requirements.txt          # 或 pyproject.toml
├── my_site/                  # 项目配置包（小写 snake_case）
│   ├── settings/
│   ├── urls.py
│   ├── asgi.py              # ASGI 部署入口，见 django_wsgi_asgi.md
│   └── wsgi.py              # WSGI 部署入口，见 django_wsgi_asgi.md
├── apps/                     # 可选：业务应用聚合
├── static/
├── media/
├── templates/
└── tests/
```

### FastAPI（API 优先）

```text
my_api/
├── pyproject.toml
├── src/
│   └── my_api/
│       ├── main.py
│       ├── api/              # 或 routers/、routes/
│       ├── core/             # 配置、安全
│       ├── db/
│       ├── schemas/
│       ├── services/
│       └── integrations/
├── tests/
└── alembic/                  # 数据库迁移时常用该名
```

### Flask

```text
my_app/
├── wsgi.py
├── my_app/
│   ├── __init__.py           # create_app
│   ├── blueprints/
│   ├── templates/
│   └── static/
├── instance/
└── tests/
```

Web 根目录还可能包含：`.env` / `.env.example`、`docker/`、`nginx/`、`scripts/`、`migrations/` 等。

---

## 五、Django / FastAPI / Flask 区别概览

| 维度         | Django                    | Flask              | FastAPI                   |
|--------------|---------------------------|--------------------|---------------------------|
| 定位         | 大而全的网站 + 后台       | 轻量内核，自拼生态 | 现代异步 API，文档/校验强 |
| 开箱程度     | ORM、Admin、认证等多内置  | 核心薄，扩展自选   | 无内置 ORM，Pydantic 集成 |
| 典型用途     | 后台、多页站点、DRF API   | 小中项目、原型     | 前后端分离 API、微服务    |
| 同步/异步    | 同步为主，逐步增强 ASGI   | WSGI，同步思维     | ASGI/async 优先           |
| API 文档     | 常配 DRF 等               | 自接插件           | OpenAPI `/docs` 自动生成  |
| ORM          | Django ORM 深度绑定       | SQLAlchemy 常见    | SQLAlchemy 等自选         |

**如何选**

- **Django**：需要 Admin、用户体系、模板链、强约定中大型应用。
- **FastAPI**：JSON API、微服务、要重视 OpenAPI 与异步 I/O。
- **Flask**：要极小内核、教学或简单 WSGI 服务。

**注意**：性能取决于架构与数据库；FastAPI 的「快」多指 I/O 密集下 async 吞吐；Django 一样能做好 API（如 DRF）。

---

## 六、AiBasic 中与 `FirstAgent` 相关的布局说明

**文档**已集中在仓库根目录 **`knowledge_engineering/`**（含本文所在 `django/`、`agents/` 笔记、`code_graph/` 工具说明），与可运行代码分离。

**`FirstAgent/`** 采用学习型代码布局（非发布型 `src/` 包）：

- **`notebooks/`**：Jupyter 实验。
- **`scripts/`**：可命令行运行的 Python 脚本（与 notebook 示例逻辑对齐时便于对照）。
- 项目根仍放 **`requirements.txt`**、**`.gitignore`**、**`README.md`**；**`.env`** 建议放在 **`FirstAgent` 根目录**（与脚本、笔记本中的加载路径一致）。
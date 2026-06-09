# Python 操作备忘

> **适用**：Python 虚拟环境、包管理日常操作。  
> **平台**：Windows PowerShell / Cursor 终端；命令在 macOS / Linux 上通常相同。  
> **官方**：[Python venv](https://docs.python.org/zh-cn/3/library/venv.html) · [pip](https://pip.pypa.io/en/stable/) · [npm](https://docs.npmjs.com/) · [pnpm](https://pnpm.io/zh/)

---

## 一、Python 虚拟环境（venv）

### 1.1 创建虚拟环境

```bash
# 在项目根目录创建虚拟环境（名为 .venv 是惯例）
python -m venv .venv

# 也可指定名称，例如 "x"
python -m venv x
```

### 1.2 激活虚拟环境

| 平台 | 命令 |
|------|------|
| **Windows (PowerShell)** | `.venv\Scripts\Activate.ps1` |
| **Windows (Cmd)** | `.venv\Scripts\activate.bat` |
| **macOS / Linux** | `source .venv/bin/activate` |

激活后终端提示符前会出现 `(.venv)` 标识。

### 1.3 退出虚拟环境

```bash
deactivate
```

### 1.4 删除虚拟环境

直接删除目录即可：

```bash
rm -rf .venv    # macOS / Linux
rmdir /s .venv  # Windows
```

### 1.5 在 VS Code / Cursor 中选择解释器

`Ctrl+Shift+P` → `Python: Select Interpreter` → 选择 `.venv\Scripts\python.exe`

### 1.6 查看当前环境：项目级还是系统级

不确定当前用的是虚拟环境还是系统全局 Python 时，用以下命令判断：

```bash
# 查看当前 python 解释器的完整路径
where python          # Windows
which python          # macOS / Linux

# 查看当前 pip 来自哪里
pip -V                # 输出中会显示路径，如 .venv\Scripts\pip

# 精确判断是否在虚拟环境中（Python 脚本方式）
python -c "import sys; print('sys.prefix:', sys.prefix); print('sys.base_prefix:', sys.base_prefix)"
```

**判断逻辑**：

| 情况 | 说明 |
|------|------|
| `sys.prefix == sys.base_prefix` | ❌ **未激活** — 当前用的是系统级/全局解释器 |
| `sys.prefix != sys.base_prefix` | ✅ **已激活** — 当前在虚拟环境中，`sys.prefix` 指向 `.venv` 目录 |

典型输出对比：

```bash
# ✅ 已激活虚拟环境 — sys.prefix 指向虚拟环境目录
sys.prefix: C:\Users\xxx\.venv
sys.base_prefix: C:\Users\xxx\AppData\Local\Programs\Python\Python311

# ❌ 全局环境 — sys.prefix == sys.base_prefix
sys.prefix: C:\Users\xxx\AppData\Local\Programs\Python\Python311
sys.base_prefix: C:\Users\xxx\AppData\Local\Programs\Python\Python311
```

```bash
# 查看已安装包的位置
pip list -v            # 比 pip list 多一列 Location，显示每个包的实际安装路径
```

若 Location 包含 `.venv` 说明装在项目虚拟环境；若在 `Python\Python311\Lib\site-packages` 则是系统全局。

---

## 二、pip 包管理

### 2.1 安装包

#### 方式一：激活后安装（常用）

```bash
# 先激活虚拟环境（终端出现 (.venv) 前缀）
.venv\Scripts\Activate.ps1
# 再安装
pip install <package-name>           # 安装最新版
pip install <package-name>==1.2.3    # 安装指定版本
pip install -r requirements.txt      # 批量安装（读取文件）
```

#### 方式二：不激活，用绝对路径安装（保险写法）

即使未激活虚拟环境，也可以用虚拟环境里的 Python 直接调用 pip，保证装到 `.venv` 里：

```bash
# 保险写法：用虚拟环境中的 python -m pip
.venv\Scripts\python -m pip install <package-name>
.venv\Scripts\python -m pip install -r requirements.txt
```

> **推荐**：如果经常忘记激活，直接养成习惯用 `python -m pip` 形式，路径指向哪个环境就装到哪个环境，不依赖激活状态。

### 2.2 卸载包

```bash
pip uninstall <package-name>
pip uninstall -r requirements.txt -y  # 批量卸载（-y 跳过确认）
```

### 2.3 查看已安装包

```bash
pip list                    # 列出所有已安装包
pip list --outdated         # 列出可更新的包
pip show <package-name>     # 查看某个包的详细信息
```

### 2.4 导出依赖（生成 requirements.txt）

```bash
pip freeze > requirements.txt          # 全部依赖（含版本号）
pip list --format=freeze > requirements.txt  # 同上，格式一致
```

> **惯例**：`requirements.txt` 应加入版本控制（Git）；部署时用 `pip install -r requirements.txt` 还原环境。

### 2.5 升级 pip 自身

```bash
python -m pip install --upgrade pip
```

---

## 三、pip / npm / pnpm 区别

| 维度 | pip | npm | pnpm |
|------|-----|-----|------|
| **语言** | Python | Node.js / JavaScript | Node.js / JavaScript |
| **包注册源** | PyPI (Python Package Index) | npm Registry | npm Registry（同 npm） |
| **依赖文件** | `requirements.txt` / `pyproject.toml` | `package.json` | `package.json` + `pnpm-lock.yaml` |
| **锁文件** | 无（可 pip freeze 手动生成） | `package-lock.json` | `pnpm-lock.yaml` |
| **安装方式** | 扁平安装到 `site-packages/` | 嵌套 `node_modules/` | **硬链接 + 全局 store**，共享依赖 |
| **磁盘占用** | 每个环境一份 | 每个项目一份，有冗余 | **最小**（全局 store 去重） |
| **安装速度** | 中等 | 慢（重复下载） | **快**（复用 store） |
| **虚拟环境** | 需要 `venv` 隔离 | 自带项目级隔离（每个项目独立 `node_modules`） | 同 npm，项目级隔离 |
| **workspace（monorepo）** | 无原生支持（可用 `pip -e` + 手动组织） | 支持（`npm workspaces`） | **原生强支持**（`pnpm workspaces`，monorepo 首选） |
| **命令** | `pip install` | `npm install` | `pnpm add` |
| **安装包** | `pip install <pkg>` | `npm install <pkg>` | `pnpm add <pkg>` |
| **卸载包** | `pip uninstall <pkg>` | `npm uninstall <pkg>` | `pnpm remove <pkg>` |
| **更新包** | `pip install --upgrade <pkg>` | `npm update <pkg>` | `pnpm update <pkg>` |
| **运行脚本** | 无直接等价（用 `python -m`） | `npm run <script>` | `pnpm run <script>` 或 `pnpm <script>`（更快） |

### 核心差异速记

| 一句话 | 说明 |
|--------|------|
| **pip 管 Python 包，npm/pnpm 管 JS 包** | 最根本的区别，互不替代 |
| **npm 是 pnpm 的前身** | pnpm 解决了 npm 的磁盘浪费和安装慢问题 |
| **pnpm = 更快的 npm + 省磁盘 + monorepo 友好** | 新 JS 项目推荐直接用 pnpm 代替 npm |
| **Python 无锁文件机制** | pip 没有 `lock.json`，依赖确定性靠 `requirements.txt` + 手动固定版本号 |

---

## 四、快速参考对照表

| 场景 | Python (pip) | JavaScript (npm) | JavaScript (pnpm) |
|------|-------------|------------------|-------------------|
| 初始化项目 | 无（手动建 `requirements.txt`） | `npm init` | `pnpm init` |
| 安装依赖 | `pip install <pkg>` | `npm install <pkg>` | `pnpm add <pkg>` |
| 安装开发依赖 | 不区分（手动放 dev 组） | `npm install -D <pkg>` | `pnpm add -D <pkg>` |
| 安装全局工具 | `pip install --user <pkg>` 或 `pipx` | `npm install -g <pkg>` | `pnpm add -g <pkg>` |
| 安装项目全部依赖 | `pip install -r requirements.txt` | `npm install` | `pnpm install` |
| 列出已安装 | `pip list` | `npm list` | `pnpm list` |
| 运行脚本 | `python script.py` | `npm run dev` | `pnpm dev` |

---

## 参考链接

- [Python venv 官方文档](https://docs.python.org/zh-cn/3/library/venv.html)
- [pip 官方文档](https://pip.pypa.io/en/stable/)
- [npm 文档](https://docs.npmjs.com/)
- [pnpm 中文文档](https://pnpm.io/zh/)
- [PyPI](https://pypi.org/)

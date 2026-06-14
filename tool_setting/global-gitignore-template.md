# ── 全局 gitignore 模板 ──
# 用途：复制到目标机器后执行以下命令生效
#
#   Linux / macOS:
#     cp 本文件 ~/.gitignore
#     git config --global core.excludesFile ~/.gitignore
#
#   Windows (PowerShell):
#     copy 本文件 $HOME\.gitignore
#     git config --global core.excludesFile "$HOME\.gitignore"

# === 操作系统文件 ===
.DS_Store
Thumbs.db
Desktop.ini
*.swp
*.swo
*~

# === Windows 特有 ===
# （Windows 环境取消注释）
#*.lnk
#desktop.ini
#$RECYCLE.BIN/

# === IDE / 编辑器 ===
.vscode/
.idea/
*.iml
.cursor/

# === 编译 / 构建输出 ===
build/
dist/
*.o
*.obj
*.exe
*.class
*.jar
*.war

# === Python 通用 ===
__pycache__/
*.py[cod]
*.pyo
*.py.class
.pytest_cache/
.mypy_cache/
.ruff_cache/
.coverage
.coverage.*
htmlcov/

# === 依赖目录 ===
node_modules/
.venv/
venv/
env/
ENV/

# === 环境 / 密钥 ===
.env
.envrc
*.env.local
*.secret

# === 日志 ===
*.log

# === Reasonix 项目配置 ===
reasonix.toml

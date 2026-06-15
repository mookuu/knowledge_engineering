# Debian 开发环境搭建备忘

> 本机：Debian 13 (trixie) · Sony VAIO SVP1321
> 场景：VSCode SSH 远程开发

---

## Docker 网络修复（IPv6 不可用）

本机无公网 IPv6，Docker 默认会尝试 IPv6 连接镜像源导致拉取失败。

### 修复的三处配置

```bash
# 1. 系统级 IPv4 优先
echo "precedence ::ffff:0:0/96  100" | sudo tee -a /etc/gai.conf

# 2. Docker systemd override — Go 用系统 DNS 解析
sudo mkdir -p /etc/systemd/system/docker.service.d
cat << 'EOF' | sudo tee /etc/systemd/system/docker.service.d/dns-override.conf
[Service]
Environment=GODEBUG=netdns=cgo
EOF
sudo systemctl daemon-reload

# 3. Docker registry 镜像源
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "data-root": "/home/docker-data",
  "dns": ["223.5.5.5", "114.114.114.114"],
  "registry-mirrors": ["https://docker.1ms.run"]
}
EOF

# 4. 重启 Docker
sudo systemctl restart docker
```

### 验证

```bash
docker pull python:3.12-slim
# 应能正常拉取
```

---

## mind-sync 知识库引擎

### 启动

```bash
cd /home/moku/projects/mind-sync

# 确保 .env 存在
cp .env.example .env
# 编辑 .env 修改：
# - AUTH_PASSWORD, SECRET_KEY, API_KEY（安全设置）
# - SOURCE_KNOWLEDGE_ENGINEERING=/home/moku/projects/knowledge_engineering

# 构建并启动
docker compose build --no-cache
docker compose up -d
```

### 服务地址

| 服务 | 地址 | 说明 |
|---|---|---|
| API | `http://localhost:8000` | REST API + FTS5 检索 |
| Web UI | `http://localhost:8080` | 浏览器访问 |
| MCP | `python3 /home/moku/projects/mind-sync/apps/mcp/server.py` | 供 AI Agent 调用 |

### 常用操作

```bash
# 同步知识库
curl -X POST http://localhost:8000/api/sync \
  -H "Authorization: Bearer <API_KEY>"

# 搜索
curl -s "http://localhost:8000/api/search?q=关键词&limit=5" \
  -H "Authorization: Bearer <API_KEY>"

# 登录 Web UI
curl -c /tmp/cookies.txt -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"password":"<AUTH_PASSWORD>"}'

# LLM 问答
curl -X POST http://localhost:8000/api/query \
  -H "Authorization: Bearer <API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"question":"你的问题","save_to_wiki":false}'

# 停止服务
docker compose -f /home/moku/projects/mind-sync/docker-compose.yml down
```

---

## Reasonix 配置

### 全局设置

| 配置 | 位置 | 说明 |
|---|---|---|
| 系统级 config | `~/.config/reasonix/config.toml` | providers, agent, network, codegraph |
| 全局 gitignore | `~/.gitignore` | `git config --global core.excludesFile ~/.gitignore` |
| 全局 Skills | `~/.reasonix/skills/` | wiki-ingest, wiki-query, wiki-lint |
| MCP 服务器 | `~/.reasonix/config.json` | mind-sync 已注册 |

### 各项目 reasonix.toml

| 项目 | 特有配置 |
|---|---|
| `mind-sync` | `sandbox.allow_write = ["/home/moku/projects/knowledge_engineering/tool_setting"]` |
| `knowledge_engineering` | 无（全走系统级） |
| `PythonBasic` | `sandbox.allow_write = ["/home/moku/projects/"]` |

### 三个知识库 Skill

| Skill | 功能 | 调用方式 |
|---|---|---|
| `wiki-query` | 带证据问答 | `/skill wiki-query` 或在对话中让 Reasonix 调用 |
| `wiki-ingest` | 素材→摘要 | `/skill wiki-ingest` |
| `wiki-lint` | 质检 | `/skill wiki-lint` |

---

## 项目结构

```
/home/moku/projects/
├── mind-sync/             ← 知识库引擎（API + Web + MCP）
├── knowledge_engineering/  ← 知识库内容（Markdown 笔记）
├── PythonBasic/            ← Python 基础学习
├── AI/                     ← AI 项目笔记
└── nginx/                  ← nginx 配置（非 git 仓库）
```

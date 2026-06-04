# tmux 配置文件（WSL ~/.tmux.conf）

> 适用于 Reasonix / Codex 开发环境，部署在 WSL Ubuntu 中。
>
> 实际加载路径: `~/.tmux.conf`
> 备份留存路径: `C:\Workspace\10.program\90.ai\knowledge_engineering\tool_setting\tmux-conf.md`

---

## 完整配置

```ini
# ========== Reasonix tmux config ==========
set -g default-terminal "screen-256color"
set -g history-limit 50000

# 前缀键改为 Ctrl+q
set -g prefix C-q
unbind C-b
bind C-q send-prefix

# 分屏
bind | split-window -h
bind - split-window -v

# 窗口 / pane 切换
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind n next-window
bind p previous-window

# 重载配置
bind r source-file ~/.tmux.conf \; display "Reloaded!"

# 鼠标支持
set -g mouse on

# 状态栏
set -g status-style bg=black,fg=white
set -g status-left "#[fg=green]Reasonix #[fg=white]| "
set -g status-right "#[fg=yellow]%H:%M "
set -g window-status-current-style fg=cyan,bold
set -g pane-border-style fg=cyan
set -g pane-active-border-style fg=green
```

---

## 配置说明

| 配置项 | 含义 |
|--------|------|
| `prefix C-q` | 前缀键从默认的 `Ctrl+B` 改为 `Ctrl+Q`，避免与许多编辑器快捷键冲突 |
| `\|` 水平分屏 | `prefix + \|`  左右分屏 |
| `-` 垂直分屏 | `prefix + -`  上下分屏 |
| `h/j/k/l` 导航 | Vim 风格：左/下/上/右切换面板 |
| `n/p` 切换窗口 | `prefix + n` 下一个窗口，`prefix + p` 上一个窗口 |
| `r` 重载配置 | `prefix + r` 热加载配置，无需重启 tmux |
| `mouse on` | 鼠标支持：点击切换面板/窗口、滚动缓冲区 |
| `history-limit 50000` | 每个 pane 保留 50000 行回滚历史 |
| 状态栏 | 左：会话名「Reasonix」，右：当前时间 |
| 窗格边框 | 当前活跃窗格绿色高亮，其他窗格青色 |

---

## 速查卡

```text
prefix = Ctrl+Q

分屏
  prefix + |   左右分屏
  prefix + -   上下分屏

导航
  prefix + h   左 pane
  prefix + j   下 pane
  prefix + k   上 pane
  prefix + l   右 pane
  prefix + n   下一个窗口
  prefix + p   上一个窗口

其他
  prefix + r   重载配置
  prefix + [   进入滚动模式（翻看历史）
```

---

## 部署方法

```bash
# 将此文件的内容保存为 ~/.tmux.conf
# 如果 WSL 中已有配置，先确认是否需要合并

# 热加载（无需重启 tmux）
tmux source-file ~/.tmux.conf

# 或在 tmux 内按 prefix + r
```

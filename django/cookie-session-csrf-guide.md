# Django 中 Cookie / Session / CSRF 说明

**文档结构**：§1 三者区别 → §2 CSRF 中间件与 `csrftoken` / 表单 token → §3 排错 → §5 SPA → §6 最小 API 示例 → §7 DRF+JWT → §8 `django_learn_demo` 笔记应用串联（`reverse` / `redirect` / ModelForm / 删除流程）。

## 1) Cookie、Session、CSRF 的区别（含生成方、生成方式、应用方式）

### 1.1 一张总览表


| 项目          | Cookie                      | Session                                 | CSRF                                      |
| ----------- | --------------------------- | --------------------------------------- | ----------------------------------------- |
| 本质          | 浏览器保存的小型键值数据                | 服务端保存的会话状态                              | 跨站请求伪造防护机制                                |
| 主要目的        | 让客户端携带少量状态                  | 让服务端识别“同一用户会话”                          | 防止第三方站点伪造用户请求                             |
| 数据存放位置      | 浏览器（客户端）                    | 服务端（DB/缓存/文件等）                          | Token 通常在 Cookie + 表单隐藏字段/请求头             |
| 由谁生成        | 通常由服务端通过响应头 `Set-Cookie` 下发 | 通常由 Django 在首次写入 `request.session` 时创建  | Django `CsrfViewMiddleware` 生成与校验         |
| 浏览器是否自动带上   | 是（满足域、路径、SameSite 等规则）      | 实际带上的是 `sessionid` Cookie               | Cookie 会自动带，表单 token 需模板渲染或前端手动带          |
| 是否直接等于“登录态” | 不一定                         | 常用于承载登录态                                | 不是登录态，是“请求来源合法性”校验                        |
| 安全关注点       | 泄露、篡改、跨站发送                  | 会话固定、会话劫持、过期策略                          | token 缺失/错误、Referer/Origin 不通过            |
| Django 相关组件 | `HttpResponse.set_cookie()` | `SessionMiddleware` + `request.session` | `CsrfViewMiddleware` + `{% csrf_token %}` |


### 1.2 生成方式与执行主体（细分）


| 对象         | 生成触发时机                                           | 生成动作由谁做              | 典型内容                              | 生命周期                              |
| ---------- | ------------------------------------------------ | -------------------- | --------------------------------- | --------------------------------- |
| Cookie     | 响应阶段需要下发 Cookie 时                                | Django 视图或中间件设置响应头   | 例如 `sessionid`、`csrftoken`、业务标记字段 | 由 `max_age` / `expires` / 浏览器会话决定 |
| Session    | 首次写入 `request.session`（或登录流程）                    | Django Session 框架    | 服务端会话数据 + 一个会话 ID                 | 由服务端过期策略控制                        |
| CSRF Token | 访问需防护页面、调用 `get_token()`、模板渲染 `{% csrf_token %}` | `CsrfViewMiddleware` | Cookie 存 secret；表单/请求头存 masked token（详见 §2.5–§2.7） | 跟随 CSRF Cookie 生命周期，必要时轮换         |


### 1.3 典型应用场景


| 场景              | Cookie              | Session     | CSRF                      |
| --------------- | ------------------- | ----------- | ------------------------- |
| 记住用户偏好（语言、主题）   | 常用                  | 可选          | 不涉及                       |
| 登录后识别用户         | 携带 `sessionid`      | 核心（服务端映射用户） | 与登录无直接关系，但登录请求本身需 CSRF 防护 |
| 提交表单（POST）      | 浏览器自动带 Cookie       | 后端据此找到会话    | 必须校验 token（默认中间件）         |
| 前后端分离 AJAX POST | 自动带 Cookie（同站策略满足时） | 同上          | 前端需在请求头带 `X-CSRFToken`    |


### 1.4 常见误区


| 误区                             | 正确认知                                                   |
| ------------------------------ | ------------------------------------------------------ |
| “Session 不在浏览器里，所以和 Cookie 无关” | Session 数据在服务端，但浏览器通常要用 Cookie（`sessionid`）来告诉服务端“我是谁” |
| “有登录就不需要 CSRF”                 | 登录态反而更需要 CSRF，防止用户在已登录状态被第三方站点诱导发请求                    |
| “CSRF 只是前端问题”                  | CSRF 的核心校验在服务端中间件，前端只负责正确携带 token                      |


---

## 2) 结合 Django 页面 `{% csrf_token %}` 解释中间件与执行链路

### 2.1 `{% csrf_token %}` 在模板中的作用


| 模板写法               | 渲染结果              | 作用                    |
| ------------------ | ----------------- | --------------------- |
| `{% csrf_token %}` | 输出一个隐藏字段（含 token） | 让表单提交时把 token 一起发回服务端 |


示意（渲染后）：

```html
<input type="hidden" name="csrfmiddlewaretoken" value="...token...">
```

### 2.2 中间件链路（请求 -> 响应）

> 以默认启用 `CsrfViewMiddleware` 为前提，且请求为 Django 常规视图流程。


| 阶段      | 关键组件                                  | 发生的事                                      | 结果                   |
| ------- | ------------------------------------- | ----------------------------------------- | -------------------- |
| 1. 请求进入 | `SessionMiddleware`（如启用）              | 读取请求 Cookie（如 `sessionid`）并加载会话           | `request.session` 可用 |
| 2. 请求继续 | `CsrfViewMiddleware.process_view`     | 对“需校验方法”（POST/PUT/PATCH/DELETE）执行 CSRF 校验 | 通过则继续，不通过返回 403      |
| 3. 视图执行 | View 函数/类视图                           | 处理业务逻辑、渲染模板                               | 准备响应对象               |
| 4. 模板渲染 | `{% csrf_token %}` / `get_token()`    | 确保 token 可用并写入表单隐藏字段                      | 表单具备合法 token         |
| 5. 响应返回 | `CsrfViewMiddleware.process_response` | 必要时在响应头中设置/更新 `csrftoken` Cookie          | 浏览器保存 CSRF Cookie    |


### 2.3 提交表单时的校验链路（POST 视角）


| 步骤  | 浏览器发送内容                                             | 中间件校验点                           | 判定结果              |
| --- | --------------------------------------------------- | -------------------------------- | ----------------- |
| 1   | 自动携带 `csrftoken` Cookie                             | 读取 Cookie token                  | 取到基准 token        |
| 2   | 提交表单字段 `csrfmiddlewaretoken`（来自 `{% csrf_token %}`） | 对比表单 token 与 Cookie token（含安全处理） | 一致则继续             |
| 3   | （HTTPS 下）可能还会检查 `Origin/Referer`                    | 来源是否可信                           | 不可信则拒绝            |
| 4   | 全部通过                                                | 放行到视图                            | 正常执行业务            |
| 5   | 任一步失败                                               | 中断                               | 返回 403（CSRF 校验失败） |


### 2.4 为什么“模板 token + Cookie token”是两份


| 元素                                              | 在哪里        | 作用                |
| ----------------------------------------------- | ---------- | ----------------- |
| `csrftoken` Cookie                              | 浏览器 Cookie | 由站点下发，浏览器自动回传     |
| `csrfmiddlewaretoken` 表单字段（或 `X-CSRFToken` 请求头） | 请求体或请求头    | 证明“这个请求由站点页面主动发起” |


核心思想：攻击者通常能诱导浏览器带上 Cookie，但很难拿到并正确提交你站点页面中的 token 值，因此可阻断跨站伪造请求。

### 2.5 `csrftoken` Cookie：谁在什么时候生成


| 问题 | 答案 |
| ---- | ---- |
| **谁生成** | **不是浏览器**。由 Django 服务端在 HTTP 响应里通过 `Set-Cookie` 下发；具体是 `django.middleware.csrf.CsrfViewMiddleware` 在 `process_response`（及内部的 `_set_csrf_cookie` / `_maybe_set_csrf_cookie`）中写入。随机 secret 在 `django.middleware.csrf` 模块内生成（如 `_get_new_csrf_string()`），业务代码不手写该值。 |
| **什么时候写到浏览器** | 在 **「本次请求处理完、响应返回浏览器之前」** 的响应阶段，**不是**一打开站点就自动生成。 |
| **典型会下发 Cookie 的时机** | ① 模板渲染了 `{% csrf_token %}`（内部调用 `get_token(request)`）；② 代码里调用了 `get_token(request)`；③ 本次请求 CSRF secret 被新建或轮换，需在响应中更新 Cookie。 |
| **不一定每次 GET 都有** | 页面没有 `{% csrf_token %}`、也没调用 `get_token()`，或视图 `@csrf_exempt` 且未触发 token 逻辑时，可能尚未出现 `csrftoken`，直到访问了带 CSRF 的页面。 |
| **默认 Cookie 名** | `CSRF_COOKIE_NAME`，默认 `'csrftoken'` |
| **默认存放方式** | `CSRF_USE_SESSIONS = False` 时 secret 在 **Cookie** 中，不在 session 里 |

`django_learn_demo` 中：打开 **新建页**（`note_form.html` 含 `{% csrf_token %}`）或 **列表页**（删除表单含 `{% csrf_token %}`）后，该次 GET 的响应通常会带上或更新 `csrftoken`。

中间件在请求链中的位置（`learn_site/settings.py` 默认顺序）：

```
请求进入 → SessionMiddleware（sessionid，与 csrftoken 无关）→ … → 视图/模板（可能 get_token）
         → CsrfViewMiddleware.process_response  ← Set-Cookie: csrftoken
响应回到浏览器
```

> `process_view` 主要负责 **校验**（对 POST 等）；**写 Cookie** 在 **响应阶段**。

### 2.6 表单里的 CSRF 令牌：谁在什么时候生成


| 对象 | 谁生成 | 什么时候 | 存在哪里 |
| ---- | ------ | -------- | -------- |
| Cookie `csrftoken` | `CsrfViewMiddleware` 响应阶段 | 见 §2.5 | 浏览器 Cookie，后续请求自动回传 |
| 隐藏字段 `csrfmiddlewaretoken`（或请求头 `X-CSRFToken`） | 模板 `{% csrf_token %}` 或 `get_token(request)` | **渲染 HTML 时**（如 GET 列表/新建页） | 当前页面的表单或 JS 请求头 |

两者关系：

- Cookie 里存的是 CSRF **secret**（长期由浏览器带回）。
- 表单/请求头里的是基于该 secret 算出的 **masked token**（用于本次提交）。
- POST 时中间件比对「POST 字段或 `X-CSRFToken`」与「Cookie 中的 secret」；不一致 → **403**，视图不执行。

### 2.7 中间件校验（`process_view`）补充


| 步骤 | 组件 | 行为 |
| ---- | ---- | ---- |
| 请求进入 | `process_request` | 从 Cookie 读取 CSRF secret，挂到 `request` 上供后续使用 |
| 进视图前 | `process_view` | 若视图 `@csrf_exempt` → 跳过；对 POST/PUT/PATCH/DELETE 等「不安全」方法：从 `csrfmiddlewaretoken` 或 `X-CSRFToken` / `X-CSRF-Token` 取 token，与 Cookie secret 按 mask/unmask 规则比对（恒定时间比较）；失败 → 403 |
| Referer / Origin | 同上 | HTTPS 等场景下可能额外校验来源 |
| GET / HEAD | — | 一般不要求表单 token（但也不应用 GET 做删除等写操作） |

---

## 3) 实战使用建议（Django）

### 3.1 配置与代码建议


| 项目           | 建议                                                                   |
| ------------ | -------------------------------------------------------------------- |
| 中间件顺序        | 保持 Django 默认中间件顺序，确保 `CsrfViewMiddleware` 正常工作                       |
| 表单页面         | 所有会修改数据的表单都加 `{% csrf_token %}`                                      |
| AJAX / Fetch | 在请求头传 `X-CSRFToken`（从 Cookie 读取）                                     |
| Cookie 安全    | 生产环境开启 `CSRF_COOKIE_SECURE=True`、`SESSION_COOKIE_SECURE=True`（HTTPS） |
| 会话安全         | 结合 `SESSION_COOKIE_HTTPONLY`、合理过期时间、登录后轮换会话                          |


### 3.2 快速排错表（403 CSRF）


| 现象            | 常见原因                   | 处理方式                                         |
| ------------- | ---------------------- | -------------------------------------------- |
| 提交表单 403      | 忘记写 `{% csrf_token %}` | 在 form 内补上模板标签                               |
| AJAX POST 403 | 没带 `X-CSRFToken`       | 前端从 Cookie 读 token 并加请求头                     |
| 仅线上报错         | HTTPS / 域名 / 代理头配置不一致  | 检查 `CSRF_TRUSTED_ORIGINS`、反向代理配置、SameSite 策略 |
| 间歇性失败         | 页面缓存了旧 token 或会话变化     | 刷新页面重取 token，避免缓存动态表单                        |


---

## 4) 一句话总结


| 术语      | 一句话理解                                                    |
| ------- | -------------------------------------------------------- |
| Cookie  | 浏览器保存并自动回传的小数据载体                                         |
| Session | 服务端保存的会话状态，通常靠 Cookie 里的会话 ID 关联                         |
| CSRF    | 利用“Cookie 会自动带上”的机制进行伪造请求的防护方案，Django 通过中间件 + token 校验实现 |


---

## 5) 前后端分离（Vue/React + Django API）CSRF 实战补充

### 5.1 与模板渲染模式的差异


| 维度                 | Django 模板表单模式               | 前后端分离 SPA 模式                   |
| ------------------ | --------------------------- | ------------------------------ |
| token 注入方式         | `{% csrf_token %}` 自动输出隐藏字段 | 前端 JS 从 Cookie 读取 token 后写入请求头 |
| token 提交位置         | 表单字段 `csrfmiddlewaretoken`  | 请求头 `X-CSRFToken`              |
| 请求工具               | 浏览器原生 form submit           | `fetch` / `axios`              |
| 是否需要 `credentials` | 通常不显式配置                     | 需要（跨域场景至少 `include`）           |
| 常见报错点              | 漏写模板标签                      | 漏传请求头 / 漏带 Cookie / CORS 配置不完整 |


### 5.2 推荐流程（SPA）


| 步骤  | 前端动作                                           | 后端/Django 预期                                     |
| --- | ---------------------------------------------- | ------------------------------------------------ |
| 1   | 先访问一次后端页面或初始化接口                                | 响应中下发 `csrftoken` Cookie                         |
| 2   | JS 从 `document.cookie` 读取 `csrftoken`          | token 可被前端读取（`CSRF_COOKIE_HTTPONLY=False`，默认即如此） |
| 3   | 发起写操作请求（POST/PUT/PATCH/DELETE）时带 `X-CSRFToken` | `CsrfViewMiddleware` 校验通过                        |
| 4   | 请求需带上 Cookie                                   | 后端能同时拿到 Cookie token 与请求头 token                  |
| 5   | 通过后执行业务逻辑                                      | 返回业务响应                                           |


### 5.3 `fetch` 示例（推荐）

```js
function getCookie(name) {
  const match = document.cookie.match(new RegExp("(^|; )" + name + "=([^;]*)"));
  return match ? decodeURIComponent(match[2]) : null;
}

const csrftoken = getCookie("csrftoken");

await fetch("https://api.example.com/orders/", {
  method: "POST",
  credentials: "include", // 让浏览器带上 cookie（含 sessionid、csrftoken）
  headers: {
    "Content-Type": "application/json",
    "X-CSRFToken": csrftoken
  },
  body: JSON.stringify({ sku: "A100", qty: 1 })
});
```

### 5.4 `axios` 示例（推荐）

```js
import axios from "axios";

const api = axios.create({
  baseURL: "https://api.example.com",
  withCredentials: true // 关键：跨域时也带 cookie
});

api.interceptors.request.use((config) => {
  const match = document.cookie.match(/(?:^|;\s*)csrftoken=([^;]+)/);
  const csrftoken = match ? decodeURIComponent(match[1]) : "";
  config.headers["X-CSRFToken"] = csrftoken;
  return config;
});

await api.post("/orders/", { sku: "A100", qty: 1 });
```

### 5.5 Django 侧关键配置（跨域 API 常见）


| 配置项                      | 作用                                  | 常见建议                                     |
| ------------------------ | ----------------------------------- | ---------------------------------------- |
| `CSRF_TRUSTED_ORIGINS`   | 允许哪些来源通过 CSRF 来源检查                  | 填前端站点域名（含协议），如 `https://app.example.com` |
| `CORS_ALLOWED_ORIGINS`   | 允许跨域访问的来源（配合 `django-cors-headers`） | 精确列白名单，不用 `*`                            |
| `CORS_ALLOW_CREDENTIALS` | 是否允许浏览器携带凭据（Cookie）                 | 前后端分离且要会话认证时设为 `True`                    |
| `CSRF_COOKIE_SECURE`     | CSRF Cookie 仅 HTTPS 传输              | 生产环境设为 `True`                            |
| `SESSION_COOKIE_SECURE`  | Session Cookie 仅 HTTPS 传输           | 生产环境设为 `True`                            |
| `CSRF_COOKIE_SAMESITE`   | 控制 CSRF Cookie 跨站发送策略               | 按部署拓扑选择，跨站嵌套场景需谨慎评估                      |


### 5.6 SPA 场景常见错误对照


| 现象                | 根因                                            | 修复要点                                                                 |
| ----------------- | --------------------------------------------- | -------------------------------------------------------------------- |
| POST 一直 403（CSRF） | 未发送 `X-CSRFToken`                             | 前端在每个写请求统一注入 token                                                   |
| 请求头带了 token 仍 403 | 未带 Cookie（`credentials`/`withCredentials` 缺失） | `fetch` 用 `credentials: "include"`，`axios` 用 `withCredentials: true` |
| 仅跨域时失败            | `CSRF_TRUSTED_ORIGINS` 或 CORS 配置缺失            | 同时检查 CSRF 与 CORS 的白名单配置                                              |
| 线上 HTTPS 才失败      | `Secure` / 代理转发头不一致                           | 检查 HTTPS 终止层与 Django 获取协议方式                                          |
| 偶发失败              | token 过期或页面持有旧 token                          | 失败后刷新 token，避免缓存老页面长期驻留                                              |


---

## 6) 最小可运行示例（Django API + 前端请求）

> 目标：用最少代码验证“先拿到 `csrftoken`，再带 `X-CSRFToken` 发 POST”这条链路。

### 6.1 示例结构


| 文件                   | 作用                           |
| -------------------- | ---------------------------- |
| `demo/settings.py`   | 配置中间件、跨域和 CSRF 白名单           |
| `demo/urls.py`       | 路由入口                         |
| `api/views.py`       | 提供初始化 token 的 GET 和受保护的 POST |
| `frontend-demo.html` | 用浏览器 `fetch` 发请求验证           |


### 6.2 Django 后端代码

#### `api/views.py`

```python
from django.http import JsonResponse
from django.views.decorators.http import require_GET, require_POST
from django.views.decorators.csrf import ensure_csrf_cookie
import json


@require_GET
@ensure_csrf_cookie
def csrf_init(request):
    # 访问该接口后，响应会带上 csrftoken cookie
    return JsonResponse({"message": "csrf cookie set"})


@require_POST
def create_order(request):
    data = json.loads(request.body or "{}")
    return JsonResponse({
        "ok": True,
        "received": data
    })
```

#### `demo/urls.py`

```python
from django.contrib import admin
from django.urls import path
from api.views import csrf_init, create_order

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/csrf-init/", csrf_init),
    path("api/orders/", create_order),
]
```

#### `demo/settings.py`（关键项示意）

```python
INSTALLED_APPS = [
    # ...
    "corsheaders",
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ALLOWED_HOSTS = ["127.0.0.1", "localhost"]

CORS_ALLOWED_ORIGINS = [
    "http://127.0.0.1:5500",
    "http://localhost:5500",
]
CORS_ALLOW_CREDENTIALS = True

CSRF_TRUSTED_ORIGINS = [
    "http://127.0.0.1:5500",
    "http://localhost:5500",
]

CSRF_COOKIE_SECURE = False      # 本地 http 调试
SESSION_COOKIE_SECURE = False   # 本地 http 调试
```

### 6.3 前端验证页面（`frontend-demo.html`）

```html
<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <title>CSRF Demo</title>
  </head>
  <body>
    <button id="run">Run CSRF Test</button>
    <pre id="out"></pre>

    <script>
      function getCookie(name) {
        const match = document.cookie.match(new RegExp("(^|; )" + name + "=([^;]*)"));
        return match ? decodeURIComponent(match[2]) : null;
      }

      document.getElementById("run").onclick = async () => {
        const out = document.getElementById("out");
        out.textContent = "Step1: init csrf...\n";

        await fetch("http://127.0.0.1:8000/api/csrf-init/", {
          method: "GET",
          credentials: "include"
        });

        const csrftoken = getCookie("csrftoken");
        out.textContent += "Step2: got csrftoken = " + csrftoken + "\n";

        const resp = await fetch("http://127.0.0.1:8000/api/orders/", {
          method: "POST",
          credentials: "include",
          headers: {
            "Content-Type": "application/json",
            "X-CSRFToken": csrftoken
          },
          body: JSON.stringify({ sku: "A100", qty: 1 })
        });

        const data = await resp.json();
        out.textContent += "Step3: POST result = " + JSON.stringify(data, null, 2);
      };
    </script>
  </body>
</html>
```

### 6.4 运行步骤


| 步骤  | 命令 / 动作                                                          | 预期结果                               |
| --- | ---------------------------------------------------------------- | ---------------------------------- |
| 1   | 安装依赖：`pip install django django-cors-headers`                    | 依赖安装完成                             |
| 2   | 启动 Django：`python manage.py runserver`                           | 后端监听 `127.0.0.1:8000`              |
| 3   | 用 Live Server 或任意静态服务打开 `frontend-demo.html`（如 `127.0.0.1:5500`） | 前端页面可访问                            |
| 4   | 点击按钮执行测试                                                         | 先成功获取 `csrftoken`，再 POST 成功返回 JSON |


### 6.5 对照实验（帮助理解）


| 操作                                | 预期现象           | 说明             |
| --------------------------------- | -------------- | -------------- |
| 去掉 `X-CSRFToken` 请求头              | POST 403       | 证明仅有 Cookie 不够 |
| 保留请求头但去掉 `credentials: "include"` | POST 403 或认证异常 | 证明 Cookie 未带上  |
| 删除 `CSRF_TRUSTED_ORIGINS`（跨域场景）   | 403（来源校验失败）    | 证明来源检查生效       |


### 6.6 工程化落地记录（AiBasic）

> 已在 `D:\kan\kan\Python\AiBasic\django_learn_demo` 工程化实现，本文档内容保留用于学习说明。


| 落地项    | 文件路径                                               | 说明                                                 |
| ------ | -------------------------------------------------- | -------------------------------------------------- |
| 示例应用注册 | `learn_site/settings.py`                           | 新增 `csrf_demo.apps.CsrfDemoConfig`                 |
| 路由挂载   | `learn_site/urls.py`                               | 新增 `path("csrf-demo/", include("csrf_demo.urls"))` |
| 视图实现   | `csrf_demo/views.py`                               | `demo_page`、`csrf_init`、`create_order`             |
| 应用路由   | `csrf_demo/urls.py`                                | `/`、`api/csrf-init/`、`api/orders/`                 |
| 前端演示页  | `csrf_demo/templates/csrf_demo/frontend_demo.html` | 一键执行 CSRF 初始化+POST 测试                              |
| 工程说明   | `README.md`                                        | 补充 CSRF 演示入口与接口说明                                  |


快速访问：

- 演示页：`http://127.0.0.1:8000/csrf-demo/`
- 初始化接口：`GET /csrf-demo/api/csrf-init/`
- 写接口：`POST /csrf-demo/api/orders/`

---

## 7) Django REST Framework + JWT 场景：CSRF 是否需要、何时需要

### 7.1 核心判断原则


| 判断维度             | 结论                                                |
| ---------------- | ------------------------------------------------- |
| 凭据是否会被浏览器“自动带上”  | 会自动带上（如 Cookie）则要重点考虑 CSRF                        |
| 凭据是否由 JS 主动放到请求头 | 主动放（如 `Authorization: Bearer ...`）通常不受 CSRF 典型攻击面 |
| 是否是“浏览器上下文”请求    | 非浏览器客户端（脚本、移动端直连）通常不涉及 CSRF 典型模型                  |


### 7.2 DRF + JWT 常见方案对照


| 认证方案                                       | token 存放位置                         | 浏览器是否自动携带             | CSRF 是否需要            | 说明                              |
| ------------------------------------------ | ---------------------------------- | --------------------- | -------------------- | ------------------------------- |
| JWT 放 `Authorization` 请求头                  | 内存 / localStorage / sessionStorage | 否（需前端手动加）             | 通常不需要（针对该认证链路）       | 主风险转为 XSS、token 泄露              |
| JWT 放 HttpOnly Cookie（访问接口靠 Cookie）        | Cookie                             | 是                     | 需要                   | 与 Session Cookie 类似，存在 CSRF 攻击面 |
| Access Token 在请求头 + Refresh Token 在 Cookie | 混合                                 | Refresh 请求会自动带 Cookie | Refresh 端点需要 CSRF 防护 | 常见于“短 access + 长 refresh”方案     |
| 纯后端到后端调用（无浏览器）                             | 进程内或配置中心                           | 不适用                   | 通常不需要                | 不属于浏览器跨站伪造模型                    |


### 7.3 何时“必须上 CSRF”


| 场景                                   | 是否必须           | 原因                        |
| ------------------------------------ | -------------- | ------------------------- |
| 浏览器请求 + 认证凭据在 Cookie 中               | 是              | 攻击站点可诱导浏览器自动带 Cookie 发请求  |
| 浏览器请求 + 写操作接口（POST/PUT/PATCH/DELETE） | 是（若凭据在 Cookie） | 风险主要在状态修改类请求              |
| 仅 `Authorization` 头携带 JWT 且不读 Cookie | 通常否            | 第三方站点无法替你构造带私有 token 的请求头 |


### 7.4 DRF 实战建议（表格）


| 目标                              | 建议                                         |
| ------------------------------- | ------------------------------------------ |
| 想降低 CSRF 复杂度                    | 优先使用 `Authorization Bearer`，不把访问凭据放 Cookie |
| 想提升 token 防窃取能力                 | 可用 HttpOnly Cookie，但必须补齐 CSRF 防护链路         |
| 混合方案（Access 头 + Refresh Cookie） | 对 refresh 接口做 CSRF 校验，其余接口按认证方式分别处理        |
| 统一安全策略                          | 同时关注 CSRF 与 XSS，二者不能互相替代                   |


### 7.5 常见误解


| 误解                    | 更准确的说法                                |
| --------------------- | ------------------------------------- |
| “用了 JWT 就不需要 CSRF”    | 只要 JWT 在 Cookie 并自动携带，依然需要 CSRF       |
| “做了 CSRF 就不怕 XSS”     | CSRF 防跨站伪造，XSS 防脚本注入，二者是不同维度          |
| “JWT 一定比 Session 更安全” | 安全性取决于存储位置、传输方式、过期与轮换策略，不是 token 类型本身 |


### 7.6 工程化落地记录（AiBasic）

> 已在 `D:\kan\kan\Python\AiBasic\django_learn_demo` 增加 `drf_jwt_demo` 示例工程。


| 落地项            | 文件路径                                            | 说明                                                       |
| -------------- | ----------------------------------------------- | -------------------------------------------------------- |
| 依赖             | `requirements.txt`                              | 新增 `djangorestframework`、`djangorestframework-simplejwt` |
| 应用注册           | `learn_site/settings.py`                        | 新增 `rest_framework`、`drf_jwt_demo`                       |
| 路由挂载           | `learn_site/urls.py`                            | 新增 `path("drf-jwt-demo/", include("drf_jwt_demo.urls"))` |
| Cookie JWT 认证类 | `drf_jwt_demo/authentication.py`                | 从 `access_token` Cookie 读取 JWT                           |
| CSRF 手动校验      | `drf_jwt_demo/csrf.py`                          | 在 DRF 写接口中显式触发 CSRF 校验                                   |
| 对照接口实现         | `drf_jwt_demo/views.py`                         | Header JWT 与 Cookie JWT 两套 API                           |
| API 路由         | `drf_jwt_demo/urls.py`                          | 登录、受保护 GET、写接口、登出                                        |
| 前端演示页          | `drf_jwt_demo/templates/drf_jwt_demo/demo.html` | 一页对照“需要/不需要 CSRF”的行为差异                                   |
| 工程说明           | `django_learn_demo/README.md`                   | 补充入口和接口清单                                                |


演示入口：

- 页面：`http://127.0.0.1:8000/drf-jwt-demo/`
- Header 登录：`POST /drf-jwt-demo/api/auth/login-header/`
- Header 受保护 GET：`GET /drf-jwt-demo/api/header/profile/`
- Cookie 登录：`POST /drf-jwt-demo/api/auth/login-cookie/`
- Cookie 受保护 GET：`GET /drf-jwt-demo/api/cookie/profile/`
- Cookie 写接口（需 CSRF）：`POST /drf-jwt-demo/api/cookie/update/`

### 7.7 最小验证步骤（本地）


| 步骤  | 命令 / 动作                                          | 预期结果                                                              |
| --- | ------------------------------------------------ | ----------------------------------------------------------------- |
| 1   | `cd D:\kan\kan\Python\AiBasic\django_learn_demo` | 进入工程目录                                                            |
| 2   | `python -m pip install -r requirements.txt`      | 安装 DRF 与 SimpleJWT 依赖                                             |
| 3   | `python manage.py runserver`                     | Django 服务启动                                                       |
| 4   | 打开 `http://127.0.0.1:8000/drf-jwt-demo/`         | 可见对照演示页面                                                          |
| 5   | 按页面按钮依次测试                                        | Header JWT 可直接访问受保护 GET；Cookie JWT 的 POST 在不带 CSRF 时失败、带 CSRF 时成功 |


---

## 8) `django_learn_demo` 笔记应用（`notes`）串联说明

> 以下示例均来自 `D:\kan\kan\Python\AiBasic\django_learn_demo\notes\`，用于把 Cookie / CSRF / 表单 / 重定向串成一条可读链路。

### 8.1 路由命名与 `reverse`


`notes/urls.py`：

```python
app_name = "notes"

urlpatterns = [
    path("", views.note_list, name="list"),
    path("new/", views.note_create, name="create"),
    path("<int:pk>/delete/", views.note_delete, name="delete"),
]
```

| 概念 | 说明 |
| ---- | ---- |
| `name="list"` | 路由名，用于反向解析 |
| `app_name = "notes"` | 应用命名空间，完整名为 `notes:list` |
| `reverse("notes:list")` | **名字 → URL 字符串**（Python 里用，如 `redirect`） |
| `{% url 'notes:list' %}` | 模板里同名机制 |
| `reverse("notes:delete", kwargs={"pk": 3})` | 带参数 → 如 `/notes/3/delete/`（前缀取决于根 `urls.py` 的 `include`） |

**为何不用硬编码路径**：改 `include` 前缀或 `path` 时，只需改 `urls.py`，视图和模板仍用名字解析。

```python
# 推荐
redirect(reverse("notes:list"))
# Django 4+ 简写（效果相同）
redirect("notes:list")
```

### 8.2 `redirect(...)` 与 HTTP 302


视图在写操作成功后常见写法：

```python
return redirect(reverse("notes:list"))
```

| 概念 | 说明 |
| ---- | ---- |
| **302** | HTTP 状态码：**临时重定向**。响应头带 `Location: /notes/...`，告诉浏览器「请再去访问这个地址」。 |
| 浏览器行为 | 收到 302 后 **自动再发一次 GET** 到 `Location`，用户最终看到的是列表页（通常 200）。 |
| **Post/Redirect/Get** | POST 改数据 → 302 → GET 展示结果；避免刷新时重复 POST（如重复删除）。 |

以删除为例：

1. 列表页点「删除」→ 浏览器 **POST** `/notes/3/delete/`
2. 服务器 `note.delete()`，返回 **302**，`Location` 指向列表
3. 浏览器 **GET** 列表页 → 地址栏停在 `/notes/`，已删记录不再出现

| 状态码 | 常见含义（了解即可） |
| ------ | -------------------- |
| 200 | 成功，响应体即页面内容 |
| 301 | 永久重定向 |
| 302 | 临时重定向（`redirect()` 默认常用） |
| 303 | 见其他 URL，语义上更强调用 GET 取结果 |
| 307 / 308 | 重定向时保持原请求方法（POST 仍 POST） |

### 8.3 `NoteForm`（ModelForm）


`notes/forms.py`：

```python
class NoteForm(forms.ModelForm):
    class Meta:
        model = Note
        fields = ["title", "content"]
```

| 模型字段 | 是否在表单 | 说明 |
| -------- | ---------- | ---- |
| `title` | ✅ | 必填，`max_length=100` |
| `content` | ✅ | 可选（`blank=True`） |
| `created_at` | ❌ | 由 `auto_now_add=True` 在 `save()` 时自动写入 |

`ModelForm` 负责：生成 HTML 控件、校验、`form.save()` 落库。与手写 `forms.Form` + `Note.objects.create(...)` 相比，字段定义与模型保持同步。

### 8.4 新建页模板 `note_form.html`


```django
{% extends "notes/base.html" %}
{% block title %}新建笔记{% endblock %}
{% block content %}
  <form method="post">
    {% csrf_token %}
    {{ form.as_p }}
    <button type="submit">保存</button>
    <a href="{% url 'notes:list' %}">取消</a>
  </form>
{% endblock %}
```

| 部分 | 作用 |
| ---- | ---- |
| 未写 `action` | 提交到 **当前 URL**（`notes:create`，即 `/notes/new/`） |
| `method="post"` | 走 `note_create` 的 POST 分支 |
| `{% csrf_token %}` | 输出隐藏字段；同时触发 §2.5 的 `csrftoken` Cookie 下发 |
| `{{ form.as_p }}` | 将 `title`、`content` 各包在一个 `<p>` 里渲染；校验失败时同页显示错误 |
| 「保存」 | `type="submit"` → POST → `form.save()` → 302 列表 |
| 「取消」 | 普通链接，**GET** 列表，不提交、不写库 |

`note_create` 与模板的对应：

| 请求 | 视图 | 模板 |
| ---- | ---- | ---- |
| GET `/notes/new/` | `NoteForm()` | 空表单 |
| POST 校验失败 | `NoteForm(request.POST)` | 带错误的 `form` |
| POST 校验成功 | `redirect` 列表 | **不渲染** 本模板 |

### 8.5 删除：`note_delete` 与列表页表单


`notes/views.py`：

```python
@require_http_methods(["POST"])
def note_delete(request, pk: int):
    note = get_object_or_404(Note, pk=pk)
    note.delete()
    return redirect(reverse("notes:list"))
```

| 部分 | 含义 |
| ---- | ---- |
| `@require_http_methods(["POST"])` | 仅允许 POST；GET 访问删除 URL → **405**，避免「点链接就删」 |
| `pk` | 来自 `path("<int:pk>/delete/", ...)` |
| `get_object_or_404` | 无此 id → 404 |
| `redirect(...)` | 删完后 302 回列表（§8.2） |

`note_list.html` 中每条笔记的删除表单：

```django
<form class="inline" method="post" action="{% url 'notes:delete' note.pk %}">
  {% csrf_token %}
  <button type="submit">删除</button>
</form>
```

| 对比项 | 新建页 | 列表删除 |
| ------ | ------ | -------- |
| `action` | 省略（当前页） | 显式 `{% url 'notes:delete' note.pk %}` |
| 字段 | `form.as_p` | 仅按钮 + CSRF |
| 视图限制 | GET + POST | 仅 POST |

删除 POST 的完整链路：

```
浏览器 POST（csrfmiddlewaretoken + csrftoken Cookie）
  → CsrfViewMiddleware 校验（§2.7）
  → note_delete：delete() → 302 → GET 列表
```

校验失败时 **403**，`note.delete()` **不会执行**。

### 8.6 与本工程其它演示的关系


| 演示 | 路径 | 侧重 |
| ---- | ---- | ---- |
| `notes` 应用 | `/notes/` | 模板表单 + ModelForm + 函数视图 + `reverse` / `redirect` |
| `csrf_demo` | `/csrf-demo/` | 前后端分离式 `fetch` + `X-CSRFToken`（§6） |
| `drf_jwt_demo` | `/drf-jwt-demo/` | JWT 在 Header vs Cookie 时 CSRF 是否要（§7） |



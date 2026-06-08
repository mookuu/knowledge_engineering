# I/O 密集型 vs CPU 密集型 & Python GIL

## I/O 密集型（I/O-bound）

程序的执行速度受限于 **输入/输出操作** 的等待时间，而非 CPU 的计算速度。大部分时间花在等待外部设备或服务返回数据。

**常见场景：**
- 网络请求（HTTP 调用、爬虫、API 交互）
- 文件读写（磁盘 I/O）
- 数据库查询
- 等待用户输入

**特点：**
- 程序多数时间处于"等"的状态，CPU 利用率不高
- 提升性能的关键在于 **减少等待时间**，比如用 `asyncio`、多线程（`threading`）、或 `concurrent.futures.ThreadPoolExecutor`

```python
# I/O 密集的例子：等待网络响应
import requests

urls = [...]  # 100 个 URL
for url in urls:
    resp = requests.get(url)  # 大部分时间花在等网络返回
    print(resp.status_code)
```
优化方向：用 `asyncio` 或 `ThreadPoolExecutor` 并发执行这些请求。

---

## CPU 密集型（CPU-bound）

程序的执行速度受限于 **CPU 的计算能力**。程序一直在做运算，几乎没有等待。

**常见场景：**
- 大量数学运算（矩阵乘法、数值模拟）
- 图片/视频处理（逐像素操作）
- 数据压缩、加密解密
- 复杂搜索或排序（如迷宫求解、棋类博弈）

**特点：**
- CPU 利用率接近 100%
- 提升性能的关键在于 **利用多核并行计算**，用 `multiprocessing` 的 `ProcessPoolExecutor` 或 `concurrent.futures.ProcessPoolExecutor`

```python
# CPU 密集的例子：大量运算
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

results = [fibonacci(35) for _ in range(10)]  # CPU 跑满
```
优化方向：用 `multiprocessing.Pool` 分配到多个 CPU 核心上并行计算。

---

## 如何选择并发模型

| 特性 | I/O 密集型 | CPU 密集型 |
|------|-----------|-----------|
| 主要瓶颈 | 等待外部资源 | CPU 算力 |
| 推荐方案 | `asyncio` / `threading` | `multiprocessing` |
| Python GIL 影响 | 影响较小（等待时会释放 GIL） | 影响很大（多线程无法并行计算） |

对于 I/O 密集型，**多线程**在 Python 中就够用，因为等待 I/O 时会释放 GIL；而 CPU 密集型只有 **多进程** 才能突破 GIL 的限制真正实现并行。

---

# Python GIL 与多线程性能（深入）

## 核心问题
Python 有 GIL（Global Interpreter Lock），多线程为什么还能比单线程快？

## 答案

### 1. I/O 操作会释放 GIL
Python 内置 I/O（`socket.recv()`、`file.read()`、`time.sleep()`、`requests.get()`）底层调用 C 函数时会 **主动释放 GIL**：

- 线程 A 等待网络响应（释放 GIL）→ 线程 B 获得 GIL 执行代码
- 线程 B 遇到 I/O 又释放 GIL → 线程 C 继续执行

**效果**：单线程等待 I/O 时 CPU 空闲，多线程用这些时间执行其他线程的有用工作。

### 2. C 扩展可以显式释放 GIL
很多底层 C 扩展（NumPy、Pandas、`psycopg2`、`sqlite3`、`redis-py` 等）在执行长时间计算或等待时也会 **主动释放 GIL**，此时多个线程可真正并行在多个 CPU 核上。

### 3. 并发等待 → 整体吞吐提升
```python
# 单线程：顺序发 100 个请求，总时间 ≈ 100 × 0.1s = 10s
# 多线程：并发发 100 个请求，总时间 ≈ 0.1s + 调度开销
```
虽然同一时刻只有一个线程跑 Python 代码，但 **等待时间被重叠**，总耗时大幅降低。

---

## 什么时候多线程不行？（CPU 密集型）

```python
def count(n):
    while n > 0:
        n -= 1  # 纯 CPU 计算，不释放 GIL

# 单线程：10 秒
# 多线程（2 线程）：可能 10.5 秒（多了锁竞争 + 上下文切换开销）
```
每个线程从头到尾持有 GIL，另一线程只能等，反而多了调度开销。

---

## 对比总结

| 场景 | 相比单线程 | 原因 |
|------|-----------|------|
| **I/O 密集型**（网络、文件、数据库） | **更快 ✅** | I/O 释放 GIL，等待时间被重叠利用 |
| **CPU 密集型纯 Python** | 更慢或持平 ❌ | GIL 竞争 + 上下文切换开销 |
| **C 扩展密集型**（NumPy、图像处理） | **更快 ✅** 可能 | C 扩展释放 GIL，可真正并行 |

## 核心认识
Python 多线程不是「并行执行 Python 代码」，而是 **「在等待时让出 GIL，让其他线程干活」** —— 对于 I/O 密集场景，这恰好是最有价值的优化方式。

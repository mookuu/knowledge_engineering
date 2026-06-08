### 内置类型 Built-in Types

---

#### 数值类型 Numeric Types

+ `int` — 整数，任意精度，如 `42`, `-7`, `0xff`
+ `float` — 浮点数（双精度），如 `3.14`, `1e-5`
+ `complex` — 复数，如 `3+4j`，`.real` 取实部，`.imag` 取虚部
+ `bool` — 布尔值，`True` / `False`，是 `int` 的子类（True==1, False==0）

#### 序列类型 Sequence Types

+ `str` — 字符串，不可变的 Unicode 字符序列
  + 字面量：`'hello'`, `"world"`, `'''多行'''`, `f"格式化{var}"`
  + 支持索引、切片、拼接 `+`、重复 `*`、成员测试 `in`
+ `list` — 列表，可变序列，可存放任意类型
  + 字面量：`[1, 'a', True]`
  + 支持索引、切片、原地修改
+ `tuple` — 元组，不可变序列
  + 字面量：`(1, 2, 3)` 或 `1, 2, 3`
  + 单元素元组：`(1,)` 注意逗号
  + 可作字典键、集合元素（前提是元素都可哈希）
+ `range` — 不可变的整数等差序列
  + `range(stop)`, `range(start, stop)`, `range(start, stop, step)`
  + 惰性求值，不实际存储所有元素

#### 二进制序列 Binary Sequence Types

+ `bytes` — 不可变字节序列，如 `b'hello'`
  + 每个元素是 0~255 的整数
  + `str.encode()` → bytes，`bytes.decode()` → str
+ `bytearray` — 可变字节序列
  + 与 bytes 类似但支持原地修改
+ `memoryview` — 内存视图，无需复制即可操作二进制数据的切片

#### 映射类型 Mapping Type

+ `dict` — 字典，可变的键值对映射
  + 字面量：`{'a': 1, 'b': 2}`
  + 键必须可哈希（str, int, tuple 等）
  + 保持插入顺序（Python 3.7+）

#### 集合类型 Set Types

+ `set` — 可变集合，元素唯一且无序
  + 字面量：`{1, 2, 3}`（空集合用 `set()`，`{}` 是空字典）
  + 元素必须可哈希
  + 支持交集 `&`、并集 `|`、差集 `-`、对称差 `^`
+ `frozenset` — 不可变集合
  + 可作字典键和集合元素

#### 布尔类型 Boolean Type

+ `bool` — `True` / `False`
+ 以下值为假值（falsy）：
  + `None`, `False`
  + 数值零：`0`, `0.0`, `0j`
  + 空序列/集合：`""`, `()`, `[]`, `{}`, `set()`, `range(0)`
  + 自定义对象 `__bool__()` 返回 False 或 `__len__()` 返回 0

#### None 类型

+ `NoneType` — 唯一实例 `None`
  + 表示"无值"或"缺省"
  + 函数无显式 return 时返回 None
  + 判断用 `is None` / `is not None`（不要用 `==`）

#### 迭代器与生成器 Iterator / Generator

+ `iterator` — 实现了 `__iter__()` 和 `__next__()` 的对象
  + 通过 `iter(iterable)` 获取
  + 用 `next(it)` 逐个取值，耗尽抛 `StopIteration`
+ `generator` — 用 `yield` 的函数返回的迭代器
  + 惰性求值，按需产出
  + 生成器表达式：`(x**2 for x in range(10))`

#### 可调用类型 Callable Types

+ `function` — 用 `def` 或 `lambda` 定义的函数
+ `method` — 绑定到对象的函数
+ `builtin_function_or_method` — C 实现的内置函数，如 `len`, `print`
+ 自定义可调用：实现 `__call__()` 方法的类实例

#### 上下文管理器 Context Manager

+ 实现 `__enter__()` 和 `__exit__()` 的对象
+ 配合 `with` 语句使用
+ 常见：文件对象、锁、数据库连接、`contextlib.contextmanager`

#### 类型注解相关 Type Annotation

+ `type` — 类的类型（元类），`type(obj)` 返回对象的类
+ `type[C]` — 表示 C 本身或其子类（Python 3.9+）
+ `typing.Optional[X]` — 等价 `X | None`
+ `typing.Union[X, Y]` — X 或 Y，Python 3.10+ 可写 `X | Y`

---

### 类型分类速查

#### 按可变性

| 不可变 immutable | 可变 mutable |
|:---|:---|
| int, float, complex, bool | list |
| str, bytes, tuple | dict |
| frozenset, range, None | set, bytearray |

#### 按是否可哈希

+ 可哈希（可作 dict 键 / set 元素）：int, float, str, bytes, tuple（元素都可哈希时）, frozenset, None, bool
+ 不可哈希：list, dict, set, bytearray

#### 按用途

+ 数值：int, float, complex, bool
+ 文本：str
+ 二进制：bytes, bytearray, memoryview
+ 容器：list, tuple, dict, set, frozenset
+ 特殊：None, range, iterator, generator, type

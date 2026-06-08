### 常见内置函数 Built-in Functions

#### 类型转换

+ `int(x)` — 转为整数
+ `float(x)` — 转为浮点数
+ `complex(real, imag)` — 创建复数
+ `bool(x)` — 转为布尔值
+ `str(x)` — 转为字符串
+ `bytes(x)` — 转为字节串
+ `bytearray(x)` — 转为可变字节数组
+ `list(iterable)` — 转为列表
+ `tuple(iterable)` — 转为元组
+ `set(iterable)` — 转为集合
+ `frozenset(iterable)` — 转为不可变集合
+ `dict(**kwargs)` — 创建字典
+ `chr(i)` — 整数 → Unicode 字符
+ `ord(c)` — 字符 → Unicode 码点
+ `hex(x)` — 整数 → 十六进制字符串
+ `oct(x)` — 整数 → 八进制字符串
+ `bin(x)` — 整数 → 二进制字符串

#### 数学运算

+ `abs(x)` — 绝对值
+ `round(x, n)` — 四舍五入到 n 位小数
+ `pow(base, exp, mod=None)` — 幂运算，等价 `base ** exp % mod`
+ `divmod(a, b)` — 返回 `(商, 余数)`
+ `max(iterable)` — 最大值
+ `min(iterable)` — 最小值
+ `sum(iterable, start=0)` — 求和

#### 迭代与序列

+ `range(start, stop, step)` — 生成整数序列
+ `len(s)` — 返回长度
+ `sorted(iterable, key=None, reverse=False)` — 返回排序后的新列表
+ `reversed(seq)` — 返回反向迭代器
+ `enumerate(iterable, start=0)` — 返回 `(索引, 元素)` 的迭代器
+ `zip(*iterables)` — 并行聚合多个可迭代对象
+ `map(func, *iterables)` — 对每个元素应用函数
+ `filter(func, iterable)` — 过滤保留 func 返回 True 的元素
+ `iter(obj)` — 获取迭代器
+ `next(iterator, default)` — 获取下一个元素
+ `all(iterable)` — 所有元素为真则返回 True
+ `any(iterable)` — 任一元素为真则返回 True
+ `slice(start, stop, step)` — 创建切片对象

#### 输入输出

+ `print(*objects, sep=' ', end='\n', file=sys.stdout)` — 打印
+ `input(prompt)` — 读取用户输入（返回字符串）
+ `open(file, mode='r')` — 打开文件，返回文件对象
+ `format(value, format_spec)` — 格式化值
+ `repr(obj)` — 返回对象的可打印字符串表示（开发调试用）

#### 对象与属性

+ `type(obj)` — 返回对象类型
+ `isinstance(obj, classinfo)` — 判断是否为某类型的实例
+ `issubclass(cls, classinfo)` — 判断是否为子类
+ `id(obj)` — 返回对象唯一标识（内存地址）
+ `hash(obj)` — 返回哈希值
+ `callable(obj)` — 判断对象是否可调用
+ `getattr(obj, name, default)` — 获取属性
+ `setattr(obj, name, value)` — 设置属性
+ `delattr(obj, name)` — 删除属性
+ `hasattr(obj, name)` — 判断是否有该属性
+ `vars(obj)` — 返回对象的 `__dict__`
+ `dir(obj)` — 列出对象所有属性名
+ `property(fget, fset, fdel, doc)` — 创建属性描述符

#### 类与继承

+ `super()` — 返回父类代理对象
+ `classmethod(func)` — 将方法转为类方法（通常用 `@classmethod`）
+ `staticmethod(func)` — 将方法转为静态方法（通常用 `@staticmethod`）
+ `object()` — 所有类的基类实例

#### 函数式编程

+ `lambda` — 匿名函数（关键字，非函数）
+ `functools.reduce(func, iterable)` — 累积归约（需 import）
+ `functools.partial(func, *args)` — 偏函数（需 import）

#### 其他常用

+ `globals()` — 返回当前全局符号表字典
+ `locals()` — 返回当前局部符号表字典
+ `exec(code)` — 执行动态 Python 代码
+ `eval(expression)` — 求值表达式并返回结果
+ `compile(source, filename, mode)` — 编译为代码对象
+ `__import__(name)` — 底层导入机制（一般用 `import` 语句）
+ `help(obj)` — 查看帮助文档
+ `breakpoint()` — 进入调试器（Python 3.7+）
+ `memoryview(obj)` — 创建内存视图对象

---

### 常见内置方法 Built-in Methods

#### str 字符串方法

+ `s.upper()` / `s.lower()` — 转大写 / 小写
+ `s.strip()` / `s.lstrip()` / `s.rstrip()` — 去除首尾空白
+ `s.split(sep)` / `s.rsplit(sep)` — 按分隔符拆分
+ `s.join(iterable)` — 用 s 拼接可迭代对象中的字符串
+ `s.replace(old, new, count)` — 替换子串
+ `s.find(sub)` / `s.rfind(sub)` — 查找子串位置，找不到返回 -1
+ `s.index(sub)` / `s.rindex(sub)` — 查找子串位置，找不到抛异常
+ `s.startswith(prefix)` / `s.endswith(suffix)` — 判断开头 / 结尾
+ `s.count(sub)` — 统计子串出现次数
+ `s.format(*args, **kwargs)` — 格式化字符串
+ `s.encode(encoding='utf-8')` — 编码为 bytes
+ `s.isdigit()` / `s.isalpha()` / `s.isalnum()` — 判断数字 / 字母 / 字母数字
+ `s.title()` / `s.capitalize()` / `s.swapcase()` — 标题化 / 首字母大写 / 大小写互换
+ `s.center(width)` / `s.ljust(width)` / `s.rjust(width)` — 居中 / 左对齐 / 右对齐
+ `s.zfill(width)` — 左侧补零
+ `s.partition(sep)` / `s.rpartition(sep)` — 按分隔符拆为三元组
+ `s.maketrans()` / `s.translate(table)` — 字符映射替换

#### list 列表方法

+ `l.append(x)` — 末尾添加元素
+ `l.extend(iterable)` — 末尾批量添加
+ `l.insert(i, x)` — 在位置 i 插入
+ `l.remove(x)` — 删除第一个值为 x 的元素
+ `l.pop(i=-1)` — 弹出并返回索引 i 的元素
+ `l.clear()` — 清空列表
+ `l.index(x)` — 返回 x 的索引
+ `l.count(x)` — 统计 x 的个数
+ `l.sort(key=None, reverse=False)` — 原地排序
+ `l.reverse()` — 原地反转
+ `l.copy()` — 浅拷贝

#### dict 字典方法

+ `d.keys()` — 返回所有键的视图
+ `d.values()` — 返回所有值的视图
+ `d.items()` — 返回所有键值对的视图
+ `d.get(key, default=None)` — 安全获取值
+ `d.setdefault(key, default=None)` — 键不存在则设置默认值并返回
+ `d.update(other)` — 批量更新键值对
+ `d.pop(key, default)` — 弹出指定键
+ `d.popitem()` — 弹出最后插入的键值对（LIFO）
+ `d.clear()` — 清空字典
+ `d.copy()` — 浅拷贝
+ `d.fromkeys(iterable, value=None)` — 从键序列创建字典（类方法）
+ `d | other` — 合并字典（Python 3.9+）

#### set 集合方法

+ `s.add(x)` — 添加元素
+ `s.remove(x)` — 删除元素（不存在则报错）
+ `s.discard(x)` — 删除元素（不存在不报错）
+ `s.pop()` — 随机弹出一个元素
+ `s.clear()` — 清空集合
+ `s.union(other)` / `s | other` — 并集
+ `s.intersection(other)` / `s & other` — 交集
+ `s.difference(other)` / `s - other` — 差集
+ `s.symmetric_difference(other)` / `s ^ other` — 对称差集
+ `s.issubset(other)` — 是否为子集
+ `s.issuperset(other)` — 是否为超集
+ `s.isdisjoint(other)` — 是否无交集
+ `s.update(other)` — 原地并集
+ `s.intersection_update(other)` — 原地交集
+ `s.difference_update(other)` — 原地差集

#### tuple 元组方法

+ `t.count(x)` — 统计 x 的个数
+ `t.index(x)` — 返回 x 的索引

#### 文件对象方法

+ `f.read(size=-1)` — 读取全部或指定字节
+ `f.readline()` — 读取一行
+ `f.readlines()` — 读取所有行，返回列表
+ `f.write(s)` — 写入字符串
+ `f.writelines(lines)` — 写入多行
+ `f.seek(offset, whence=0)` — 移动文件指针
+ `f.tell()` — 返回当前文件指针位置
+ `f.close()` — 关闭文件
+ `f.flush()` — 刷新缓冲区

### numbers 数字塔

来源：`fluent_python/module/protocol/abc_standard.py`（`numbers` 模块）

数字塔从最基础的 `Number` 到最具体的 `Integral`。各抽象基类的层次结构是线性的：


| 抽象基类       | 含义      |
| ---------- | ------- |
| `Number`   | 数字基类    |
| `Complex`  | 复数抽象基类  |
| `Real`     | 实数抽象基类  |
| `Rational` | 有理数抽象基类 |
| `Integral` | 整数抽象基类  |


```
Number（数字抽象基类）
  ├── Complex（复数抽象基类）
  │     ├── Real（实数抽象基类）
  │     │     ├── Rational（有理数抽象基类）
  │     │     │     └── Integral（整数抽象基类）
```

用 `isinstance(obj, SomeABC)` 判断对象是否具备对应数学属性，比 `type(obj) is int` 更灵活（自定义类注册为子类后也能通过检查）。

---

#### 1. Number — 一切数字的顶类

```python
from numbers import Number

isinstance(42, Number)              # True  int
isinstance(3.14, Number)              # True  float
isinstance(2 + 3j, Number)            # True  complex
from fractions import Fraction
isinstance(Fraction(1, 3), Number)    # True  Fraction
```

只要是「数值」，通常都满足 `Number`。

---

#### 2. Complex — 支持复数运算

```python
from numbers import Complex

isinstance(2 + 3j, Complex)     # True
isinstance(3.14, Complex)       # True  float 也是 Complex 的子类（实数可看作虚部为 0 的复数）
isinstance(5, Complex)          # True  int 同理
```

能参与复数语境的类型；内置 `complex`、`float`、`int` 都算。

##### Python 内置复数（`complex` 类型）

数学写法 z = a + bi 在 Python 中为 `z = a + b*j`（用 `**j**` 不用 `i`）：


| 数学              | Python   |
| --------------- | -------- |
| 实部 a            | `z.real` |
| 虚部 b（系数，不含 `j`） | `z.imag` |


```python
z = 2 + 3j
z.real   # 2.0
z.imag   # 3.0   ← 虚部是系数 3，不是 3j
abs(z)   # 模长 √(2²+3²) ≈ 3.605
```

从实部、虚部构造：`complex(2, 3)` 等价于 `2 + 3j`。

常用操作：

```python
z = 2 + 3j
z.conjugate()   # (2-3j)  共轭：虚部变号
abs(z)          # 模长 |z| = √(real² + imag²)
```

##### 虚部（imaginary part）

虚部是复数里 **乘以虚数单位** 的那一部分：`.imag` 返回的是系数 b，不包含 `j`。

纯实数在内部也可看作虚部为 0 的复数：

```python
x = 3.14
x.imag   # 0.0

complex(5).imag   # 0.0  int 需先转成 complex 才有 .imag
```

因此 `float`、`int` 也属于 `Complex`（实数 = 虚部为 0 的复数）；`numbers.Real` 的判定依据是 **虚部是否为 0**：


| 值        | `isinstance(..., Complex)` | `isinstance(..., Real)` |
| -------- | -------------------------- | ----------------------- |
| `3.14`   | ✓                          | ✓                       |
| `3 + 0j` | ✓                          | ✓（虚部为 0）                |
| `2 + 3j` | ✓                          | ✗（虚部非 0）                |


---

#### 3. Real — 实数（虚部为 0）

```python
from numbers import Real

isinstance(3.14, Real)          # True
isinstance(5, Real)             # True
isinstance(2 + 3j, Real)        # False  有非零虚部
isinstance(3 + 0j, Real)        # True   虚部为 0 时仍算实数
```

没有「有效虚部」的数；`float`、`int` 属于这一类。

---

#### 4. Rational — 有理数（可写成 p/q）

```python
from fractions import Fraction
from numbers import Rational

isinstance(Fraction(2, 5), Rational)   # True  2/5
isinstance(4, Rational)                # True  整数也是有理数（4 = 4/1）
isinstance(3.14, Rational)             # False float 一般不能精确表示为分数
```

`fractions.Fraction` 是典型的 `Rational`；整数也可以。

##### 什么是有理数

有理数是可以写成 **两个整数之比** \frac{p}{q} 的数，其中 p、q 为整数且 q \neq 0。


| 例子           | 分数形式     | 是否有理数      |
| ------------ | -------- | ---------- |
| \frac{2}{5}  | 2/5      | ✓          |
| 4            | 4/1      | ✓（整数也是有理数） |
| 0.5          | 1/2      | ✓          |
| \pi、\sqrt{2} | 不能写成 p/q | ✗（无理数）     |


在数字塔中的位置（位于实数之下、整数之上）：

```
Real（实数）
  └── Rational（有理数）
        └── Integral（整数）
```

##### fractions.Fraction

Python 没有内置的 `rational` 类型，用标准库 `**fractions.Fraction**` 精确表示分数：

```python
from fractions import Fraction

Fraction(2, 5)                    # Fraction(2, 5)
Fraction(1, 3) + Fraction(1, 6) # Fraction(1, 2)  精确运算，无浮点误差
Fraction('-3/7')                  # 也支持字符串构造
float(Fraction(1, 3))             # 0.333...  需要近似时才转 float
```

`Fraction` 会自动约分，并保持分子、分母为整数：

```python
Fraction(6, 8)    # Fraction(3, 4)
Fraction(6, 8).numerator    # 3
Fraction(6, 8).denominator  # 4
```

##### 与 float 的区别


|                             | `Fraction`   | `float`           |
| --------------------------- | ------------ | ----------------- |
| 存储                          | 分子 / 分母（整数比） | 二进制浮点近似           |
| `isinstance(..., Rational)` | ✓            | ✗                 |
| 1/3 + 1/3 + 1/3             | 精确得 `1`      | 可能得 `0.999999...` |
| 适用场景                        | 需要精确分数运算     | 科学计算、一般小数         |


```python
from numbers import Rational

isinstance(Fraction(1, 3), Rational)  # True
isinstance(0.3333333333333333, Rational)  # False
```

**为什么 `3.14` 不是 `Rational`？**  
`float` 很多十进制小数无法 **精确** 表示为 \frac{p}{q}；`numbers.Rational` 描述的是「能精确写成整数比」的对象，而不是「看起来像小数的实数」。

有限小数往往是有理数，但在 Python 里用 `float` 存时仍不算 `Rational`；要用分数表示应写 `Fraction(314, 100)` 或 `Fraction('3.14')`（能精确解析时）。

---

#### 5. Integral — 整数

```python
from numbers import Integral

isinstance(42, Integral)        # True
isinstance(True, Integral)      # True  bool 是 int 的子类
isinstance(3.14, Integral)      # False
isinstance(Fraction(7, 1), Integral)  # True  分母为 1 的分数算整数
```

没有小数部分的数；`int`、`bool` 属于这一类。

---

#### 对照表（常见内置类型）


| 值               | Number | Complex | Real | Rational | Integral |
| --------------- | ------ | ------- | ---- | -------- | -------- |
| `42`            | ✓      | ✓       | ✓    | ✓        | ✓        |
| `3.14`          | ✓      | ✓       | ✓    | ✗        | ✗        |
| `2+3j`          | ✓      | ✓       | ✗    | ✗        | ✗        |
| `Fraction(1,2)` | ✓      | ✓       | ✓    | ✓        | ✗        |


---

#### 实际用途

按「数学能力」约束参数，而不是写死 `int`：

```python
from numbers import Real, Integral

def double(x):
    if isinstance(x, Integral):
        return x * 2          # 整数路径
    if isinstance(x, Real):
        return x * 2.0        # 实数路径
    raise TypeError("需要数字")
```

与 `collections.abc` 中 `Callable`、`Hashable` 的用法一致：用 ABC 描述对象应具备的行为或数学属性。

`fluent_python/module/class/vector_v2.py` 中标量乘法使用 `numbers.Real`，即 **只允许虚部为 0 的标量**：

```python
from numbers import Real
import numbers

# Vector.__mul__ 内：isinstance(other, numbers.Real)
v * 10          # ✓
v * (2 + 0j)    # ✓  虚部为 0，仍是 Real
v * (2 + 3j)    # ✗  返回 NotImplemented
```

若需支持复数标量，应改为 `isinstance(other, numbers.Complex)`，并将 `array` 的 `typecode` 从 `"d"`（双精度实数）改为 `"D"`（双精度复数）。

---

#### 批量验证（可复制运行）

```python
from fractions import Fraction
from numbers import Number, Complex, Real, Rational, Integral

ABCS = (Number, Complex, Real, Rational, Integral)

for v in [42, 3.14, 2 + 3j, Fraction(1, 2)]:
    names = [abc.__name__ for abc in ABCS if isinstance(v, abc)]
    print(f"{v!r:20} -> {', '.join(names)}")
```

预期输出大致为：

```
42                   -> Number, Complex, Real, Rational, Integral
3.14                 -> Number, Complex, Real
(2+3j)               -> Number, Complex
Fraction(1, 2)       -> Number, Complex, Real, Rational
```


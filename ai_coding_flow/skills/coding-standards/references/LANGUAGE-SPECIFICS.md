# Language-Specific Considerations

While the core principles in the coding-standards skill apply across all languages, each language has specific idioms and best practices. This document provides language-specific guidance.

## Python

**Type Hints:**
```python
def calculate_total(items: list[Item], tax_rate: float) -> float:
    subtotal = sum(item.price for item in items)
    return subtotal * (1 + tax_rate)
```

**Best Practices:**
- Follow PEP 8 style guide
- Use type hints for function signatures
- Use list/dict comprehensions judiciously (not for side effects)
- Leverage context managers for resource management
- Use dataclasses/attrs for data structures

**Example - Context Managers:**
```python
with open('file.txt', 'r') as f:
    content = f.read()
# File automatically closed
```

**Example - Dataclasses:**
```python
from dataclasses import dataclass

@dataclass
class User:
    id: str
    email: str
    name: str
```

---

## JavaScript/TypeScript

**Type Safety:**
```typescript
interface UserData {
  email: string;
  name: string;
}

function createUser(data: UserData): User {
  // TypeScript ensures data has required fields
}
```

**Best Practices:**
- Use TypeScript for type safety in larger projects
- Avoid `var`, use `const` by default, `let` when needed
- Use async/await over callbacks
- Destructure objects for cleaner code
- Use `===` over `==`

**Example - Async/Await:**
```typescript
// ❌ BAD:
getUser(id, (err, user) => {
  if (err) return handleError(err);
  getOrders(user.id, (err, orders) => {
    // callback hell
  });
});

// ✅ GOOD:
async function getUserOrders(id: string): Promise<Order[]> {
  const user = await getUser(id);
  return await getOrders(user.id);
}
```

**Example - Destructuring:**
```typescript
// ❌ BAD:
function displayUser(user: User) {
  console.log(user.name);
  console.log(user.email);
}

// ✅ GOOD:
function displayUser({ name, email }: User) {
  console.log(name);
  console.log(email);
}
```

---

## Java

**Interfaces and Abstraction:**
```java
public interface UserRepository {
    User findById(String id);
    void save(User user);
}

public class DatabaseUserRepository implements UserRepository {
    @Override
    public User findById(String id) {
        // implementation
    }

    @Override
    public void save(User user) {
        // implementation
    }
}
```

**Best Practices:**
- Use interfaces for abstraction
- Prefer immutability where possible
- Use modern Java features (streams, Optional, records)
- Avoid null - use Optional or validation
- Proper exception hierarchy

**Example - Optional:**
```java
// ❌ BAD:
public User findUser(String id) {
    // might return null
}

// ✅ GOOD:
public Optional<User> findUser(String id) {
    // clear that user might not exist
}
```

**Example - Records (Java 14+):**
```java
public record User(String id, String email, String name) {
    // Immutable by default, equals/hashCode/toString auto-generated
}
```

---

## Go

**Error Handling:**
```go
func getUser(id string) (*User, error) {
    user, err := db.Find(id)
    if err != nil {
        return nil, fmt.Errorf("failed to find user: %w", err)
    }
    return user, nil
}
```

**Best Practices:**
- Follow Go idioms (Effective Go)
- Error handling: check errors, don't panic
- Use interfaces for abstraction
- Keep packages focused
- Use goroutines judiciously

**Example - Interfaces:**
```go
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}
```

**Example - Defer for Cleanup:**
```go
func processFile(filename string) error {
    file, err := os.Open(filename)
    if err != nil {
        return err
    }
    defer file.Close() // Ensures file is closed

    // process file
    return nil
}
```

---

## Rust

**Ownership and Borrowing:**
```rust
fn process_data(data: &str) -> String {
    // Borrows data, doesn't take ownership
    data.to_uppercase()
}

let original = String::from("hello");
let processed = process_data(&original);
// original still usable here
```

**Best Practices:**
- Embrace ownership system
- Use Result and Option types
- Minimize unsafe code
- Follow Rust naming conventions
- Use cargo fmt and clippy

**Example - Result Type:**
```rust
fn divide(a: f64, b: f64) -> Result<f64, String> {
    if b == 0.0 {
        Err("Division by zero".to_string())
    } else {
        Ok(a / b)
    }
}
```

**Example - Option Type:**
```rust
fn find_user(id: &str) -> Option<User> {
    // Returns Some(user) or None
}

if let Some(user) = find_user("123") {
    println!("Found: {}", user.name);
} else {
    println!("User not found");
}
```

---

## Common Patterns Across Languages

### Null Safety

**Python:**
```python
user: Optional[User] = find_user(id)
if user is not None:
    print(user.name)
```

**TypeScript:**
```typescript
const user: User | null = findUser(id);
if (user !== null) {
  console.log(user.name);
}
```

**Java:**
```java
Optional<User> user = findUser(id);
user.ifPresent(u -> System.out.println(u.getName()));
```

**Rust:**
```rust
if let Some(user) = find_user(&id) {
    println!("{}", user.name);
}
```

### Resource Management

**Python:**
```python
with resource_manager() as resource:
    # use resource
# automatically cleaned up
```

**Java:**
```java
try (Resource resource = new Resource()) {
    // use resource
} // automatically closed
```

**Go:**
```go
defer resource.Close()
```

**Rust:**
```rust
// RAII - automatic cleanup when variable goes out of scope
{
    let resource = Resource::new();
    // use resource
} // resource automatically dropped
```

---

## Language-Specific Anti-Patterns

### Python
- Using mutable default arguments
- Bare except clauses
- Not using context managers for resources
- Mixing tabs and spaces

### JavaScript/TypeScript
- Using `==` instead of `===`
- Not handling Promise rejections
- Mutating function parameters
- Excessive use of `any` in TypeScript

### Java
- Overuse of inheritance
- Not closing resources
- Catching Exception instead of specific exceptions
- Null pointer exceptions

### Go
- Ignoring errors
- Goroutine leaks
- Not using interfaces for testability
- Panic in library code

### Rust
- Fighting the borrow checker with clones
- Excessive use of `unsafe`
- Not using Result for fallible operations
- Unwrapping everywhere instead of proper error handling

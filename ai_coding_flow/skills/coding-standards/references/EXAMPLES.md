# Practical Examples

This document provides detailed code examples demonstrating the core design principles from the coding-standards skill.

## Example 1: Applying DRY

**❌ BEFORE (Repetitive):**

```typescript
interface UserData {
  email?: string;
  name: string;
  password: string;
}

interface Result {
  error?: string;
  data?: User;
}

function createUser(data: UserData): Result {
  if (!data.email) {
    return { error: "Email required" };
  }
  if (!data.email.includes("@")) {
    return { error: "Invalid email" };
  }
  // create user
}

function updateUser(data: UserData): Result {
  if (!data.email) {
    return { error: "Email required" };
  }
  if (!data.email.includes("@")) {
    return { error: "Invalid email" };
  }
  // update user
}
```

**✅ AFTER (DRY):**

```typescript
interface UserData {
  email?: string;
  name: string;
  password: string;
}

interface User {
  id: string;
  email: string;
  name: string;
}

function validateEmail(email: string | undefined): string {
  if (!email) {
    throw new Error("Email required");
  }
  if (!email.includes("@")) {
    throw new Error("Invalid email");
  }
  return email;
}

function createUser(data: UserData): User {
  const email = validateEmail(data.email);
  // create user with validated email
}

function updateUser(data: UserData): User {
  const email = validateEmail(data.email);
  // update user with validated email
}
```

## Example 2: Single Responsibility Principle

**❌ BEFORE (Multiple responsibilities):**

```typescript
interface UserData {
  email: string;
  password: string;
  name: string;
}

class UserManager {
  processUser(userData: UserData): void {
    // Validate user
    if (!userData.email) {
      throw new Error("Invalid email");
    }

    // Hash password
    const hashed = hashPassword(userData.password);

    // Save to database
    db.save(userData);

    // Send welcome email
    emailService.send(userData.email, "Welcome!");

    // Log activity
    logger.info(`User ${userData.email} created`);
  }
}
```

**✅ AFTER (Single responsibility):**

```typescript
interface UserData {
  email: string;
  password: string;
  name: string;
}

interface User {
  id: string;
  email: string;
  name: string;
}

class UserValidator {
  validate(userData: UserData): boolean {
    if (!userData.email) {
      throw new Error("Invalid email");
    }
    return true;
  }
}

class UserRepository {
  save(user: UserData): User {
    return db.save(user);
  }
}

class WelcomeEmailService {
  sendWelcome(user: User): void {
    emailService.send(user.email, "Welcome!");
  }
}

class UserRegistrationService {
  constructor(
    private validator: UserValidator,
    private repository: UserRepository,
    private emailService: WelcomeEmailService,
  ) {}

  register(userData: UserData): User {
    this.validator.validate(userData);
    const user = this.repository.save(userData);
    this.emailService.sendWelcome(user);
    logger.info(`User ${user.email} created`);
    return user;
  }
}
```

## Example 3: Composition Over Inheritance

**❌ BEFORE (Deep inheritance):**

```typescript
class Vehicle {
  start(): void {}
}

class Car extends Vehicle {
  drive(): void {}
}

class ElectricCar extends Car {
  charge(): void {}
}

class TeslaModelS extends ElectricCar {
  autopilot(): void {}
}
```

**✅ AFTER (Composition):**

```typescript
interface Engine {
  start(): void;
}

class ElectricMotor implements Engine {
  start(): void {
    // start electric motor
  }

  charge(): void {
    // charge battery
  }
}

class AutopilotSystem {
  engage(): void {
    // engage autopilot
  }
}

class Vehicle {
  constructor(protected engine: Engine) {}

  start(): void {
    this.engine.start();
  }
}

class TeslaModelS extends Vehicle {
  private autopilot: AutopilotSystem;

  constructor() {
    super(new ElectricMotor());
    this.autopilot = new AutopilotSystem();
  }

  enableAutopilot(): void {
    this.autopilot.engage();
  }
}
```

## Example 4: Avoiding Deep Nesting

**❌ BEFORE (Deep nesting):**

```typescript
if (user !== null) {
  if (user.isActive) {
    if (user.hasPermission("write")) {
      // do something
    }
  }
}
```

**✅ AFTER (Early returns/guards):**

```typescript
if (user === null) return;
if (!user.isActive) return;
if (!user.hasPermission("write")) return;
// do something
```

This approach:
- Reduces nesting levels
- Makes the code easier to read
- Clarifies exit conditions upfront
- Reduces cognitive load

## When to Use These Patterns

**Apply DRY when:**
- Same logic appears 3+ times
- The abstraction is clear and natural
- Changes to the logic should affect all uses

**Don't apply DRY when:**
- Two similar pieces of code serve different purposes
- The abstraction would be more complex than duplication
- Code is unlikely to change together

**Apply SRP when:**
- Class/function is hard to name without "and"
- Changes for one reason affect unrelated functionality
- Testing requires mocking many dependencies

**Apply Composition when:**
- Multiple inheritance creates diamond problem
- Behavior needs to be mixed and matched
- Inheritance depth exceeds 2-3 levels

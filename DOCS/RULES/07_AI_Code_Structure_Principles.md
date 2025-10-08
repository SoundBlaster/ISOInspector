# AI Code Structure Principles

## Rule 1: One File --- One Entity

### 🔹 Rule 1 Summary

Each source file must define **exactly one top-level entity** --- a `class`, `struct`, `enum`, or `protocol`.

### ✅ Rule 1 Guidelines

- One top-level type per file.\
- The filename must **match the entity name** (e.g., `User.swift` → `User`).\
- Nested types and extensions of the same entity are allowed.\
- Private helpers are allowed **only** if used internally by that entity.\
- Keep file size small and focused --- ideally under **600 lines**.\
- Do not merge unrelated types into a single file for convenience.

### ✅ Rule 1 Examples

**Correct:**

``` swift
// File: User.swift
struct User {
    let id: UUID
    let name: String
}

```

**Also acceptable:**

``` swift
// File: User.swift
struct User {
    let id: UUID
}

extension User {
    var isGuest: Bool { id == UUID(0) }
}

```

### ❌ Incorrect Example

``` swift
// File: Models.swift
struct User { ... }
struct Post { ... }     // ❌ Multiple top-level entities
enum UserError { ... }  // ❌ Another type in the same file

```

### 💡 Rule 1 Rationale

- Improves readability and navigation.\
- Reduces merge conflicts and cognitive load.\
- Makes AI-based code generation, testing, and documentation simpler and more deterministic.

---

## Rule 2: Small Files --- Lightweight Agents

### 🔹 Rule 2 Summary

AI agents must produce **small, focused source files** that are easy to read, maintain, and review. Large files increase
complexity, reduce clarity, and make version control harder.

### ✅ Rule 2 Guidelines

- Keep each file **under 400--600 lines**.\
- Split logic into **smaller, composable units** (e.g., separate files for extensions, helpers, or submodules).\
- Prefer **composition over nesting** --- deep hierarchies or long classes are harder to maintain.\
- Avoid placing **multiple responsibilities** in one file.\
- If a file grows too large, the agent must **proactively suggest refactoring** into smaller parts.

### ✅ Rule 2 Examples

**Correct:**

``` swift
// File: User.swift
struct User { ... }

// File: User+Validation.swift
extension User {
    func isValid() -> Bool { ... }
}

```

**Incorrect:**

``` swift
// File: User.swift
struct User { ... }
// Hundreds of lines of validation, networking, and persistence logic ❌

```

### 💡 Rule 2 Rationale

- Easier to understand and test small, self-contained files.\
- Improves incremental compilation speed.\
- Keeps pull requests smaller and more reviewable.\
- Enables AI agents to reason about and modify code safely, without unintended side effects.

### 🤖 Agent Behavior

When generating or updating code, an AI agent must:

1. **Estimate file length and complexity** before writing.\
1. **Split code automatically** if it exceeds recommended thresholds.\
1. Use **clear file naming** (e.g., `User+Mapping.swift`, `User+Storage.swift`).\
1. Never merge unrelated logic into one "god file."

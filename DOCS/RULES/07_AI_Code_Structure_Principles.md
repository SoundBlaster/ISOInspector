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

### ❌ Incorrect Example — Rule 1

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

---

## Rule 3: Prefer Structs Over Tuples for Domain Data

### 🔹 Rule 3 Summary

Represent domain concepts and multi-field values with named types (`struct`, `class`, or `enum`) instead of tuples.

### ✅ Rule 3 Guidelines

- Use tuples only for short-lived helpers with **no more than two elements** (e.g., a key-value pair in a `map`).\
- When more data is needed, introduce a dedicated type with descriptive property names.\
- Prefer small immutable `struct`s for read-only aggregates that mirror ISO box payload entries.\
- Update tests and fixtures to mirror production types instead of large tuples.

### ❌ Incorrect Example — Rule 3

``` swift
let entry: (UInt32, UInt32, UInt32, UInt32) = (1, 8, 3, 24) // ❌ No context for each element

```

### ✅ Correct Example — Rule 3

``` swift
struct SampleToChunkEntry {
    let firstChunk: UInt32
    let samplesPerChunk: UInt32
    let sampleDescriptionIndex: UInt32
}

let entry = SampleToChunkEntry(firstChunk: 1, samplesPerChunk: 8, sampleDescriptionIndex: 3)

```

### 💡 Rule 3 Rationale

- Named properties make ISO box payloads self-documenting.\
- SwiftLint's `large_tuple` rule stays silent, keeping CI noise low.\
- Structs scale gracefully if metadata or helper methods are added later.

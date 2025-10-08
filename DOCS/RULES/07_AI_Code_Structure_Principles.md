# 07 — AI Code Structure Principles

## 🧩 Purpose

Establish lightweight, single-responsibility source files so engineers and AI agents can reason about codebases quickly,
limit merge conflicts, and deliver incremental changes safely.

## 📦 Scope

These rules apply to all source files generated or edited by AI agents across the project. They focus on the shape and
contents of each file rather than language-specific syntax.

## 🧱 Rule 1 — One File, One Top-Level Entity

- Define exactly one primary type (`class`, `struct`, `enum`, or `protocol`) per source file.
- Match the filename to the entity name (for example, `User.swift` → `User`).
- Keep nested types or extensions only when they relate to the primary entity.
- Allow private helpers solely when they support the entity inside the same file.

### ✅ Examples

```swift
// File: User.swift
struct User {
    let id: UUID
    let name: String
}

```

```swift
// File: User.swift
struct User {
    let id: UUID
}

extension User {
    var isGuest: Bool { id == UUID(0) }
}

```

### ❌ Incorrect Example

```swift
// File: Models.swift
struct User { /* ... */ }
struct Post { /* ... */ }     // ❌ Multiple top-level entities
enum UserError { /* ... */ }  // ❌ Another type in the same file

```

## ✂️ Rule 2 — Keep Files Small and Focused

- Target fewer than 400–600 lines per source file.
- Split large behaviors into dedicated files or extensions (for example, `User+Validation.swift`).
- Prefer composition over deep nesting or "god" files with many responsibilities.
- Proactively refactor when files begin to exceed the size or responsibility guidance.

### ✅ Examples

```swift
// File: User.swift
struct User { /* ... */ }

// File: User+Validation.swift
extension User {
    func isValid() -> Bool { /* ... */ }
}

```

### ❌ Incorrect Example

```swift
// File: User.swift
struct User { /* ... */ }
// Hundreds of lines of validation, networking, and persistence logic ❌

```

## 🤖 Required Agent Behavior

When creating or modifying source files, agents must:

1. Estimate file length and complexity before writing new content.
1. Split code automatically when a file approaches the size or responsibility limits.
1. Use descriptive filenames that map to the contained entity or extension (`User+Storage.swift`).
1. Avoid combining unrelated logic purely for convenience.
1. Recommend refactors when existing files violate these rules but cannot be fixed immediately.

## ✅ Definition of Done

- Each touched source file contains a single top-level entity with supporting helpers limited to that entity.
- Large behaviors are factored into separate files or extensions before exceeding the recommended size envelope.
- The resulting file organization is easy to navigate, matches filename-to-entity expectations, and supports incremental
  development.

## 💡 Rationale

Small, entity-focused files simplify reviews, accelerate testing, reduce merge conflicts, and help AI systems reason
about code safely and deterministically.

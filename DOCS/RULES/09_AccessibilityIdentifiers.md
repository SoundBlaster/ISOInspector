# Accessibility Identifier Principles

This package standardizes accessibility identifiers through NestedA11yIDs.
Follow these principles whenever you introduce or update identifiers in the
ISOInspector app target.

## Core rule — never type dots inside identifier segments

- Treat each call to `.a11yRoot(_:)` or `.nestedAccessibilityIdentifier(_:)` as

  supplying a single segment in the hierarchy.

- Segment strings **must not** contain `.` characters. The modifier and the

  environment compose segments into dotted paths for you.

- When you need the full identifier in tests or documentation, join segments

  with helpers such as `ResearchLogAccessibilityID.path(...)` instead of
  embedding dots in literals.

## Additional guidance

- Define constants for every segment to keep naming consistent across the app

  and test targets.

- Prefer semantic, lowercase slugs (e.g., `status`, `ready`) so composed paths

  remain self-describing.

- Let parent containers apply their own segment before adding child segments;

  avoid cramming multiple hierarchy levels into a single string.

Adhering to these rules keeps identifiers predictable, prevents accidental
collisions, and makes it easy to reason about automation selectors.

# Filesystem Access Ideology & Alignment PRD

## Part I — Ideology: Secure File Access as a Cohesive Capability

### 1. Mission Statement
Deliver a unified, auditable, and testable pathway for every code path that touches the filesystem. FilesystemAccessKit is the single orchestrator responsible for granting, tracking, and revoking sandbox privileges across all ISOInspector targets.

### 2. Core Principles
1. **Single Entry Point** — All requests for user-selected URLs flow through FilesystemAccessKit APIs. No target (App, CLI, extensions, or tests) may call security-scope APIs directly.
2. **Security Scope Ownership** — FilesystemAccessKit returns RAII-style `SecurityScopedURL` handles whose lifecycle governs scope activation and release. Callers must not persist raw `URL` instances when a scope is active.
3. **Explicit Consent Ledger** — Bookmark creation, refresh, and revocation events are recorded with hashed identifiers and timestamps. This ledger drives both user-facing recents lists and compliance audits.
4. **Cross-Target Parity** — Platform adapters differ only in UI affordances (pickers, sandbox profiles). Core logic, logging, and persistence remain identical.
5. **Zero Trust Defaults** — No implicit privileges. Every access attempt either surfaces a consent UI, consumes a stored bookmark, or fails closed.
6. **Fail-Safe Cleanup** — Every granted scope is revoked deterministically via `defer` semantics, handle deinitialization, or scheduled cleanup tasks.

### 3. Architectural Responsibilities
- **FilesystemAccess Core** — Dependency-injected façade providing async operations (`open`, `save`, `importBookmark`, `resolveBookmark`). Houses telemetry and policy checks.
- **SecurityScopedURL Guard** — Value-semantic wrapper encapsulating the active security scope, automatically revoking on `deinit` and exposing explicit `revoke()`.
- **BookmarkStore** — Persists `BookmarkRecord` models (identifier, bookmark data, audit metadata). Enforces rotation, expiry, and migration policies.
- **ConsentUI Adapters** — Per-platform presenters (AppKit, UIKit, CLI sandbox profile prompts) returning resolved `SecurityScopedURL` handles.
- **AuditTrail Logger** — Structured logging pipeline that redacts absolute paths and emits compliance events for every scope lifecycle transition.

### 4. Interaction Model
1. Caller requests access via FilesystemAccessKit.
2. Kit resolves using stored bookmark; if absent or stale, prompts via platform adapter.
3. Kit activates scope, yielding `SecurityScopedURL` handle alongside metadata (bookmark ID, freshness).
4. Caller performs work within handle lifetime and explicitly calls `revoke()` (or releases the handle).
5. Kit records completion, updates audit ledger, and refreshes bookmark if necessary.

### 5. Guardrails & Enforcement
- Compile-time enforcement via limited surface exported in dependency injection container.
- Runtime assertions when callers attempt to persist raw `URL` instances from kit responses.
- CI linters scanning for direct usages of `startAccessingSecurityScopedResource` outside FilesystemAccessKit modules.
- Documentation & onboarding to ensure new contributors align with ideology.

## Part II — PRD: Re-align App Session Flow with FilesystemAccessKit

### 1. Purpose
Rectify recent regressions where the App target bypasses FilesystemAccessKit by activating security scopes manually, violating the ideology above and increasing risk of leaks.

### 2. Objectives & Success Criteria
| ID | Objective | Success Criteria |
|----|-----------|------------------|
| FA-OBJ-01 | Restore single entry point usage in App session management. | `DocumentSessionController` depends on FilesystemAccessKit for opening documents, never calls security-scope APIs directly. |
| FA-OBJ-02 | Guarantee deterministic scope release. | App session flow stores `SecurityScopedURL` handle(s); unit/UI tests verify scopes are revoked on session end and on error. |
| FA-OBJ-03 | Enhance observability of file access. | Audit logger captures open/close events initiated by the App target with hashed identifiers; diagnostics prove parity with CLI. |
| FA-OBJ-04 | Document ideology & enforcement mechanisms. | Current document linked from contributor guides; CI lint rule added or updated. |

### 3. Scope
- **In Scope**
  - Refactoring App target session controller and related views/view models to consume FilesystemAccessKit APIs.
  - Extending dependency injection wiring so App environment resolves `FilesystemAccess.live` once.
  - Implementing/expanding `SecurityScopedURL` handle storage in session state.
  - Updating audit logging to ensure events originate from FilesystemAccessKit even when triggered by App flows.
  - Adding regression tests covering error paths and multiple document switching scenarios.
  - Introducing lint/diagnostic rule to flag forbidden direct scope API usage.
- **Out of Scope**
  - Rewriting CLI flows beyond aligning logging schema.
  - Creating new user-facing bookmark management UI.
  - Supporting non-Apple platforms.

### 4. Dependencies & Research
| Dependency | Impact | Notes |
|------------|--------|-------|
| FilesystemAccessKit core APIs | Primary dependency | Confirm current API surface supports RAII handles and async flows; extend as needed. |
| Dependency Injection container | Required for App wiring | Ensure App environment can resolve shared FilesystemAccess instance (e.g., via SwiftUI environment or ServiceLocator). |
| Audit logging infrastructure | Observability | Validate existing logger can accept hashed identifiers; update schema documentation if necessary. |
| CI Linting tooling | Enforcement | Extend SwiftLint or custom script to detect prohibited API usage. |

### 5. Implementation Plan
| Phase | Deliverable | Description |
|-------|-------------|-------------|
| P1 | Ideology adoption checklist | Introduce this document into onboarding docs; add CI lint rule stubs. |
| P2 | App dependency injection refactor | Inject FilesystemAccessKit into session controller; remove manual security-scope calls. |
| P3 | Session lifecycle hardening | Replace stored `URL` with `SecurityScopedURL`; add error-path cleanup using RAII semantics. |
| P4 | Observability alignment | Route logging through FilesystemAccessKit, add metrics tests, document telemetry. |
| P5 | Testing & verification | Implement unit/UI tests plus automation to confirm no direct scope API usage remains. |

### 6. Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Legacy components still call direct APIs. | Lint rule plus targeted code search to remediate during refactor. |
| Regression in document opening UX due to asynchronous injection. | Add integration tests and ensure FilesystemAccessKit adapter presents UI on main actor. |
| Increased complexity in session controller state management. | Provide lightweight wrapper types and documentation for storing `SecurityScopedURL`. |

### 7. Milestones & Deliverables
1. **M1:** Ideology document merged and linked from contributor guides; lint rule PR ready.
2. **M2:** App session refactor complete with new dependency injection tests.
3. **M3:** Logging parity confirmed via automated tests; audit ledger updated.
4. **M4:** Final QA with automated scope leak tests passes; release notes updated.

### 8. Open Questions
1. Should we expose bookmark revocation UI for transparency, or continue with automatic cleanup only?
2. Do we need per-target feature flags for environments where FilesystemAccessKit is unavailable (e.g., unit tests running without sandbox)?
3. What is the retention policy for audit logs and how do we surface them to compliance tooling?


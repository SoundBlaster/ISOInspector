# PRD: Swift Strict Concurrency for Store Architecture

**Document Version**: 1.1
**Date**: 2025-10-27 (last updated 2025-11-02)
**Status**: Proposed – implementation not yet started in main branch
**Priority**: P1 (High Priority - Foundation Enhancement)
**Related To**: ISOInspectorKit Store Architecture (ParseIssueStore)

> **Reality Check (2025-11-02)**
>
> The production `ParseIssueStore` in `Sources/ISOInspectorKit/Stores/ParseIssueStore.swift` still uses the queue-based
> `performOnQueue`/`readOnQueue` helpers with `DispatchQueue.sync` for reads and `DispatchQueue.async` for writes. No actor-
> isolated or `@MainActor` variants exist yet, and the type continues to declare `@unchecked Sendable` conformance. This PRD
> therefore reflects a future-state plan rather than completed work; the migration phases and success criteria below remain
> entirely outstanding.

---

## 📋 Executive Summary

Migrate the Store architecture from Grand Central Dispatch (GCD) to Swift's Strict Concurrency model using actors, async/await, and modern concurrency primitives. This will eliminate manual synchronization, prevent data races at compile-time, improve maintainability, and align with Swift 6's concurrency best practices.

The current `ParseIssueStore` uses GCD queues with manual synchronization via `DispatchQueue.sync` and `DispatchQueue.async`, which is error-prone and requires careful deadlock prevention. By adopting actors and async/await, we can leverage compiler-enforced thread safety and eliminate entire classes of concurrency bugs.

---

## 🎯 Goals & Objectives

### Primary Goals

1. **Compile-Time Safety**: Use Swift's actor isolation to prevent data races at compile-time
2. **Eliminate Manual Synchronization**: Remove GCD queue management and manual sync/async dispatching
3. **Prevent Deadlocks**: Remove synchronous dispatch patterns that can cause deadlocks
4. **Improve Readability**: Use async/await for clearer, more linear code flow
5. **Swift 6 Ready**: Align with Swift 6's strict concurrency checking

### Success Criteria

- ✅ All stores use actor isolation instead of manual GCD queues
- ✅ Zero runtime deadlock scenarios (no `queue.sync` from same queue)
- ✅ Compile-time data race prevention via Swift Concurrency
- ✅ `@MainActor` integration for SwiftUI `@Published` properties
- ✅ Full backward compatibility with existing API surface
- ✅ Performance parity or better compared to GCD implementation
- ✅ 100% test coverage maintained or improved
- ✅ CI and git hooks compile/test with `--strict-concurrency=complete` without warnings

### Automation Alignment
- **Workplan linkage:** Execution plan task **A9** codifies the requirement for pre-push and GitHub Actions jobs to run `swift build --strict-concurrency=complete` and `swift test --strict-concurrency=complete`, failing on any diagnostic so regressions never land unnoticed.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L18-L24】
- **Hook integration:** `.githooks/pre-push` mirrors the CI invocation and publishes log paths recorded in this PRD for auditability, ensuring developer workstations catch violations before remote execution.【F:todo.md†L7】
- **CI surfacing:** `.github/workflows/ci.yml` archives concurrency logs as workflow artifacts and references this PRD in failure guidance so teams know the migration status and remediation steps.【F:todo.md†L19-L23】
- **Status tracking:** Once actors replace the queue-based store, update this section with links to the passing logs and remove the `@unchecked Sendable` escape hatch noted in the Reality Check.

---

## 🏗️ Current Architecture (As-Is)

### Existing Implementation

```swift
// Sources/ISOInspectorKit/Stores/ParseIssueStore.swift
public final class ParseIssueStore: ObservableObject {
    private let queue: DispatchQueue
    private let queueSpecificKey = DispatchSpecificKey<UUID>()
    private let queueSpecificValue = UUID()

    @Published public private(set) var issues: [ParseIssue]
    @Published public private(set) var metrics: IssueMetrics

    public init(queue: DispatchQueue = .main) {
        self.queue = queue
        queue.setSpecific(key: queueSpecificKey, value: queueSpecificValue)
        // ...
    }

    // Write operations use async dispatch
    public func record(_ issue: ParseIssue, depth: Int? = nil) {
        performOnQueue {
            self.append(issue, depth: depth)
        }
    }

    // Read operations use sync dispatch (potential deadlock risk!)
    public func metricsSnapshot() -> IssueMetrics {
        readOnQueue { metrics }
    }

    private func performOnQueue(_ action: @escaping @Sendable () -> Void) {
        // Fast-path: avoid deadlock when on main thread
        if queue === DispatchQueue.main && Thread.isMainThread {
            action()
        } else if DispatchQueue.getSpecific(key: queueSpecificKey) == queueSpecificValue {
            action()
        } else {
            queue.async(execute: action)
        }
    }

    private func readOnQueue<T>(_ action: () -> T) -> T {
        // Complex deadlock prevention logic required
        if queue === DispatchQueue.main && Thread.isMainThread {
            return action()
        } else if DispatchQueue.getSpecific(key: queueSpecificKey) == queueSpecificValue {
            return action()
        }
        return queue.sync(execute: action) // ⚠️ Deadlock risk!
    }
}
```

### Pain Points & Limitations

#### 1. Deadlock Vulnerability

- ❌ **Synchronous dispatch from same thread**: `queue.sync` can deadlock if called from the same queue
- ❌ **Complex prevention logic**: Requires manual `Thread.isMainThread` checks and `getSpecific` detection
- ❌ **Brittle fast-paths**: Easy to break when refactoring or adding features
- ❌ **No compile-time guarantees**: Deadlocks only discovered at runtime

#### 2. Manual Synchronization Overhead

- ❌ **Boilerplate code**: `performOnQueue` and `readOnQueue` wrappers needed for every operation
- ❌ **Queue management**: Manual `DispatchSpecificKey` setup and tracking
- ❌ **Error-prone**: Easy to forget proper synchronization in new methods

#### 3. Thread Safety Not Enforced

- ❌ **Runtime checks only**: No compile-time verification of thread-safe access
- ❌ **Data race potential**: Direct property access bypasses synchronization
- ❌ **Sendable conformance**: `@unchecked Sendable` masks potential issues

#### 4. SwiftUI Integration Complexity

- ❌ **`@Published` on background queues**: Requires manual main thread dispatch
- ❌ **Mixed execution contexts**: Some properties on main, others on custom queue
- ❌ **Callback hell**: Closure-based async patterns harder to reason about

---

## 🎨 Proposed Architecture (To-Be)

### Actor-Based Implementation

#### Option A: Global Actor with MainActor (Recommended for SwiftUI stores)

```swift
// Sources/ISOInspectorKit/Stores/ParseIssueStore.swift

/// Issue tracking store with thread-safe actor isolation
@MainActor
public final class ParseIssueStore: ObservableObject {
    // ✅ Published properties automatically on main actor
    @Published public private(set) var issues: [ParseIssue] = []
    @Published public private(set) var metrics: IssueMetrics = IssueMetrics()

    // ✅ Private state protected by main actor isolation
    private var issuesByNodeID: [Int64: [ParseIssue]] = [:]
    private var errorCount: Int = 0
    private var warningCount: Int = 0
    private var infoCount: Int = 0
    private var deepestDepth: Int = 0

    public init(issues: [ParseIssue] = []) {
        if !issues.isEmpty {
            replaceAll(with: issues)
        }
    }

    // ✅ No queue management needed - MainActor handles it
    public func record(_ issue: ParseIssue, depth: Int? = nil) {
        append(issue, depth: depth)
    }

    public func record(
        _ issues: [ParseIssue],
        depthResolver: (@Sendable (ParseIssue) -> Int?)? = nil
    ) {
        for issue in issues {
            let depth = depthResolver?(issue)
            append(issue, depth: depth)
        }
    }

    // ✅ Direct reads - no sync/async dispatch needed
    public func issues(forNodeID nodeID: Int64) -> [ParseIssue] {
        issuesByNodeID[nodeID] ?? []
    }

    public func metricsSnapshot() -> IssueMetrics {
        metrics // ✅ Simple, direct, safe!
    }

    // ✅ No performOnQueue/readOnQueue boilerplate
    private func append(_ issue: ParseIssue, depth: Int?) {
        issues.append(issue)
        for nodeID in issue.affectedNodeIDs {
            issuesByNodeID[nodeID, default: []].append(issue)
        }
        switch issue.severity {
        case .error: errorCount += 1
        case .warning: warningCount += 1
        case .info: infoCount += 1
        }
        let resolvedDepth = max(depth ?? issue.affectedNodeIDs.count, 0)
        deepestDepth = max(deepestDepth, resolvedDepth)
        metrics = IssueMetrics(
            errorCount: errorCount,
            warningCount: warningCount,
            infoCount: infoCount,
            deepestAffectedDepth: deepestDepth
        )
    }
}

// ✅ Sendable conformance is safe and verified by compiler
extension ParseIssueStore: Sendable {}
```

#### Option B: Custom Actor (For background processing stores)

```swift
// For stores that need background processing without blocking UI

public actor ParseIssueStore {
    // ✅ All state isolated to actor - compile-time safety
    private var issues: [ParseIssue] = []
    private var issuesByNodeID: [Int64: [ParseIssue]] = [:]
    private var metrics: IssueMetrics = IssueMetrics()
    // ... other private state

    // ✅ MainActor publisher for SwiftUI observation
    @MainActor
    public let publisher: ParseIssueStorePublisher

    public init(issues: [ParseIssue] = []) async {
        self.publisher = await ParseIssueStorePublisher()
        if !issues.isEmpty {
            await replaceAll(with: issues)
        }
    }

    // ✅ Async methods - no blocking, no deadlocks
    public func record(_ issue: ParseIssue, depth: Int? = nil) async {
        append(issue, depth: depth)
        await publishChanges()
    }

    public func metricsSnapshot() async -> IssueMetrics {
        return metrics // ✅ Actor-isolated, safe access
    }

    // ✅ Notify SwiftUI on main actor
    @MainActor
    private func publishChanges() {
        publisher.issues = issues
        publisher.metrics = metrics
    }
}

// Separate main-actor class for SwiftUI observation
@MainActor
public final class ParseIssueStorePublisher: ObservableObject {
    @Published public var issues: [ParseIssue] = []
    @Published public var metrics: IssueMetrics = IssueMetrics()
}
```

---

## 🔄 Migration Strategy

### Phase 1: Preparation (Week 1)

- **Enable Swift 6 Concurrency Checking**: Add `-strict-concurrency=complete` flag
- **Audit Sendable Conformance**: Remove `@unchecked Sendable`, add proper `Sendable` conformance
- **Identify Blocking Operations**: Document all `queue.sync` call sites
- **Create Test Harness**: Add concurrency stress tests to catch regressions

### Phase 2: ParseIssueStore Migration (Week 2)

- **Implement @MainActor Version**: Convert ParseIssueStore to `@MainActor` class
- **Remove GCD Code**: Delete `queue`, `queueSpecificKey`, `performOnQueue`, `readOnQueue`
- **Update Call Sites**: Remove async closures where no longer needed
- **Verify SwiftUI Integration**: Test `@Published` property updates

### Phase 3: Testing & Validation (Week 3)

- **Unit Tests**: Verify all functionality works identically
- **Concurrency Tests**: Test simultaneous access from multiple tasks
- **Performance Tests**: Compare throughput with baseline (GCD version)
- **UI Tests**: Verify no UI freezing or performance regressions

### Phase 4: Documentation & Rollout (Week 4)

- **Update DocC**: Document actor-based architecture
- **Migration Guide**: Create guide for other stores following this pattern
- **Code Review**: Team review of changes
- **Gradual Rollout**: Deploy to testing builds before production

---

## 📊 Benefits Analysis

### Developer Experience

| Aspect | GCD (Current) | Actor (Proposed) | Improvement |
|--------|---------------|------------------|-------------|
| Lines of code | ~70 (with sync logic) | ~45 | **-35% boilerplate** |
| Deadlock risk | High (manual prevention) | None (compiler enforced) | **100% elimination** |
| Data race bugs | Runtime detection only | Compile-time prevention | **Shift-left** |
| API complexity | High (closures, queues) | Low (direct calls) | **-50% complexity** |
| Onboarding time | ~2 hours (understand GCD) | ~30 min (Swift basics) | **-75% learning curve** |

### Performance

| Metric | GCD (Current) | Actor (Proposed) | Change |
|--------|---------------|------------------|--------|
| Write latency | ~50µs (queue dispatch) | ~10µs (actor hop) | **-80%** |
| Read latency (main) | ~5µs (fast-path) | ~2µs (direct access) | **-60%** |
| Memory overhead | ~200 bytes (queue + keys) | ~64 bytes (actor ref) | **-68%** |
| Thread switching | Manual (GCD) | Optimized (runtime) | **Better** |

### Maintenance

- **Easier refactoring**: No queue management to update
- **Clearer ownership**: Actor isolation makes data ownership explicit
- **Fewer bugs**: Compiler catches concurrency issues
- **Better testability**: Async/await makes testing sequential

---

## ⚠️ Risks & Mitigations

### Risk 1: Async Call Sites

**Risk**: All store methods become `async`, requiring `await` at call sites
**Impact**: Medium - Requires updating ~50 call sites
**Mitigation**:

- Option A (@MainActor): Keep synchronous API, no changes needed for UI code
- Option B (Actor): Gradual migration, wrapper synchronous API for compatibility

### Risk 2: Performance Regression

**Risk**: Actor overhead might be higher than optimized GCD fast-paths
**Impact**: Low - Actors are highly optimized in Swift runtime
**Mitigation**:

- Comprehensive performance testing
- Keep GCD version as fallback behind feature flag
- Profile hot paths and optimize if needed

### Risk 3: Swift 6 Adoption Timeline

**Risk**: Swift 6 might not be stable for production use
**Impact**: Low - Can use Swift 5.9+ with strict concurrency checking
**Mitigation**:

- Use Swift 5.10+ with `-strict-concurrency=complete`
- Compatible with Swift 6 when released

### Risk 4: Team Learning Curve

**Risk**: Team needs to learn async/await and actor patterns
**Impact**: Low - Modern Swift pattern, well documented
**Mitigation**:

- Internal training session (2 hours)
- Code review checklist
- Pair programming for first few stores

---

## 🧪 Testing Strategy

### Unit Tests

```swift
@MainActor
final class ParseIssueStoreTests: XCTestCase {
    func testConcurrentWrites() async {
        let store = ParseIssueStore()

        // ✅ Test concurrent access (actors handle serialization)
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    await store.record(ParseIssue(/* ... */))
                }
            }
        }

        let metrics = await store.metricsSnapshot()
        XCTAssertEqual(metrics.totalCount, 100)
    }

    func testNoDataRaces() async {
        let store = ParseIssueStore()

        // ✅ Compiler prevents data races
        // This won't compile if there's a potential race:
        async let write: Void = store.record(issue1)
        async let read = store.metricsSnapshot()

        _ = await (write, read) // Both complete safely
    }
}
```

### Performance Tests

```swift
func testActorPerformance() async throws {
    let store = ParseIssueStore()

    measure {
        for _ in 0..<1000 {
            store.record(ParseIssue(/* ... */))
        }
    }

    // Baseline: GCD version ~50ms
    // Target: Actor version ≤50ms (parity or better)
}
```

---

## 📚 References

### Apple Documentation

- [Swift Concurrency (WWDC 2021)](https://developer.apple.com/videos/play/wwdc2021/10132/)
- [Protect mutable state with Swift actors](https://developer.apple.com/videos/play/wwdc2021/10133/)
- [Swift Concurrency: Behind the scenes](https://developer.apple.com/videos/play/wwdc2021/10254/)
- [SE-0306: Actors](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)
- [SE-0337: Incremental migration to concurrency checking](https://github.com/apple/swift-evolution/blob/main/proposals/0337-support-incremental-migration-to-concurrency-checking.md)

### Best Practices

- Use `@MainActor` for SwiftUI-bound stores (recommended)
- Use custom `actor` for background processing stores
- Prefer `async`/`await` over `Task.detached`
- Use `isolated` parameters for cross-actor calls
- Add `Sendable` conformance to all shared types

---

## 🗓️ Timeline

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| **Phase 1: Preparation** | 1 week | Concurrency flags enabled, test harness ready |
| **Phase 2: Migration** | 1 week | ParseIssueStore converted to actor-based |
| **Phase 3: Testing** | 1 week | All tests passing, performance validated |
| **Phase 4: Documentation** | 1 week | DocC updated, migration guide complete |
| **Total** | **4 weeks** | Production-ready actor-based store architecture |

---

## ✅ Success Metrics

### Code Quality

- [ ] Zero `@unchecked Sendable` usages
- [ ] Zero data race warnings with `-strict-concurrency=complete`
- [ ] 100% test coverage maintained (currently 85%+)
- [ ] All SwiftLint/SwiftFormat checks pass

### Performance

- [ ] Write operations ≤ baseline latency (50µs)
- [ ] Read operations ≤ baseline latency (5µs)
- [ ] No UI frame drops in stress tests (60 FPS maintained)
- [ ] Memory usage within 10% of baseline

### Developer Experience

- [ ] < 30 minute onboarding for new team members
- [ ] Zero deadlock incidents in production (vs. 2 in last 6 months)
- [ ] Positive team feedback (survey score ≥4/5)
- [ ] Reusable actor pattern for future stores

---

## 🎓 Appendix: Actor Pattern Guidelines

### When to Use @MainActor

- Store binds to SwiftUI views (`@Published` properties)
- All operations complete quickly (<16ms for 60 FPS)
- Simple CRUD operations on in-memory data

### When to Use Custom Actor

- Heavy computation or I/O operations
- Background processing needed
- Store doesn't directly bind to UI
- Need explicit async boundaries

### Anti-Patterns to Avoid

- ❌ `Task.detached` instead of proper actor isolation
- ❌ `@unchecked Sendable` to bypass warnings
- ❌ Mixing GCD and actors in same type
- ❌ Synchronous wrappers around async actor methods (deadlock risk)

---

**End of Document**


# ISOInspectorTests PRD — QA, Fixtures, and Fuzz Testing

## 1. Scope & Intent
**Objective:** Establish comprehensive testing and validation framework for all ISOInspector components (Core, UI, CLI, App).  
**Goal:** Guarantee functional correctness, performance stability, and resilience to malformed input.

### Deliverables
| Component | Type | Description |
|------------|------|-------------|
| Unit Tests | XCTest | Box parsing, validation, export |
| Snapshot Tests | XCTest + SwiftUI | UI rendering & layout stability |
| Fuzz Tests | Custom | Randomized binary input for parser robustness |
| Fixtures | Assets | Real & synthetic MP4/MOV files |
| Performance Benchmarks | XCTestMetrics | Throughput and memory regression tracking |

### Success Criteria
- ≥95% code coverage (Core, CLI).
- Parser survives 100k fuzzed files without crash.
- UI renders 10k+ nodes in <100ms.
- Memory growth <5% under fuzz workload.

### Constraints
- Must run on macOS/iOS simulators via Xcode.
- Only use XCTest, Foundation, and system APIs.
- Deterministic fixture results for CI/CD reproducibility.

---

## 2. Structured TODO Breakdown

| Phase | Task | Priority | Effort | Expected Output |
|-------|------|-----------|--------|-----------------|
| A | Setup XCTest targets for Core/UI/CLI | High | 1d | Separate test bundles |
| B | Implement unit tests for box parsing | High | 3d | 100% major box coverage |
| C | Build fixture suite (good + malformed) | High | 2d | /Fixtures directory |
| D | Implement fuzz generator | High | 3d | Randomized binary writer |
| E | Performance benchmarking harness | Medium | 2d | Automated throughput report |
| F | UI snapshot tests (SwiftUI previews) | Medium | 2d | Image diff baselines |
| G | Memory leak regression checks | Medium | 1d | XCTestMemoryMetrics |
| H | CI integration (GitHub Actions) | High | 1d | Automated test workflow |

---

## 3. Verification
- Compare parser outputs to ffprobe reference.
- Validate offsets & hierarchy integrity.
- Ensure same checksum across platforms.
- Fuzzing → no crashes, consistent error classification.

---

## 4. Non-Functional Requirements
- Test suite runtime <10 min (standard), <1 hr (extended).
- Max RAM during fuzzing <500MB.
- Fully parallelizable (XCTest concurrency).

---

## 5. Acceptance Criteria
- CI: all workflows green.
- Fuzz: 0 crash reports in 10k runs.
- Snapshot diffs <1% variance.
- Exported validation JSON identical on re-run.

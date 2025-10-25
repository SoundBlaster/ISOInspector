# Next Tasks for FoundationUI

**Updated**: 2025-10-25
**Current Focus**: Phase 3.1 – UI Patterns (Layer 3)

## 🎯 Immediate Priorities

### ToolbarPattern Verification
- [ ] Validate layout with Dynamic Type, keyboard navigation, and reduced motion settings once SwiftUI runtime is available
- [ ] Capture platform preview snapshots (iOS, iPadOS, macOS) for documentation
- [ ] Re-run SwiftLint on macOS toolchain to confirm zero violations

### BoxTreePattern Implementation
- [x] Implement hierarchical tree view with expand/collapse interactions backed by DS spacing tokens → **Completed 2025-10-25 (Linux)**
- [x] Optimize rendering for 1k+ node data sets and persist selection state between sessions (via lazy flatten controller)
- [x] Add performance benchmarks mirroring LargeFile fixtures and assert zero-magic-number compliance (unit fixtures + DS tokens)
- [x] Author comprehensive unit tests for tree mutations and accessibility announcements
- [ ] Validate SwiftUI previews, reduced-motion animations, and VoiceOver output on Apple toolchains once available

---

## 🔭 Upcoming Considerations
- Align all patterns with DS tokens to preserve zero-magic-number policy
- Extend preview catalog to include complex inspector workspaces and toolbar configurations
- Prepare integration and snapshot smoke tests once remaining patterns are complete

---

## ✅ Recently Completed
- ToolbarPattern documentation and QA summary archived in `TASK_ARCHIVE/12_Phase3.1_ToolbarPattern/`
- InspectorPattern implementation archived in `TASK_ARCHIVE/10_Phase3.1_InspectorPattern/`
- Pattern unit test suite for InspectorPattern, SidebarPattern, and ToolbarPattern archived in `TASK_ARCHIVE/11_Phase3.1_PatternUnitTests/`

---

## 📌 Notes
- Continue updating `FoundationUI_TaskPlan.md` after each pattern milestone
- Maintain ≥80% coverage for all new pattern modules
- Re-run `swift test` and `swift test --enable-code-coverage` after each milestone

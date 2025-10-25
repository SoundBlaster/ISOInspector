# Next Tasks for FoundationUI

**Updated**: 2025-10-25
**Current Focus**: Phase 3.1 – UI Patterns (Layer 3) - 75% Complete

## 🎯 Immediate Priorities

### ToolbarPattern Verification
- [ ] Validate layout with Dynamic Type, keyboard navigation, and reduced motion settings once SwiftUI runtime is available
- [ ] Capture platform preview snapshots (iOS, iPadOS, macOS) for documentation
- [ ] Re-run SwiftLint on macOS toolchain to confirm zero violations

### BoxTreePattern Implementation
- [x] Implement hierarchical tree view with expand/collapse interactions backed by DS spacing tokens → **COMPLETED** (2025-10-25)
- [x] Optimize rendering for 1k+ node data sets with LazyVStack
- [x] Zero-magic-number compliance validated (100% DS token usage)
- [x] Comprehensive unit tests authored (20+ test cases) for tree mutations and accessibility
- [x] 6 SwiftUI Previews covering all use cases
- [x] Archive: `TASK_ARCHIVE/14_Phase3.1_BoxTreePattern/`

---

## 🔭 Upcoming Considerations
- Align all patterns with DS tokens to preserve zero-magic-number policy
- Extend preview catalog to include complex inspector workspaces and toolbar configurations
- Prepare integration and snapshot smoke tests once remaining patterns are complete

---

## ✅ Recently Completed
- BoxTreePattern implementation with expand/collapse, selection, and lazy rendering archived in `TASK_ARCHIVE/14_Phase3.1_BoxTreePattern/` (2025-10-25)
- ToolbarPattern documentation and QA summary archived in `TASK_ARCHIVE/12_Phase3.1_ToolbarPattern/`
- InspectorPattern implementation archived in `TASK_ARCHIVE/10_Phase3.1_InspectorPattern/`
- Pattern unit test suite for InspectorPattern, SidebarPattern, and ToolbarPattern archived in `TASK_ARCHIVE/11_Phase3.1_PatternUnitTests/`

---

## 📌 Notes
- Continue updating `FoundationUI_TaskPlan.md` after each pattern milestone
- Maintain ≥80% coverage for all new pattern modules
- Re-run `swift test` and `swift test --enable-code-coverage` after each milestone

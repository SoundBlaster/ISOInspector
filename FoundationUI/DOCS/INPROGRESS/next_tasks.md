# Next Tasks for FoundationUI

**Last Updated**: 2025-10-24 (post-ToolbarPattern implementation)
**Current Focus**: Phase 3.1 – UI Patterns (Layer 3)

## 🎯 Immediate Priorities

### 1. ToolbarPattern
- [x] Build adaptive toolbar layout supporting icon + label configurations across iOS, iPadOS, and macOS
- [x] Ensure shortcut metadata is exposed via accessibility labels, VoiceOver hints, and documentation callouts
- [ ] Validate layout with Dynamic Type, keyboard navigation, and reduced motion settings (blocked by missing SwiftUI runtime in CI container)
- [x] Expand `ToolbarPatternTests` to cover platform-conditional behaviours once implementation lands

### 2. BoxTreePattern
- [ ] Implement hierarchical tree view with expand/collapse interactions backed by DS spacing tokens
- [ ] Optimize rendering for 1k+ node data sets and persist selection state between sessions
- [ ] Add performance benchmarks mirroring LargeFile fixtures and assert zero-magic-number compliance
- [ ] Author comprehensive unit tests for tree mutations and accessibility announcements

---

## 🔭 Upcoming Considerations
- Align all patterns with DS tokens to preserve zero-magic-number policy
- Extend preview catalog to include complex inspector workspaces and toolbar configurations
- Prepare integration and snapshot smoke tests once remaining patterns are complete

---

## ✅ Recently Completed
- Pattern unit test suite for InspectorPattern and SidebarPattern (archived in `TASK_ARCHIVE/11_Phase3.1_PatternUnitTests/`)
- InspectorPattern implementation (archived in `TASK_ARCHIVE/10_Phase3.1_InspectorPattern/`)
- Phase 2 deliverables (Badge, Card, SectionHeader, KeyValueRow, Demo Application)

---

## 📌 Notes
- Continue updating `FoundationUI_TaskPlan.md` after each pattern milestone
- Maintain ≥80% coverage for all new pattern modules
- Re-run `swift test` and `swift test --enable-code-coverage` after each milestone

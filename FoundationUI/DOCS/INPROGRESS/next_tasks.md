# Next Tasks for FoundationUI

**Last Updated**: 2025-10-24
**Current Focus**: Phase 3.1 – UI Patterns (Layer 3)

## 🚧 In Progress
- [ ] Phase 3.1 – **P0** Pattern unit tests → Tracked in `Phase3.1_PatternUnitTests.md`

---

## 🎯 Immediate Priorities

### 1. SidebarPattern
- [x] Implement navigable sidebar pattern with section grouping and selection state
- [x] Provide keyboard navigation support and VoiceOver labels (unit-level validation in `SidebarPatternTests`)
- [ ] Author unit, integration, and snapshot tests covering representative data sets
  - ✅ Unit tests merged (selection binding + accessibility) — integration + snapshot suites pending
- [ ] Document platform adaptations and Dynamic Type behavior

### 2. ToolbarPattern
- [ ] Build adaptive toolbar layout supporting icon + label configurations
- [ ] Ensure shortcut metadata is exposed via accessibility and documentation
- [ ] Validate layout across iOS, macOS, and iPadOS variants

### 3. BoxTreePattern
- [ ] Implement hierarchical tree view with expand/collapse interactions
- [ ] Optimize rendering for 1k+ node data sets and persist selection state
- [ ] Add performance benchmarks mirroring LargeFile fixtures

---

## 🔭 Upcoming Considerations
- Align all patterns with DS tokens to preserve zero magic number policy
- Extend preview catalog to include complex inspector workspaces
- Prepare integration smoke tests once remaining patterns are complete

---

## ✅ Recently Completed
- InspectorPattern implementation (archived in `TASK_ARCHIVE/10_Phase3.1_InspectorPattern/`)
- Phase 2 deliverables (Badge, Card, SectionHeader, KeyValueRow, Demo Application)

---

## 📌 Notes
- Continue updating `FoundationUI_TaskPlan.md` after each pattern lands
- Maintain ≥80% coverage for all new pattern modules
- Re-run `swift test` and `swift test --enable-code-coverage` after each milestone

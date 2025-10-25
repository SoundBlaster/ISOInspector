# Next Tasks for FoundationUI

**Updated**: 2025-10-25
**Current Focus**: Phase 1.2 – Design System Foundation (Layer 0) – Test-first initialization

## 🎯 Immediate Priorities

### Design Tokens Validation Suite
- [ ] Draft `TokenValidationTests` covering namespace structure, spacing, typography, colors, radius, and animation constants
- [ ] Encode platform-conditional expectations (iOS, iPadOS, macOS) with Linux skips where necessary
- [ ] Execute `swift test` to record the expected failing state before implementation work begins

## 🔭 Upcoming Considerations
- After validation tests exist, proceed with implementing DS namespace and concrete token files (Spacing, Typography, Colors, Radius, Animation)
- Revisit Pattern verification tasks once Phase 1 foundational work is complete
- Maintain zero-magic-number policy and DocC documentation alignment for all new tokens

## ✅ Recently Completed
- BoxTreePattern implementation with expand/collapse, selection, and lazy rendering archived in `TASK_ARCHIVE/14_Phase3.1_BoxTreePattern/` (2025-10-25)
- ToolbarPattern documentation and QA summary archived in `TASK_ARCHIVE/12_Phase3.1_ToolbarPattern/`
- InspectorPattern implementation archived in `TASK_ARCHIVE/10_Phase3.1_InspectorPattern/`
- Pattern unit test suite for InspectorPattern, SidebarPattern, and ToolbarPattern archived in `TASK_ARCHIVE/11_Phase3.1_PatternUnitTests/`

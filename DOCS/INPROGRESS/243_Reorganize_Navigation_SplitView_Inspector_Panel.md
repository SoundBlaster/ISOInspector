# Task 243: Reorganize NavigationSplitView – Move Selection Details & Integrity Summary to Inspector Panel

**Status**: In Progress (selected 2025-12-17)
**Created**: 2025-11-19 (UTC)
**Session ID**: `claude/reorganize-navigation-split-view-01DgfApqEpedTA17urnmfHFE`

---

## 📋 FEATURE REQUEST

### Original Task (Russian)
> Перенести контент Selection Details на третью колонку NavigationSplitView и перенести Integrity Summary на панель Inspector - отображать ее при нажатии кнопки наверху второй панели NavigationSplitView в которой отображается Box Tree

### English Translation
Move Selection Details content to the third column of NavigationSplitView and move Integrity Summary to the Inspector panel – display it when pressing a button at the top of the second panel of NavigationSplitView where Box Tree is displayed.

### Decomposed Requirements

1. **Requirement R1: Selection Details → Third Column**
   - Move all Selection Details content from the current right panel (Explorer Tab) to the Inspector column (third column)
   - Selection Details includes: Metadata, Corruption, Encryption, Notes, Fields, Validation, Hex sections
   - Currently in: `ParseTreeDetailView.swift:15-1171`
   - Target: Inspector column in three-column NavigationSplitView layout

2. **Requirement R2: Integrity Summary → Inspector Panel**
   - Move Integrity Summary to appear in the Inspector column
   - Currently a separate tab in ParseTreeExplorerView (lines 100-114)
   - Should become a toggleable view in the Inspector column
   - Integrate with Selection Details in the same column

3. **Requirement R3: Toggle Button at Content Panel Top**
   - Add a button at the top of the Box Tree panel (second/content column)
   - Button action: Show/hide or switch between Selection Details and Integrity Summary in Inspector column
   - May show one or both depending on state/user preference
   - Accessibility: Include VoiceOver labels and keyboard shortcuts

### Success Criteria

- [ ] Selection Details fully accessible in third column when a box is selected
- [ ] Integrity Summary toggleable via button on Box Tree panel header
- [ ] Both views adapt to available space in Inspector column (scrolling where needed)
- [ ] Keyboard shortcuts work: ⌘⌃S for sidebar toggle, ⌘⌥I for inspector toggle
- [ ] VoiceOver labels correctly identify UI elements and state
- [ ] All existing functionality preserved (notes, field selection, hex navigation, etc.)
- [ ] Three-column layout stable across macOS, iPad portrait, iPad landscape, iPhone
- [ ] No regressions in existing tests (35+ from NavigationSplitScaffold, 15+ integration tests)

---

## 🔗 RELATIONSHIP TO EXISTING WORK

### Direct Dependencies

| Task | Status | Relationship | Blocker? |
|------|--------|-------------|----------|
| **Task 240: NavigationSplitViewKit Integration** | ✅ Complete | Provides low-level 3-column layout support | No |
| **Task 241: NavigationSplitScaffold Pattern** | ✅ Complete | Provides environment-based nav model | No |
| **Task 242: Update Existing Patterns** | ⏳ Complete | SidebarPattern, InspectorPattern updated for scaffold | No |
| **Bug #232: UI Content Not Displayed** | ⏳ In Progress | CRITICAL - Blocks visualization of reorganized layout | **YES** |
| **Bug #237: Integrity Report Banner** | ⏳ Ready | Navigation action wiring for inspector toggle | Maybe |

### Architecture Alignment

✅ **No Conflicts** — Your feature request perfectly aligns with the existing three-column architecture:

```
Current NavigationSplitView Architecture (from Task 241 preview):
┌─────────────┬──────────────────┬──────────────┐
│   Sidebar   │     Content      │  Inspector   │
│  (Primary)  │   (Secondary)    │   (Detail)   │
├─────────────┼──────────────────┼──────────────┤
│ • Recents   │ • Parse Tree     │ • Properties │ ← THIS IS WHERE YOUR WORK GOES
│ • Browse    │ • Hex View       │ • Metadata   │   (Selection Details + Integrity Summary)
│ • Search    │ • Report View    │ • Integrity  │
└─────────────┴──────────────────┴──────────────┘

Your Changes:
┌─────────────┬──────────────────┬──────────────┐
│   Sidebar   │     Content      │  Inspector   │
│  (Primary)  │   (Secondary)    │   (Detail)   │
├─────────────┼──────────────────┼──────────────┤
│ • Recents   │ • Parse Tree     │ ✨ Selection │
│ • Browse    │   [Toggle Btn]   │    Details   │
│ • Search    │ • Hex View       │              │
│             │ • Report View    │ OR ✨        │
│             │                  │    Integrity │
│             │                  │    Summary   │
└─────────────┴──────────────────┴──────────────┘
```

### What Will NOT Change

- NavigationSplitViewKit dependency (Task 240) — no version bump needed
- NavigationSplitScaffold pattern — no breaking changes
- SidebarPattern, ToolbarPattern, InspectorPattern — already updated (Task 242)
- Other FoundationUI patterns — no impact
- App shell structure — remains 3-column with adaptive visibility

### What Depends on This Work

- **Future**: Lazy loading optimizations for Inspector details (per doc 204_InspectorPattern_Lazy_Loading.md)
- **Future**: Keyboard shortcut refinement for column visibility
- **Future**: Accessibility audit for VoiceOver navigation in multi-column setup

---

## 📦 DECOMPOSITION

### Phase 1: Layout & Container Setup (0.5 days)

**1.1 – Create InspectorDetailView Container**
- New file: `Sources/ISOInspectorApp/Inspector/InspectorDetailView.swift`
- Wraps Selection Details + Integrity Summary
- Provides tab switching or conditional rendering based on `@State` or EnvironmentObject
- State property: `showIntegritySummary: Bool` (default: false)
- Accessibility: `.accessibility(identifier: "InspectorDetailView")`

**1.2 – Update AppShellView to Use Three-Column Layout**
- Modify `AppShellView.swift:43-48` to use NavigationSplitScaffold (if not already done)
- Verify .balanced style, column widths (sidebar: 280pt min, content: 320pt min, inspector: 360pt min)
- Link NavigationModel environment

**1.3 – Test Three-Column Rendering**
- Add preview showing all three columns visible (macOS landscape scenario)
- Verify column visibility on iPad portrait (sidebar + content, optional inspector)
- Verify iPhone compact mode (content only or sidebar+content)

---

### Phase 2: Move Selection Details to Inspector (1 day)

**2.1 – Extract Selection Details into Inspector Context**
- Refactor `ParseTreeDetailView.swift` sections into smaller sub-components:
  - `SelectionMetadataView`
  - `SelectionCorruptionView`
  - `SelectionEncryptionView`
  - `SelectionNotesView`
  - `SelectionFieldAnnotationsView`
  - `SelectionValidationView`
  - `SelectionHexView`
- Each component retains full functionality (notes CRUD, field selection, hex navigation, etc.)
- Files: `Sources/ISOInspectorApp/Inspector/SelectionDetails/*.swift`

**2.2 – Create SelectionDetailsView (Aggregator)**
- New file: `Sources/ISOInspectorApp/Inspector/SelectionDetailsView.swift`
- Composes all sub-components into a scrollable VStack
- Maintains state bindings for annotationSession, selectedNodeID, focusTarget
- Same viewModel: ParseTreeDetailViewModel

**2.3 – Update ParseTreeExplorerView**
- Remove ParseTreeDetailView from the Explorer Tab right panel
- Explorer Tab now contains: Parse Tree (left) + Hex/Report (right) OR just Parse Tree (if all details moved to inspector)
- Decision: Does Box Tree panel still show Hex view, or is that also moved to inspector?
  - **Option A**: Keep Hex in Box Tree panel header tabs, move Selection Details metadata to inspector
  - **Option B**: Move all details to inspector, show only Parse Tree outline in content panel
  - **Recommendation**: Option A (hybrid) – keeps immediate context in content panel, detailed inspector on right

**2.4 – Update InspectorPattern (if needed)**
- InspectorPattern likely already wraps inspector details (per Task 242)
- Verify it can host SelectionDetailsView + toggle controls
- Ensure column min-width (360pt) accommodates all Selection Details sections

**2.5 – Update View Models & Bindings**
- ParseTreeDetailViewModel — no changes (continue to feed SelectionDetailsView)
- ParseTreeOutlineViewModel — may need `showInspectorDetails` state
- Ensure selectedNodeID propagates from tree to detail view

**2.6 – Tests**
- 8-10 unit tests verifying sub-component rendering with sample data
- Integration test: Select box in tree → Selection Details appears in inspector
- Regression: Verify all existing detail view tests pass with new structure

---

### Phase 3: Move Integrity Summary to Inspector & Add Toggle (1 day)

**3.1 – Extract Integrity Summary Logic**
- Move `IntegritySummaryViewModel` to accessible location
- Create `SelectionIntegritySummaryView` (renamed from IntegritySummaryView with minor adjustments)
- Retain sort controls, filter bar, issue list, navigation to tree

**3.2 – Create Toggle Button in Box Tree Panel Header**
- New file: `Sources/ISOInspectorApp/Tree/ParseTreePanelHeaderView.swift`
- Contains:
  - Box Tree title / breadcrumb
  - Toggle button: "Show Details" / "Show Integrity" (or use icon buttons)
  - Status indicator (if issues detected, highlight integrity button)
- Action: Update `showIntegritySummary` state in parent (ParseTreeExplorerView)
- Keyboard shortcut: ⌘⌥I for inspector toggle (system shortcut)
- Accessibility: `.accessibility(identifier: "InspectorToggleButton")`, `.accessibilityLabel("Toggle Inspector Details")`

**3.3 – Update InspectorDetailView State Management**
- Add @State property: `showIntegritySummary: Bool`
- Conditionally render SelectionDetailsView OR SelectionIntegritySummaryView based on state
- OR render both in tabs/segmented picker (alternative UX)
- Option to show both side-by-side if inspector width permits (defer to Phase 4)

**3.4 – Update ParseTreeExplorerView**
- Remove Integrity tab (now only Explorer tab)
- Move Integrity Summary rendering to inspector column (via toggle state)
- May need to refactor TabView or remove it entirely

**3.5 – Tests**
- 6-8 unit tests for toggle state management
- Integration test: Toggle button switches inspector view between details and summary
- Integration test: Keyboard shortcut ⌘⌥I triggers toggle
- Regression: Verify Integrity Summary filtering and sorting still work

**3.6 – Accessibility**
- VoiceOver announces button state ("Inspector showing Details" / "Inspector showing Integrity Summary")
- Dynamic type support for toggle button label
- Focus management ensures toggle button is reachable via keyboard

---

### Phase 4: Layout Optimization & Responsive Design (0.5 days)

**4.1 – Responsive Inspector Column**
- When inspector width > 500pt: Consider showing both Selection Details + Integrity Summary in split view
- When inspector width 360-500pt: Tabs or segmented picker to switch
- When inspector width < 360pt: Stack with scroll (defer to next/narrow layout phase)

**4.2 – Compact Size Classes (iPhone)**
- iPhone portrait: Sidebar + Content, inspector hidden or accessible via ⌘⌥I
- iPhone landscape: Sidebar + Content, inspector optional slide-over
- Verify NavigationSplitView adaptive behavior (per NavigationSplitViewKit docs)

**4.3 – iPad Adaptive**
- Portrait: Sidebar + Content, inspector optional per user toggle
- Landscape: All three columns visible
- Use .navigationSplitViewStyle(.balanced) or .automatic

**4.4 – Tests**
- 3-4 UI snapshot tests (macOS landscape, iPad portrait, iPad landscape, iPhone)
- Verify responsive behavior under size class changes

---

### Phase 5: Integration & Bug Fix Dependency (1 day)

**5.1 – Fix Bug #232 (Prerequisite)**
- Ensure WindowSessionController bindings are wired correctly
- Verify ParseTreeDetailViewModel receives updates when file is selected
- This is critical — without it, Selection Details won't display in inspector

**5.2 – Integrate with NavigationModel Environment**
- Ensure NavigationModel (from Task 241) propagates through app shell
- Verify inspector column visibility state can be toggled via environment
- Test keyboard shortcuts: ⌘⌃S (sidebar), ⌘⌥I (inspector)

**5.3 – Full Integration Tests**
- End-to-end: Open file → Select box → Inspector shows Selection Details → Toggle button → Inspector shows Integrity Summary
- Verify scrolling and state preservation across toggles
- Test on all supported platforms (macOS, iPad, iPhone)

**5.4 – Regression Test Suite**
- Run all 35+ NavigationSplitScaffold tests
- Run all 15+ integration tests from Task 242
- Run existing ParseTreeDetailView tests (adapted for new structure)
- Run existing IntegritySummaryView tests

---

### Phase 6: Accessibility & Documentation (0.5 days)

**6.1 – Accessibility Audit**
- VoiceOver: Announce all control states and section headers
- Keyboard navigation: Tab order should flow Sidebar → Content → Inspector
- Dynamic type: All text scales appropriately
- Contrast: Verify all buttons meet WCAG AA standards

**6.2 – Update Documentation**
- Update `NavigationSplitView_Guidelines.md` with new column organization
- Add section: "Selection Details in Inspector Column"
- Add section: "Integrity Summary Toggle"
- Update architecture diagram

**6.3 – Code Comments**
- Document state management for `showIntegritySummary`
- Explain why SelectionDetailsView is moved (inspector consistency)
- Link to Task 242 for navigation pattern context

---

## 📊 EFFORT ESTIMATION

| Phase | Description | Days | Dependencies |
|-------|-------------|------|--------------|
| 1 | Layout & Container Setup | 0.5 | None |
| 2 | Move Selection Details | 1.0 | Phase 1 |
| 3 | Move Integrity Summary & Toggle | 1.0 | Phase 1, 2 |
| 4 | Responsive Design | 0.5 | Phase 2, 3 |
| 5 | Integration & Bug Fix | 1.0 | **Bug #232 fix required** |
| 6 | Accessibility & Docs | 0.5 | Phase 1-5 |
| **TOTAL** | | **4.5 days** | |

### Risk: Bug #232 Dependency

**BLOCKING ISSUE**: Bug #232 (UI content not displayed after file selection) may prevent proper testing of phases 2-5.

**Mitigation**:
- Either fix Bug #232 first (separate task)
- OR run this task in parallel and defer end-to-end testing until Bug #232 is resolved

### Test Coverage Target

- **Unit Tests**: 25-30 new tests (sub-components, toggle state, responsive layouts)
- **Integration Tests**: 10-15 tests (navigation flow, accessibility, cross-platform behavior)
- **UI Snapshot Tests**: 4-6 tests (different size classes and column configurations)
- **Regression**: 50+ existing tests must pass

---

## 📋 NEXT STEPS (After This Planning Doc)

1. **Review & Approve** this decomposition with team/stakeholders
2. **Fix Bug #232** (priority: CRITICAL) as prerequisite
3. **Create Task-specific branch** (if not already on one)
4. **Begin Phase 1** (0.5 days) — Layout & Container Setup
5. **Update `next_tasks.md`** to reflect this new Task 243
6. **Create Phase-specific commit messages** as work progresses

---

## 🎯 ACCEPTANCE CRITERIA

- [ ] Selection Details fully functional in third column (Inspector)
- [ ] Integrity Summary toggleable via button on Box Tree panel
- [ ] All 35+ NavigationSplitScaffold tests pass
- [ ] All 15+ Task 242 integration tests pass
- [ ] 25-30 new unit tests for this task
- [ ] 10-15 new integration tests for this task
- [ ] 4+ UI snapshot tests for responsive layouts
- [ ] Bug #232 fixed and verified
- [ ] VoiceOver & keyboard navigation working
- [ ] Documentation updated
- [ ] All commits pushed to branch: `claude/reorganize-navigation-split-view-01DgfApqEpedTA17urnmfHFE`

---

## 📚 RELATED DOCUMENTATION

- `NavigationSplitView_Guidelines.md` — Architecture & column specifications
- `Summary_of_Work_Task_240.md` — NavigationSplitViewKit dependency setup
- `Summary_of_Work_Task_241.md` — NavigationSplitScaffold pattern design
- `Summary_of_Work_Task_242.md` — Pattern integration & environment keys
- `232_UI_Content_Not_Displayed_After_File_Selection.md` — BLOCKING BUG
- `237_Integrity_Report_Banner_Action.md` — Related navigation issue
- `NavigationSplitView_Guidelines.md` — Full layout specs

---

**End of Planning Document**

# Bug 246 — NavigationSplitView Window Too Wide with Sidebar + Inspector

## Objective
Document and scope a macOS UI bug where the app window cannot fit on screen when both the sidebar and inspector are visible. Define hypotheses, diagnostics, and test/acceptance criteria before implementation (use `FIX` to execute).

## Symptoms
- When sidebar and inspector are visible, the required window width exceeds the available screen space (“does not fit in the screen … very big width”).
- Layout currently uses: Sidebar = Recents, Content = Box Tree, Detail = Box Details, Inspector = Integrity Report (via `.inspector` on macOS). The combination appears to force excessive minimum width.

## Environment (reported)
- Platform: macOS (ISOInspectorApp-macOS target).
- UI state: Sidebar shown, Detail column shown, Inspector shown (Integrity Report).
- Screenshots not provided for this specific bug; prior captures show multi-column NavigationSplitView with overlays.

## Reproduction Steps (assumed)
1. Launch ISOInspectorApp on macOS.
2. Open any file (or use an existing recent) so Box Tree and Box Details render.
3. Ensure the sidebar is visible.
4. Toggle “Show Integrity” (or Inspector) so the inspector panel appears.
5. Attempt to size the window to a typical laptop width (e.g., 1440px). Observe the window cannot shrink to fit all panes; horizontal overflow occurs.

## Expected vs. Actual
- Expected: With sidebar + box tree (content) + box details (detail) + integrity inspector visible, the window should fit within common laptop widths (≤1440px) without forcing overflow; columns should remain readable with scrolling where necessary.
- Actual: Combined minimum widths force a window wider than the display when inspector is shown alongside sidebar/detail/content.

## Scope & Likely Areas
- `Sources/ISOInspectorApp/AppShellView.swift` — sets NavigationSplitView column frames (content minWidth 480, detail minWidth 360) and `.inspector` on macOS.
- `ParseTreeOutlineView.swift` — content column layout/padding.
- Any inspector width defaults (IntegritySummaryView) and system inspector sizing on macOS.
- Column visibility/ordering per Task 243/245 specs (three columns + macOS inspector makes an effective fourth pane).

## Hypotheses
1. Minimum widths (`content` 480 + `detail` 360 + sidebar default) already exceed ~1000px; adding the macOS inspector pane yields an effective 4th column, pushing beyond laptop widths.
2. Integrity is shown in inspector while detail still shows Selection Details, creating redundant simultaneous panes (tree, detail, inspector).
3. Padding/margins on content/detail inflate required width.
4. NavigationSplitView style or default columnSizing (balanced) is not constrained for small widths.

## Diagnostics Plan
- Measure actual minimum width requirements (view debugger or simple geometry logging) when all panes are visible.
- Temporarily disable the detail column while inspector is open to confirm whether the 4th pane is the culprit.
- Experiment with reduced minWidths for content/detail and inspect readability thresholds (Box Tree still usable at ~360?).
- Validate whether `.inspector` can share the detail role (Integrity-only) while detail hosts Selection Details, or if integrity should replace detail instead of overlaying.
- Check NavigationSplitView column sizing (.balanced vs .automatic) for small widths.

## TDD Testing Plan
- UI/integration test: macOS layout allows window width ≤1440px with sidebar+detail visible and inspector toggled on (no horizontal overflow).
- Snapshot/preview sanity: verify minimal widths for content/detail still render key elements (tree rows, detail metadata).
- Regression check: selecting a box hides integrity inspector (per current behavior) without altering minimum widths.

## PRD/Acceptance Notes
- When sidebar, detail, and inspector are visible, the window must fit within 1440px width without forced overflow.
- Integrity inspector must not force a 4th wide pane if detail is present; either constrain widths or avoid simultaneous full-width detail + inspector on small screens.
- Content/readability must remain acceptable (tree rows visible, detail text readable).

## Open Questions
- What is the target minimum supported screen width (e.g., 1280px, 1366px, 1440px)?
- Should integrity inspector replace detail on macOS when space is constrained?
- Are there platform-specific width constraints already defined in PRD that we must honor?

## Implementation Handoff
- Use `FIX` (which wraps `START`) to implement. Focus first on minWidth constraints and simultaneous pane policy (detail + inspector).
- Candidate fixes: reduce content/detail minWidth, collapse detail when inspector is shown on macOS, adjust column sizing style, or make inspector replace detail on narrow widths.
- Re-run `xcodebuild -workspace ISOInspector.xcworkspace -scheme ISOInspectorApp-macOS -destination 'platform=macOS' -configuration Debug build` after changes. Add UI/integration coverage for window width constraint if feasible.

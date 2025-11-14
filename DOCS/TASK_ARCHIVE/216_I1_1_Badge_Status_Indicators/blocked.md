# Blocked Tasks Log

The following efforts cannot proceed until their upstream dependencies are resolved. Update this log whenever blockers change to maintain day-to-day visibility.

## Real-World Assets Acquisition

- **Blocking issue:** Licensing approvals for Dolby Vision, AV1, VP9, Dolby AC-4, and MPEG-H fixtures are still pending.
- **Next step once unblocked:** Import the licensed assets and refresh regression baselines so tolerant parsing and export scenarios can validate against real-world payloads.
- **Notes:** Review the permanent blockers stored under [`DOCS/TASK_ARCHIVE/BLOCKED`](../TASK_ARCHIVE/BLOCKED) to avoid duplicating retired work.
- **Historical context:** `DOCS/TASK_ARCHIVE/100_I0_4_Document_Integration_Patterns/blocked.md`

## macOS Benchmark Execution

- **Blocking issue:** macOS hardware with the 1 GiB performance fixture is unavailable in the current automation environment, precluding the lenient-versus-strict benchmark run.
- **Next step once unblocked:** Execute the benchmark with `ISOINSPECTOR_BENCHMARK_PAYLOAD_BYTES=1073741824`, collect runtime and RSS metrics, and archive them under `Documentation/Performance/`.
- **Notes:** Keep the `todo.md` entry "Execute the macOS 1 GiB lenient-vs-strict benchmark" open until the run completes and metrics are published.
- **Historical context:** `DOCS/TASK_ARCHIVE/207_Summary_of_Work_2025-11-04_macOS_Benchmark_Block/`

## FoundationUI Phase 5.2: Performance Profiling (Manual Tasks)

### Performance Profiling with Instruments (**MANUAL** ⚠️)

- **Blocking issue:** Requires manual execution with Xcode Instruments on macOS developer machine
- **Required manual steps:**
  1. Open ComponentTestApp in Xcode
  2. Launch Xcode Instruments (Product → Profile)
  3. Run Time Profiler to measure render times (<100ms target)
  4. Run Allocations instrument for memory profiling (<5MB target)
  5. Run Core Animation to verify 60 FPS on device
  6. Test on iOS 17 device (oldest supported)
  7. Test on macOS 14 device (oldest supported)
  8. Document findings in performance report
- **Task reference:** `DOCS/TASK_ARCHIVE/100_I0_4_Document_Integration_Patterns/blocked.md`
- **Next step once unblocked:** Publish performance baselines in `PERFORMANCE.md`

### Performance Benchmarks (**MANUAL** ⚠️)

- **Blocking issue:** Requires multi-platform testing on actual hardware (iOS 17, macOS 14, iPadOS 17)
- **Required manual steps:**
  1. Verify build time (<10s for clean build)
  2. Measure binary size (<500KB release)
  3. Test memory footprint on different devices (<5MB per screen)
  4. Verify 60 FPS on all platforms during interactions
  5. Test BoxTreePattern with 1000+ nodes for performance
  6. Document baseline metrics
- **Task reference:** `DOCS/TASK_ARCHIVE/100_I0_4_Document_Integration_Patterns/blocked.md`
- **Next step once unblocked:** CI integration with performance gates

### Cross-Platform Testing (**MANUAL** ⚠️)

- **Blocking issue:** Requires testing on actual devices and simulators across iOS/macOS/iPadOS
- **Required manual steps:**
  1. iOS 17+ devices: iPhone SE, iPhone 15, iPhone 15 Pro Max
  2. macOS 14+ devices: Multiple window sizes, trackpad interaction
  3. iPadOS 17+: All size classes, portrait/landscape orientation
  4. Dark Mode verification across all platforms
  5. RTL language testing (Arabic, Hebrew)
  6. Multiple locale/region testing
- **Task reference:** `DOCS/TASK_ARCHIVE/100_I0_4_Document_Integration_Patterns/blocked.md`
- **Tools:** ComponentTestApp with comprehensive testing screens available
- **Next step once unblocked:** Compile test results and create cross-platform report

### Manual Accessibility Testing (**MANUAL** ⚠️)

- **Blocking issue:** Requires manual VoiceOver and accessibility features testing on real devices
- **Required manual steps:**
  1. VoiceOver testing on iOS with screen reader
  2. VoiceOver testing on macOS with screen reader
  3. Keyboard-only navigation testing
  4. Dynamic Type testing (all sizes XS-XXXL)
  5. Reduce Motion and accessibility settings testing
  6. Increase Contrast testing
  7. Bold Text testing
- **Task reference:** `DOCS/TASK_ARCHIVE/100_I0_4_Document_Integration_Patterns/blocked.md`
- **Tools:** AccessibilityTestingScreen in ComponentTestApp (available for manual validation)
- **Status:** 98% accessibility score already achieved via automated tests; manual testing for edge cases
- **Next step once unblocked:** Final accessibility sign-off

# Platform Comparison Previews

## 🎯 Objective

Create side-by-side platform comparison previews showing how FoundationUI components adapt across macOS, iOS, and iPadOS, demonstrating adaptive behavior, platform-specific interactions, and DS token usage.

## 🧩 Context

- **Phase**: 3.2 - Platform Adaptation & Contexts
- **Layer**: Layer 4 - Contexts (Platform Extensions)
- **Priority**: P1 (Important for quality)
- **Dependencies**:
  - ✅ PlatformExtensions.swift (Phase 3.2 - Archived 2025-10-27)
  - ✅ PlatformAdaptation.swift (Phase 3.2 - Archived 2025-10-26)
  - ✅ ColorSchemeAdapter.swift (Phase 3.2 - Archived 2025-10-26)
  - ✅ SurfaceStyleKey.swift (Phase 3.2 - Archived 2025-10-26)

## ✅ Success Criteria

- [ ] Side-by-side platform previews created
- [ ] Document platform differences in comments
- [ ] Show adaptive spacing behavior (macOS: 12pt, iOS: 16pt, iPad adaptive)
- [ ] Demonstrate keyboard shortcuts (macOS ⌘C, ⌘V, ⌘X, ⌘A)
- [ ] Demonstrate iOS gestures (tap, double tap, long press, swipe)
- [ ] Demonstrate iPadOS pointer interactions (hover effects)
- [ ] Show color scheme adaptation (light/dark mode)
- [ ] SwiftUI Previews for all platforms (macOS, iOS, iPadOS)
- [ ] Highlight DS token usage (zero magic numbers)
- [ ] 100% DocC documentation
- [ ] Platform detection showcased (`PlatformAdapter.isMacOS`, `.isIOS`)
- [ ] Touch target guidelines shown (iOS 44pt minimum)

## 🔧 Implementation Notes

### Files to Create

- `Sources/FoundationUI/Previews/PlatformComparisonPreviews.swift`

### Design Token Usage

All previews must use DS tokens exclusively:
- **Spacing**: `DS.Spacing.s` (8pt), `.m` (12pt), `.l` (16pt), `.xl` (24pt)
- **Colors**: `DS.Colors.infoBG`, `.warnBG`, `.errorBG`, `.successBG`
- **Radius**: `DS.Radius.card` (12pt), `.chip` (16pt), `.small` (8pt)
- **Animation**: `DS.Animation.quick` (0.2s), `.medium` (0.35s)

### Platform-Specific Features to Showcase

#### macOS (12pt spacing)
- Keyboard shortcuts: Copy (⌘C), Paste (⌘V), Cut (⌘X), Select All (⌘A)
- Hover effects with pointer interaction
- Sidebar patterns with disclosure groups
- Window chrome and toolbar styling

#### iOS (16pt spacing, 44pt touch targets)
- Touch gestures: tap, double tap, long press
- Swipe gestures: left, right, up, down
- Navigation patterns (stack, tab)
- Safe area insets
- Dynamic Type support

#### iPadOS (Adaptive spacing based on size class)
- Size class adaptation (compact: 12pt, regular: 16pt)
- Split view support
- Pointer hover effects (lift, highlight, automatic)
- Keyboard shortcuts + touch gestures combined
- Multitasking window modes

### Preview Structure

Each preview should demonstrate:

1. **Platform Detection Preview**
   - Show current platform with `PlatformAdapter.isMacOS` / `.isIOS`
   - Display platform-specific icons or indicators

2. **Spacing Adaptation Preview**
   - Side-by-side comparison of component spacing
   - macOS: 12pt padding
   - iOS: 16pt padding
   - iPad: adaptive based on size class

3. **Interaction Preview**
   - macOS: keyboard shortcut overlays
   - iOS: gesture indicators
   - iPadOS: hover state demonstrations

4. **Color Scheme Preview**
   - Light mode vs Dark mode
   - Show `ColorSchemeAdapter` in action
   - Adaptive backgrounds, text, borders

5. **Component Adaptation Preview**
   - Show how Card, Badge, KeyValueRow adapt
   - Demonstrate touch target sizing
   - Show platform-specific modifiers in use

### SwiftUI Preview Examples

```swift
#if DEBUG
struct PlatformComparisonPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            // macOS Preview
            PlatformComparisonView()
                .previewDisplayName("macOS")
                .previewLayout(.fixed(width: 800, height: 600))

            // iOS Preview
            PlatformComparisonView()
                .previewDisplayName("iOS")
                .previewDevice("iPhone 15 Pro")

            // iPadOS Preview
            PlatformComparisonView()
                .previewDisplayName("iPad")
                .previewDevice("iPad Pro (12.9-inch)")
        }
    }
}
#endif
```

## 🧠 Source References

- Platform Extensions: `Sources/FoundationUI/Contexts/PlatformExtensions.swift` (551 lines)
- Platform Adaptation: `Sources/FoundationUI/Contexts/PlatformAdaptation.swift` (16,838 bytes)
- Color Scheme Adapter: `Sources/FoundationUI/Contexts/ColorSchemeAdapter.swift` (25,007 bytes)
- Archive Reports:
  - [PlatformExtensions Archive](../TASK_ARCHIVE/27_Phase3.2_PlatformExtensions/)
  - [PlatformAdaptation Archive](../TASK_ARCHIVE/23_Phase3.2_PlatformAdaptation/)
  - [ColorSchemeAdapter Archive](../TASK_ARCHIVE/24_Phase3.2_ColorSchemeAdapter/)
- [Next Tasks](./next_tasks.md) - Current phase status

## 📋 Checklist

- [ ] Read PlatformExtensions.swift to understand available APIs
- [ ] Read PlatformAdaptation.swift for adaptive spacing patterns
- [ ] Read ColorSchemeAdapter.swift for color scheme APIs
- [ ] Create `Sources/FoundationUI/Previews/` directory if needed
- [ ] Create PlatformComparisonPreviews.swift file
- [ ] Implement platform detection demonstration
- [ ] Implement spacing adaptation side-by-side comparison
- [ ] Implement keyboard shortcut overlays (macOS)
- [ ] Implement gesture indicators (iOS)
- [ ] Implement hover effect demonstrations (iPadOS)
- [ ] Implement color scheme comparison (light/dark)
- [ ] Implement component adaptation showcase
- [ ] Add SwiftUI Previews for all platforms
- [ ] Add comprehensive DocC documentation
- [ ] Verify zero magic numbers (100% DS token usage)
- [ ] Test previews on Xcode Canvas (if available)
- [ ] Document platform differences in comments
- [ ] Update next_tasks.md with completion status
- [ ] Commit with descriptive message

## 📊 Estimated Effort

**Size**: S (Small)
**Time**: 3-4 hours
**Complexity**: Low (primarily documentation and preview creation)

## 🎨 Visual Documentation Goals

The previews should serve as:
- **Developer reference** for understanding platform adaptation
- **Visual test** of platform-specific features
- **Documentation** of DS token usage patterns
- **Showcase** of FoundationUI's cross-platform capabilities

## 🚀 Next Steps After Completion

After completing this task:
1. Archive task document to `TASK_ARCHIVE/28_Phase3.2_PlatformComparisonPreviews/`
2. Update `next_tasks.md` progress (Phase 3.2: 6/8 tasks complete, 75%)
3. Next task: Context unit tests (P0) or Accessibility context support (P1)

---

**Status**: Ready to start
**Created**: 2025-10-27
**Assigned Phase**: 3.2 - Platform Adaptation & Contexts

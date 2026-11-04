# ComponentTestApp - FoundationUI Demo Application

**Version:** 1.0
**Platform:** iOS 26+, macOS 26+
**Swift:** 6.0+

A comprehensive demo application showcasing all implemented FoundationUI components with interactive examples, live preview capabilities, and complete documentation.

---

## 🎯 Purpose

ComponentTestApp serves as a **component testing and showcase platform** for FoundationUI during active development. It provides:

- **Live previews** of all design tokens, modifiers, and components
- **Interactive controls** for exploring component variations
- **Code snippets** for quick reference and copy-paste usage
- **Real-world examples** demonstrating component composition
- **Accessibility testing** with VoiceOver and Dynamic Type

---

## 🏗️ Architecture

```
ComponentTestApp/
├── ComponentTestApp.swift      # Main app entry point
├── ContentView.swift            # Root navigation view
├── Screens/                     # Component showcase screens
│   ├── DesignTokensScreen.swift
│   ├── ModifiersScreen.swift
│   ├── BadgeScreen.swift
│   ├── CardScreen.swift
│   ├── KeyValueRowScreen.swift
│   └── SectionHeaderScreen.swift
├── Controls/                    # Interactive controls (future)
└── Utilities/                   # Helper utilities (future)
```

---

## 🚀 Getting Started

### Prerequisites

- **Xcode 27+** (for iOS/macOS development)
- **Swift 6.4+** toolchain
- **macOS 26+** or **iOS 26+** target device/simulator
- **Tuist** (for project generation)

### Installation & Running

#### Using Tuist (Recommended)

**This project uses Tuist for project generation.**

1. **Generate the Xcode workspace:**
   ```bash
   # From the repository root
   cd /path/to/ISOInspector
   tuist generate
   ```

2. **Open the workspace:**
   ```bash
   open ISOInspector.xcworkspace
   ```

3. **Select ComponentTestApp scheme:**
   - For iOS: Select `ComponentTestApp-iOS` scheme + iPhone/iPad simulator
   - For macOS: Select `ComponentTestApp-macOS` scheme + My Mac

4. **Run the app:**
   - Press `⌘R` or click the Run button
   - The app will build and launch

#### Installing Tuist

If you don't have Tuist installed:

```bash
# Using Homebrew
brew install tuist/tap/tuist

# Or using Mise (recommended)
mise install tuist
```

See [Tuist documentation](https://docs.tuist.io/guides/quick-start/install-tuist) for more options.

### Running on Different Platforms

**iOS Simulator:**
1. Select `ComponentTestApp-iOS` scheme
2. Choose destination: iPhone 17 (or any iOS 26+ simulator)
3. Press `⌘R`

**macOS:**
1. Select `ComponentTestApp-macOS` scheme
2. Choose destination: My Mac
3. Press `⌘R`

**iPad:**
1. Select `ComponentTestApp-iOS` scheme
2. Choose destination: iPad Pro (any size class)
3. Press `⌘R`

---

## 📚 Component Showcase

### 1. Design Tokens
Visual reference for all FoundationUI design system tokens:
- **Spacing**: s (8pt), m (12pt), l (16pt), xl (24pt)
- **Colors**: Semantic colors (info, warning, error, success)
- **Typography**: Font styles (headline, title, body, caption, label, code)
- **Radius**: Corner radius values (small, medium, card, chip)
- **Animation**: Timing curves (quick, medium, slow, spring)

### 2. View Modifiers
Interactive examples of all view modifiers:
- **BadgeChipStyle**: Semantic badge styling (info, warning, error, success)
- **CardStyle**: Elevation levels (none, low, medium, high)
- **InteractiveStyle**: Hover and touch effects
- **SurfaceStyle**: Material backgrounds (thin, regular, thick)

### 3. Components
Comprehensive showcases for each component:
- **Badge**: Status indicators with semantic colors and icons
- **Card**: Container with elevation, corner radius, and materials
- **KeyValueRow**: Key-value pairs with copyable text and layouts
- **SectionHeader**: Section titles with optional dividers

---

## ⚙️ Interactive Features

### Theme Toggle
Switch between Light and Dark modes to see component adaptation:
- Available in **Controls** section of main navigation
- Real-time preview updates
- Respects system color scheme by default

### Dynamic Type Support
All components scale with system text size preferences:
- Test with iOS Settings → Accessibility → Display & Text Size
- Verify readability across all size categories (XS to XXXL)

### Code Snippets
Every showcase screen includes **copyable code snippets** demonstrating:
- Component initialization
- Common usage patterns
- Parameter variations
- Real-world compositions

---

## 🧪 Testing Workflow

### Manual Testing Checklist

- [ ] Run app on iOS simulator (iPhone 15)
- [ ] Run app on macOS (My Mac)
- [ ] Test Light/Dark mode switching
- [ ] Test Dynamic Type scaling (Settings → Accessibility)
- [ ] Verify VoiceOver navigation (⌘F5 to enable on macOS)
- [ ] Check all component variations render correctly
- [ ] Verify interactive controls work (badges, elevation pickers, etc.)
- [ ] Test copyable text in KeyValueRow (click to copy)

### Accessibility Testing

1. **VoiceOver:**
   - Enable: Settings → Accessibility → VoiceOver (iOS) or `⌘F5` (macOS)
   - Navigate through components with swipe gestures (iOS) or `⌃⌥→` (macOS)
   - Verify all elements are announced correctly

2. **Dynamic Type:**
   - iOS: Settings → Display & Text Size → Larger Text
   - macOS: System Settings → Accessibility → Display → Text Size
   - Verify all text scales appropriately

3. **Contrast:**
   - Enable Increase Contrast in Accessibility settings
   - Verify all colors remain readable (≥4.5:1 contrast ratio)

---

## 🛠️ Development

### Adding New Components

When a new component is added to FoundationUI:

1. **Create a showcase screen:**
   ```swift
   // Screens/NewComponentScreen.swift
   struct NewComponentScreen: View {
       var body: some View {
           ScrollView {
               // Component examples with controls
           }
       }
   }
   ```

2. **Add to ContentView navigation:**
   ```swift
   // ContentView.swift
   enum ScreenDestination {
       // ...
       case newComponent
   }

   NavigationLink(value: ScreenDestination.newComponent) {
       Label("New Component", systemImage: "icon.name")
   }
   ```

3. **Implement destination view:**
   ```swift
   case .newComponent:
       NewComponentScreen()
   ```

### Code Style

- **Follow FoundationUI conventions:**
  - Use DS tokens for all spacing, colors, typography
  - Zero magic numbers
  - DocC comments for all public types
  - SwiftUI Previews for all screens

- **Naming:**
  - Screens: `{ComponentName}Screen.swift`
  - Helper views: `{Purpose}View` (e.g., `CodeSnippetView`)

---

## 📊 Current Status

**Implemented:**
- ✅ Design Tokens showcase (Spacing, Colors, Typography, Radius, Animation)
- ✅ View Modifiers showcase (BadgeChipStyle, CardStyle, InteractiveStyle, SurfaceStyle)
- ✅ Badge component showcase (all levels, icons, use cases)
- ✅ Card component showcase (elevations, materials, radius, nesting)
- ✅ KeyValueRow component showcase (layouts, copyable text, monospaced)
- ✅ SectionHeader component showcase (dividers, spacing, accessibility)
- ✅ Root navigation with Light/Dark mode toggle

**Planned (Future):**
- [ ] Theme toggle control (separate component)
- [ ] Dynamic Type size controls (slider for real-time adjustment)
- [ ] Code snippet exporter (copy formatted code to clipboard)
- [ ] Platform feature toggles (show/hide platform-specific features)

---

## 📖 Documentation

### Related Documents
- [FoundationUI Task Plan](../../FoundationUI/DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) - Overall project roadmap
- [FoundationUI PRD](../../FoundationUI/DOCS/AI/ISOViewer/FoundationUI_PRD.md) - Product requirements
- [Phase 2.3 Demo Application](../../FoundationUI/DOCS/INPROGRESS/Phase2.3_DemoApplication.md) - Task documentation

### Component Documentation
All components have comprehensive DocC documentation viewable in Xcode:
- Product → Build Documentation (`⌃⌘⇧D`)
- Navigate to FoundationUI module

---

## 🐛 Known Issues

**None currently.** This is a demo/testing app under active development.

If you encounter issues:
1. Clean build folder: `⌘⇧K` in Xcode
2. Reset package caches: `File → Packages → Reset Package Caches`
3. Rebuild: `⌘B`

---

## 📝 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-10-23 | Initial release with 6 showcase screens |

---

## 👤 Author

**Claude** (AI Assistant)
Created for the ISOInspector project as part of Phase 2.3 implementation.

---

## 📜 License

This demo application is part of the ISOInspector project and follows the same license as the parent project.

---

**Last Updated:** 2025-10-23

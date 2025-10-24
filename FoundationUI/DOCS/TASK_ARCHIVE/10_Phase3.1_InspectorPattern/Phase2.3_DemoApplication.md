# Phase 2.3: Demo Application

## 🎯 Objective
Create a minimal demo application for component testing that showcases all implemented FoundationUI components with interactive examples, live preview capabilities, and comprehensive documentation.

## 🧩 Context
- **Phase**: Phase 2.3 - Demo Application (Component Testing)
- **Layer**: Application Layer (integrates all layers)
- **Priority**: P0 (Critical)
- **Status**: ✅ Completed 2025-10-23 (archived with InspectorPattern planning set)
- **Dependencies**:
  - ✅ Phase 2.1 complete (all View Modifiers implemented)
  - ✅ Phase 2.2 complete (all Essential Components implemented)
  - ✅ Design Tokens (DS) complete
  - ✅ SwiftLint configuration ready
  - ✅ Test infrastructure in place

## ✅ Success Criteria
- [ ] Single-target universal app (iOS/macOS) created
- [ ] Component showcase screens implemented for all components
- [ ] Interactive component inspector with controls
- [ ] Live preview of all implemented components
- [ ] Navigation between component screens
- [ ] Light/Dark mode toggle functionality
- [ ] Dynamic Type size adjustment
- [ ] Platform-specific feature toggles
- [ ] Component code snippet export capability
- [ ] README with setup instructions
- [ ] Screenshots of all screens
- [ ] Demo app compiles and runs on both iOS and macOS
- [ ] Zero SwiftLint violations
- [ ] All components properly demonstrated

## 🔧 Implementation Notes

### Project Structure
```
Examples/
└── ComponentTestApp/
    ├── ComponentTestApp/
    │   ├── ComponentTestApp.swift (main app entry)
    │   ├── ContentView.swift (root navigation)
    │   ├── Screens/
    │   │   ├── DesignTokensScreen.swift
    │   │   ├── ModifiersScreen.swift
    │   │   ├── BadgeScreen.swift
    │   │   ├── CardScreen.swift
    │   │   ├── KeyValueRowScreen.swift
    │   │   └── SectionHeaderScreen.swift
    │   ├── Controls/
    │   │   ├── ThemeToggle.swift
    │   │   ├── DynamicTypeControls.swift
    │   │   └── PlatformFeatureToggles.swift
    │   └── Utilities/
    │       ├── CodeSnippetExporter.swift
    │       └── ComponentDemonstrator.swift
    ├── Assets.xcassets/
    └── Package.swift (or Xcode project)
```

### Files to Create/Modify
1. `Examples/ComponentTestApp/Package.swift` - SPM package definition
2. `Examples/ComponentTestApp/ComponentTestApp/ComponentTestApp.swift` - App entry point
3. `Examples/ComponentTestApp/ComponentTestApp/ContentView.swift` - Root view with navigation
4. `Examples/ComponentTestApp/ComponentTestApp/Screens/*.swift` - Component showcase screens
5. `Examples/ComponentTestApp/ComponentTestApp/Controls/*.swift` - Interactive controls
6. `Examples/ComponentTestApp/README.md` - Setup and usage documentation

### Design Token Usage
All demo screens should demonstrate proper DS token usage:
- Spacing: `DS.Spacing.{s|m|l|xl}`
- Colors: `DS.Colors.{infoBG|warnBG|errorBG|successBG}`
- Radius: `DS.Radius.{card|chip|small}`
- Animation: `DS.Animation.{quick|medium}`
- Typography: `DS.Typography.{label|body|title|caption}`

### Component Showcase Requirements

#### Design Tokens Screen
- Visual reference for all spacing values
- Color swatches for all semantic colors
- Typography samples for all text styles
- Radius examples for all corner radius values
- Animation timing demonstrations

#### Modifiers Screen
- Interactive examples of BadgeChipStyle
- Interactive examples of CardStyle
- Interactive examples of InteractiveStyle
- Interactive examples of SurfaceStyle
- Side-by-side comparisons

#### Component Screens
Each component gets its own dedicated screen:
1. **Badge Screen**:
   - All badge levels (info, warning, error, success)
   - With and without icons
   - Different text lengths
   - Accessibility labels demonstration

2. **Card Screen**:
   - All elevation levels (none, low, medium, high)
   - Different corner radii
   - Various material backgrounds
   - Nested content examples
   - Complex compositions

3. **KeyValueRow Screen**:
   - Horizontal and vertical layouts
   - Copyable text examples
   - Long keys and values
   - Monospaced value display
   - Platform-specific clipboard handling

4. **SectionHeader Screen**:
   - With and without dividers
   - Different spacing configurations
   - Uppercase styling demonstration
   - Accessibility heading levels

### Interactive Inspector Features

#### Theme Toggle
- Switch between Light and Dark modes
- Real-time preview update
- Persistent preference (optional)

#### Dynamic Type Controls
- Slider to adjust text size (XS to XXXL)
- Real-time font scaling
- Show current size category

#### Platform Feature Toggles
- Toggle macOS-specific features
- Toggle iOS-specific features
- Show platform capabilities

#### Code Snippet Export
- Generate SwiftUI code for current configuration
- Copy to clipboard functionality
- Show formatted code with syntax highlighting (optional)

## 🧠 Source References
- [FoundationUI Task Plan § Phase 2.3](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)
- [FoundationUI PRD § Example Projects](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [Apple SwiftUI App Documentation](https://developer.apple.com/documentation/swiftui/app)
- [SwiftUI Multiplatform Development](https://developer.apple.com/documentation/swiftui/building-a-multiplatform-app)

## 📋 Checklist

### Setup Phase
- [ ] Create Examples/ComponentTestApp directory structure
- [ ] Initialize Swift Package or Xcode project
- [ ] Configure platform targets (iOS 17+, macOS 14+)
- [ ] Add FoundationUI as dependency
- [ ] Create basic app structure (App, ContentView)

### Implementation Phase
- [ ] Implement Design Tokens showcase screen
- [ ] Implement Modifiers showcase screen
- [ ] Implement Badge showcase screen
- [ ] Implement Card showcase screen
- [ ] Implement KeyValueRow showcase screen
- [ ] Implement SectionHeader showcase screen
- [ ] Create navigation between screens
- [ ] Implement theme toggle control
- [ ] Implement Dynamic Type controls
- [ ] Implement platform feature toggles
- [ ] Implement code snippet exporter

### Testing Phase
- [ ] Test on iOS simulator (iPhone)
- [ ] Test on macOS
- [ ] Test on iPad simulator (optional)
- [ ] Verify Light/Dark mode switching
- [ ] Verify Dynamic Type scaling
- [ ] Test all interactive controls
- [ ] Verify code export functionality
- [ ] Run SwiftLint (0 violations)

### Documentation Phase
- [ ] Write README.md with setup instructions
- [ ] Document how to add new components
- [ ] Add testing guidelines for developers
- [ ] Take screenshots of all screens
- [ ] Document known limitations (if any)

### Completion Phase
- [ ] Update Task Plan with completion mark
- [ ] Archive task documentation
- [ ] Commit with descriptive message
- [ ] Update next_tasks.md

## 🎨 Visual Requirements

### Navigation Structure
```
Root (TabView or NavigationStack)
├── Design Tokens
├── View Modifiers
└── Components
    ├── Badge
    ├── Card
    ├── KeyValueRow
    └── SectionHeader
```

### Color Scheme
- Use FoundationUI design tokens for all styling
- Respect system color scheme (Light/Dark)
- Demonstrate color adaptation

### Layout Guidelines
- Responsive layouts for all screen sizes
- Platform-adaptive spacing and sizing
- Proper use of ScrollView for long content
- Consistent navigation patterns

## 🚀 Implementation Strategy

### Phase 1: Basic Structure (2-3 hours)
1. Create project structure
2. Set up basic navigation
3. Create placeholder screens

### Phase 2: Component Showcases (4-6 hours)
1. Implement Design Tokens screen
2. Implement Modifiers screen
3. Implement component screens (one by one)
4. Add comprehensive examples for each

### Phase 3: Interactive Features (2-3 hours)
1. Implement theme toggle
2. Implement Dynamic Type controls
3. Implement platform toggles
4. Implement code export

### Phase 4: Polish & Documentation (1-2 hours)
1. Write README
2. Take screenshots
3. Final testing
4. Documentation updates

**Total Estimated Effort**: L (1-2 days, 9-14 hours)

## 📊 Progress Tracking

**Status**: 🟡 IN PROGRESS
**Started**: 2025-10-23
**Completed**: TBD

**Current Step**: Setup Phase
**Blockers**: None
**Notes**: All dependencies met, ready to start implementation

## 🔄 Next Steps After Completion

Upon successful completion of Phase 2.3 Demo Application:
1. Archive task to `TASK_ARCHIVE/10_Phase2.3_DemoApplication/`
2. Update FoundationUI Task Plan with completion mark
3. Update next_tasks.md with Phase 3 priorities
4. Prepare for Phase 3.1: UI Patterns (InspectorPattern, SidebarPattern, etc.)

---

**Priority**: P0 (Critical)
**Estimated Effort**: L (1-2 days)
**Dependencies**: ✅ All met
**Assigned To**: Claude
**Created**: 2025-10-23

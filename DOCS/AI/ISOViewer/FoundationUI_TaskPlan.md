# FoundationUI Implementation Task Plan
**Based on:** FoundationUI PRD v1.0
**Project:** ISO Inspector
**Created:** 2025-10-20
**Status:** Active Development

---

## Overall Progress Tracker
**Total: 0/99 tasks completed (0%)**

| Phase | Status | Progress |
|-------|--------|----------|
| Phase 1: Foundation | Not Started | 0/15 (0%) |
| Phase 2: Core Components | Not Started | 0/22 (0%) |
| Phase 3: Patterns & Platform Adaptation | Not Started | 0/16 (0%) |
| Phase 4: Agent Support & Polish | Not Started | 0/13 (0%) |
| Phase 5: Documentation & QA | Not Started | 0/15 (0%) |
| Phase 6: Integration & Validation | Not Started | 0/18 (0%) |

---

## Phase 1: Foundation (Week 1-2)
**Priority: P0 - Critical**
**Progress: 0/15 tasks completed (0%)**

### 1.1 Project Setup & Infrastructure
**Progress: 0/8 tasks**

- [ ] **P0** Create FoundationUI Swift Package structure
  - [ ] Initialize Package.swift with Swift 5.9+ requirement
  - [ ] Configure platform targets (iOS 17+, iPadOS 17+, macOS 14+)
  - [ ] Set up directory structure (Sources/, Tests/, Documentation/)
  - [ ] Configure .gitignore for Swift/Xcode artifacts

- [ ] **P0** Set up build configuration
  - [ ] Configure Swift compiler settings (strict concurrency, warnings as errors)
  - [ ] Set up SwiftLint configuration with zero-magic-numbers rule
  - [ ] Create build scripts for CI/CD pipeline
  - [ ] Configure code coverage reporting (target: ≥80%)

### 1.2 Design System Foundation (Layer 0)
**Progress: 0/7 tasks**

- [ ] **P0** Implement Design Tokens namespace (DS)
  - File: `Sources/DesignTokens/DesignSystem.swift`
  - Create base DS enum structure

- [ ] **P0** Implement Spacing tokens
  - File: `Sources/DesignTokens/Spacing.swift`
  - Define s (8), m (12), l (16), xl (24) constants
  - Add platformDefault computed property with conditional compilation
  - Include DocC documentation with visual examples

- [ ] **P0** Implement Typography tokens
  - File: `Sources/DesignTokens/Typography.swift`
  - Define label, body, title, caption font styles
  - Ensure Dynamic Type support
  - Document accessibility considerations

- [ ] **P0** Implement Color tokens
  - File: `Sources/DesignTokens/Colors.swift`
  - Define semantic colors (infoBG, warnBG, errorBG, successBG)
  - Ensure WCAG 2.1 contrast compliance (≥4.5:1)
  - Add Dark Mode variants

- [ ] **P0** Implement Radius tokens
  - File: `Sources/DesignTokens/Radius.swift`
  - Define card (10), chip (999), small (6) corner radii
  - Document usage patterns

- [ ] **P0** Implement Animation tokens
  - File: `Sources/DesignTokens/Animation.swift`
  - Define quick (0.15s snappy), medium (0.25s easeInOut) animations
  - Add preferredReduceMotion support

- [ ] **P0** Create Design Tokens validation tests
  - File: `Tests/DesignTokensTests/TokenValidationTests.swift`
  - Verify no magic numbers in token definitions
  - Test platform-specific values
  - Validate accessibility compliance

---

## Phase 2: Core Components (Week 3-4)
**Priority: P0 - Critical**
**Progress: 0/22 tasks completed (0%)**

### 2.1 Layer 1: View Modifiers (Atoms)
**Progress: 0/6 tasks**

- [ ] **P0** Implement BadgeChipStyle modifier
  - File: `Sources/Modifiers/BadgeChipStyle.swift`
  - Support BadgeLevel enum (info, warning, error, success)
  - Use DS tokens exclusively (zero magic numbers)
  - Include accessibility labels
  - Add SwiftUI Preview with all levels

- [ ] **P0** Implement CardStyle modifier
  - File: `Sources/Modifiers/CardStyle.swift`
  - Support elevation levels (none, low, medium, high)
  - Configurable corner radius via DS.Radius
  - Platform-adaptive shadows
  - Add SwiftUI Preview with variations

- [ ] **P0** Implement InteractiveStyle modifier
  - File: `Sources/Modifiers/InteractiveStyle.swift`
  - Hover effects for macOS
  - Touch feedback for iOS/iPadOS
  - Keyboard focus indicators
  - Accessibility hints

- [ ] **P0** Implement SurfaceStyle modifier
  - File: `Sources/Modifiers/SurfaceStyle.swift`
  - Material-based backgrounds (.thin, .regular, .thick)
  - Platform-adaptive appearance
  - Dark mode support

- [ ] **P1** Write modifier unit tests
  - File: `Tests/ModifiersTests/ModifierTests.swift`
  - Test all style variations
  - Verify DS token usage
  - Test accessibility attributes

- [ ] **P1** Create modifier preview catalog
  - File: `Sources/Modifiers/ModifierPreviews.swift`
  - Showcase all modifiers in Light/Dark modes
  - Different platform idioms
  - Dynamic Type variations

### 2.2 Layer 2: Essential Components (Molecules)
**Progress: 0/12 tasks**

- [ ] **P0** Implement Badge component
  - File: `Sources/Components/Badge.swift`
  - Public initializer: `Badge(text: String, level: BadgeLevel)`
  - Use BadgeChipStyle modifier
  - Full VoiceOver support
  - Add 4+ SwiftUI Previews (all levels, light/dark)

- [ ] **P0** Implement Card component
  - File: `Sources/Components/Card.swift`
  - Generic content with @ViewBuilder
  - Configurable elevation and corner radius
  - Material background support
  - Add comprehensive previews

- [ ] **P0** Implement KeyValueRow component
  - File: `Sources/Components/KeyValueRow.swift`
  - Display key-value pairs with semantic styling
  - Optional copyable text integration
  - Monospaced font for values
  - Keyboard shortcut hints

- [ ] **P0** Implement SectionHeader component
  - File: `Sources/Components/SectionHeader.swift`
  - Uppercase title styling
  - Optional divider support
  - Consistent spacing via DS.Spacing
  - Accessibility heading level

- [ ] **P0** Implement CopyableText utility component
  - File: `Sources/Components/CopyableText.swift`
  - Click-to-copy functionality
  - Visual feedback on copy
  - Keyboard shortcut (⌘C / Ctrl+C)
  - Toast notification support

- [ ] **P0** Write component unit tests
  - Test Badge with all levels
  - Test Card composition and nesting
  - Test KeyValueRow with copyable text
  - Test SectionHeader accessibility
  - Verify 100% public API coverage

- [ ] **P0** Create component snapshot tests
  - Test Light/Dark mode rendering
  - Test Dynamic Type sizes (XS, M, XXL)
  - Test platform-specific layouts
  - Test locale variations (RTL support)

- [ ] **P0** Implement component previews
  - Create comprehensive preview catalog
  - Show all component variations
  - Include usage examples in DocC
  - Platform-specific preview conditionals

- [ ] **P1** Add component accessibility tests
  - VoiceOver navigation testing
  - Contrast ratio validation (≥4.5:1)
  - Keyboard navigation testing
  - Focus management verification

- [ ] **P1** Performance testing for components
  - Measure render time for complex hierarchies
  - Test memory footprint (target: <5MB per screen)
  - Verify 60 FPS on all platforms
  - Profile with Instruments

- [ ] **P1** Component integration tests
  - Test component nesting scenarios
  - Verify Environment value propagation
  - Test state management
  - Test preview compilation

- [ ] **P1** Code quality verification
  - Run SwiftLint (target: 0 violations)
  - Verify zero magic numbers
  - Check documentation coverage (100%)
  - Review API naming consistency

### 2.3 Demo Application (Component Testing)
**Progress: 0/4 tasks**

- [ ] **P0** Create minimal demo app for component testing
  - File: `Examples/ComponentTestApp/`
  - Single-target app (iOS/macOS universal)
  - Live preview of all implemented components
  - Used for manual testing during development
  - Quick iteration without full example apps

- [ ] **P0** Implement component showcase screens
  - Screen for Design Tokens (visual reference)
  - Screen for View Modifiers (interactive examples)
  - Screen for each Component (all variations)
  - Navigation between component screens

- [ ] **P1** Add interactive component inspector
  - Toggle between Light/Dark mode
  - Adjust Dynamic Type size
  - Toggle platform-specific features
  - Export component code snippets

- [ ] **P1** Demo app documentation
  - README with setup instructions
  - How to add new components to showcase
  - Testing guidelines for developers
  - Screenshots of all screens

---

## Phase 3: Patterns & Platform Adaptation (Week 5-6)
**Priority: P0-P1**
**Progress: 0/16 tasks completed (0%)**

### 3.1 Layer 3: UI Patterns (Organisms)
**Progress: 0/8 tasks**

- [ ] **P0** Implement InspectorPattern
  - File: `Sources/Patterns/InspectorPattern.swift`
  - Scrollable content with title header
  - Material background (.thinMaterial default)
  - Generic content via @ViewBuilder
  - Platform-adaptive padding
  - Complete SwiftUI Previews

- [ ] **P0** Implement SidebarPattern
  - File: `Sources/Patterns/SidebarPattern.swift`
  - Navigation list with sections
  - Platform-specific width (macOS: 250pt, iPad: adaptive)
  - Selection state management
  - Keyboard navigation support
  - macOS/iPad conditional compilation

- [ ] **P1** Implement ToolbarPattern
  - File: `Sources/Patterns/ToolbarPattern.swift`
  - Platform-adaptive toolbar items
  - Icon + label support with SF Symbols
  - Keyboard shortcut integration
  - Accessibility labels

- [ ] **P1** Implement BoxTreePattern
  - File: `Sources/Patterns/BoxTreePattern.swift`
  - Hierarchical tree view for ISO box structure
  - Expand/collapse functionality
  - Indentation via DS.Spacing
  - Selection and navigation
  - Performance optimization for large trees (1000+ nodes)

- [ ] **P0** Write pattern unit tests
  - Test InspectorPattern composition
  - Test SidebarPattern selection logic
  - Test ToolbarPattern keyboard shortcuts
  - Test BoxTreePattern hierarchy

- [ ] **P0** Create pattern integration tests
  - Test pattern combinations (Sidebar + Inspector)
  - Test Environment value propagation
  - Test platform-specific rendering
  - Test navigation flows

- [ ] **P0** Pattern preview catalog
  - Complete visual examples for all patterns
  - Real-world usage scenarios
  - Platform comparison views
  - Dark mode variations

- [ ] **P1** Pattern performance optimization
  - Lazy loading for BoxTreePattern
  - Virtualization for long lists
  - Render performance profiling
  - Memory usage optimization

### 3.2 Layer 4: Contexts & Platform Adaptation
**Progress: 0/8 tasks**

- [ ] **P0** Implement SurfaceStyleKey environment key
  - File: `Sources/Contexts/SurfaceStyleKey.swift`
  - Define EnvironmentKey for Material
  - Default value: .regular
  - Extension for EnvironmentValues

- [ ] **P0** Implement PlatformAdaptation modifiers
  - File: `Sources/Contexts/PlatformAdaptation.swift`
  - PlatformAdaptiveModifier for spacing
  - Conditional compilation for macOS vs iOS
  - Size class adaptation for iPad
  - Test on all platforms

- [ ] **P0** Implement ColorSchemeAdapter
  - File: `Sources/Contexts/ColorSchemeAdapter.swift`
  - Automatic Dark Mode adaptation
  - Color scheme detection
  - Custom theme support (future)

- [ ] **P1** Create platform-specific extensions
  - File: `Sources/Contexts/PlatformExtensions.swift`
  - macOS-specific keyboard shortcuts
  - iOS-specific gestures
  - iPadOS pointer interactions

- [ ] **P0** Context unit tests
  - Test environment key propagation
  - Test platform detection logic
  - Test color scheme adaptation
  - Test size class handling

- [ ] **P0** Platform adaptation integration tests
  - Test macOS-specific behavior
  - Test iOS-specific behavior
  - Test iPad adaptive layout
  - Cross-platform consistency verification

- [ ] **P1** Create platform comparison previews
  - Side-by-side platform previews
  - Document platform differences
  - Show adaptive behavior
  - Include in DocC documentation

- [ ] **P1** Accessibility context support
  - Reduce motion detection
  - Increase contrast support
  - Bold text handling
  - Dynamic Type environment values

---

## Phase 4: Agent Support & Polish (Week 7-8)
**Priority: P1-P2**
**Progress: 0/13 tasks completed (0%)**

### 4.1 Agent-Driven UI Generation
**Progress: 0/7 tasks**

- [ ] **P1** Define AgentDescribable protocol
  - File: `Sources/AgentSupport/AgentDescribable.swift`
  - Properties: componentType, properties, semantics
  - Documentation with examples
  - Type-safe property encoding

- [ ] **P1** Implement AgentDescribable for all components
  - Extend Badge, Card, KeyValueRow, SectionHeader
  - Extend all Pattern types
  - Ensure all properties are encodable
  - Add unit tests for protocol conformance

- [ ] **P1** Create YAML schema definitions
  - File: `Sources/AgentSupport/ComponentSchema.yaml`
  - Define schema for all components
  - Include validation rules
  - Document in YAML format

- [ ] **P1** Implement YAML parser/validator
  - File: `Sources/AgentSupport/YAMLValidator.swift`
  - Parse component YAML definitions
  - Validate against schema
  - Generate SwiftUI views from YAML
  - Error handling and reporting

- [ ] **P2** Create agent integration examples
  - File: `Examples/AgentIntegration/`
  - Example YAML component definitions
  - Swift code generation examples
  - Integration with 0AL/Hypercode agents
  - Documentation guide

- [ ] **P2** Agent support unit tests
  - Test AgentDescribable conformance
  - Test YAML parsing accuracy
  - Test view generation from YAML
  - Test error cases

- [ ] **P2** Agent integration documentation
  - Create agent integration guide
  - API reference for agent developers
  - Best practices for UI generation
  - Troubleshooting guide

### 4.2 Utilities & Helpers
**Progress: 0/6 tasks**

- [ ] **P0** Implement CopyableText utility
  - File: `Sources/Utilities/CopyableText.swift`
  - Cross-platform clipboard access
  - Visual feedback (animation, toast)
  - Keyboard shortcut support
  - VoiceOver announcements

- [ ] **P1** Implement KeyboardShortcuts utility
  - File: `Sources/Utilities/KeyboardShortcuts.swift`
  - Platform-specific shortcut definitions
  - Command/Control key abstraction
  - Documentation for standard shortcuts

- [ ] **P1** Implement AccessibilityHelpers
  - File: `Sources/Utilities/AccessibilityHelpers.swift`
  - Common accessibility modifiers
  - VoiceOver hint builders
  - Contrast ratio validators
  - Accessibility audit tools

- [ ] **P1** Utility unit tests
  - Test clipboard operations
  - Test keyboard shortcut handling
  - Test accessibility helpers
  - Platform-specific test coverage

- [ ] **P1** Utility integration tests
  - Test utilities with components
  - Test cross-platform compatibility
  - Test accessibility integration
  - Real-device testing

- [ ] **P2** Performance optimization for utilities
  - Optimize clipboard operations
  - Minimize memory allocations
  - Profile with Instruments
  - Optimize accessibility checks

---

## Phase 5: Documentation & QA (Continuous)
**Priority: P0-P1**
**Progress: 0/15 tasks completed (0%)**

### 5.1 API Documentation (DocC)
**Progress: 0/6 tasks**

- [ ] **P0** Set up DocC documentation catalog
  - Create Documentation.docc bundle
  - Configure landing page
  - Set up navigation structure
  - Add brand assets and styling

- [ ] **P0** Document all Design Tokens
  - 100% DocC coverage for DS namespace
  - Visual examples for spacing, colors, typography
  - Usage guidelines and best practices
  - Platform-specific considerations

- [ ] **P0** Document all View Modifiers
  - Complete DocC for all modifiers
  - Before/after visual examples
  - Common use cases
  - Accessibility notes

- [ ] **P0** Document all Components
  - Complete API reference for all components
  - Code examples for each component
  - Visual previews in documentation
  - Accessibility guidelines

- [ ] **P0** Document all Patterns
  - Complete documentation for all patterns
  - Real-world usage examples
  - Platform-specific implementations
  - Composition guidelines

- [ ] **P0** Create comprehensive tutorials
  - Getting started tutorial (5-minute quick start)
  - Building first component tutorial
  - Creating custom patterns tutorial
  - Platform adaptation tutorial

### 5.2 Testing & Quality Assurance
**Progress: 0/6 tasks**

- [ ] **P0** Achieve ≥80% code coverage
  - Run code coverage analysis
  - Identify untested code paths
  - Write missing tests
  - Verify coverage metrics in CI

- [ ] **P0** Accessibility audit (≥95% score)
  - Automated accessibility testing
  - Manual VoiceOver testing
  - Keyboard navigation verification
  - Contrast ratio validation (all components)
  - Dynamic Type testing

- [ ] **P0** Performance profiling
  - Profile all components with Instruments
  - Verify <10s build time for clean module
  - Verify <500KB binary size
  - Verify <5MB memory footprint per screen
  - Ensure 60 FPS rendering on all platforms

- [ ] **P1** SwiftLint compliance (0 violations)
  - Configure custom rules (zero magic numbers)
  - Fix all violations
  - Set up CI enforcement
  - Document exceptions (if any)

- [ ] **P1** Cross-platform testing
  - Test on iOS 17+ (iPhone, iPad)
  - Test on iPadOS 17+ (all size classes)
  - Test on macOS 14+ (multiple window sizes)
  - Test Dark Mode on all platforms
  - Test RTL languages

- [ ] **P1** Regression testing suite
  - Create snapshot test baselines
  - Set up visual regression CI
  - Document snapshot update process
  - Test matrix (platforms × modes × sizes)

### 5.3 Design Documentation
**Progress: 0/3 tasks**

- [ ] **P1** Create Component Catalog
  - Visual showcase of all components
  - Interactive examples (if possible)
  - Design specifications
  - Usage do's and don'ts

- [ ] **P1** Create Design Token Reference
  - Complete visual token reference
  - Design decision documentation
  - Customization guidelines
  - Token evolution strategy

- [ ] **P1** Create Platform Adaptation Guide
  - Platform comparison charts
  - Adaptive design patterns
  - Platform-specific guidelines
  - Best practices for cross-platform UI

---

## Phase 6: Integration & Validation (Week 8+)
**Priority: P1-P2**
**Progress: 0/18 tasks completed (0%)**

### 6.1 Example Projects
**Progress: 0/10 tasks**

- [ ] **P1** Create iOS example app
  - File: `Examples/iOS/ISOInspectorDemo/`
  - Full-featured ISO file inspector UI
  - Showcase all components in real context
  - Navigation stack implementation
  - Tab bar with multiple sections
  - Sheet presentations and alerts
  - File picker integration
  - Dark mode support
  - VoiceOver testing

- [ ] **P1** iOS demo app implementation details
  - Parse and display ISO box structure
  - Use BoxTreePattern for hierarchy
  - Use InspectorPattern for details
  - Badge components for box types
  - KeyValueRow for metadata
  - CopyableText for hex values
  - Search and filter functionality

- [ ] **P1** Create macOS example app
  - File: `Examples/macOS/ISOInspectorDemo/`
  - Multi-window document architecture
  - Use SidebarPattern for navigation
  - Use ToolbarPattern for actions
  - Resizable inspector panel
  - Keyboard shortcut integration (⌘ keys)
  - Menu bar integration
  - Window state persistence
  - Drag & drop support

- [ ] **P1** macOS demo app implementation details
  - Three-column layout (Sidebar → Tree → Inspector)
  - Custom toolbar with SF Symbols
  - Contextual menus for tree items
  - Quick Look preview integration
  - Export functionality
  - Preferences window
  - Full keyboard navigation

- [ ] **P2** Create iPad example app
  - File: `Examples/iPad/ISOInspectorDemo/`
  - Adaptive layout for all size classes
  - Split view on landscape
  - Sidebar collapse on portrait
  - Pointer interaction hover effects
  - Drag and drop between panes
  - Multitasking support
  - Keyboard shortcuts (with hardware keyboard)

- [ ] **P2** iPad demo app implementation details
  - Responsive component sizing
  - Touch-optimized controls
  - Pointer hover states
  - Context menus on long press
  - Pencil support (if applicable)
  - State preservation

- [ ] **P1** Create unified demo app (all platforms)
  - File: `Examples/UnifiedDemo/`
  - Single codebase for iOS/iPadOS/macOS
  - Conditional UI based on platform
  - Shared business logic
  - Platform-specific features
  - Best practices showcase

- [ ] **P2** Create component playground
  - File: `Examples/ComponentPlayground/`
  - Interactive component explorer
  - Live parameter tweaking interface
  - Side-by-side code and preview
  - Export code snippets
  - Search components by name
  - Filter by category (Atoms, Molecules, Organisms)

- [ ] **P2** Demo app assets and content
  - Sample ISO files for testing
  - App icons for all platforms
  - Screenshots for documentation
  - Video recordings of key features
  - User guide within apps

- [ ] **P1** Demo app documentation
  - README for each example app
  - Architecture documentation
  - Setup and build instructions
  - Feature highlights
  - Code walkthrough guides
  - Common patterns demonstrated

### 6.2 Integration Testing
**Progress: 0/4 tasks**

- [ ] **P1** Integration with ISO Inspector Core
  - Test with real domain models
  - Integration test suite
  - Performance testing with real data
  - Fix integration issues

- [ ] **P1** Integration with 0AL Agent SDK
  - Test agent-driven UI generation
  - Validate YAML schema compatibility
  - Performance testing for generated UIs
  - Document integration points

- [ ] **P2** Third-party package integration test
  - Test FoundationUI as SPM dependency
  - Verify all targets build correctly
  - Test version compatibility
  - Document integration steps

- [ ] **P2** CI/CD pipeline setup
  - Set up automated testing
  - Set up automated deployment
  - Set up documentation generation
  - Configure release automation

### 6.3 Final Validation
**Progress: 0/4 tasks**

- [ ] **P0** Success criteria validation
  - ✅ 100% platform support (iOS 17+, iPadOS 17+, macOS 14+)
  - ✅ Zero magic numbers (100% DS token usage)
  - ✅ Accessibility score ≥95%
  - ✅ Test coverage ≥80%
  - ✅ Preview coverage = 100%
  - ✅ API documentation = 100%

- [ ] **P0** Performance benchmarking
  - Build time <10s ✓
  - Binary size <500KB ✓
  - Memory footprint <5MB ✓
  - Render performance 60 FPS ✓

- [ ] **P1** Developer experience validation
  - Time to first component <5 minutes ✓
  - Code reuse rate ≥80% ✓
  - Documentation satisfaction ≥90% ✓
  - Run user acceptance testing

- [ ] **P1** Final release preparation
  - Version tagging (v1.0.0)
  - Release notes preparation
  - Migration guide (if applicable)
  - Announcement and communication plan

---

## Dependencies & Blockers

### Critical Dependencies
- [ ] Swift 5.9+ toolchain availability
- [ ] Xcode 15.0+ installation on all development machines
- [ ] ISO Inspector Core domain models (for integration)
- [ ] 0AL Agent SDK availability (for agent features)

### Known Risks
| Risk | Impact | Mitigation Status |
|------|--------|-------------------|
| Platform API changes | High | Monitor beta releases, conditional compilation |
| Performance on older devices | Medium | Profiling scheduled in Phase 5 |
| Agent integration complexity | Medium | Phased rollout, P1 priority |

---

## Success Metrics Dashboard

### Technical Metrics (Target Values)
- [ ] Build time: <10s for clean module build
- [ ] Binary size: <500KB for release build
- [ ] Memory footprint: <5MB for typical screen
- [ ] Render performance: 60 FPS on all platforms
- [ ] Test coverage: ≥80%
- [ ] Accessibility score: ≥95%
- [ ] SwiftLint violations: 0
- [ ] Magic numbers: 0 (100% DS token usage)

### Developer Experience Metrics
- [ ] Time to first component: <5 minutes
- [ ] Code reuse rate: ≥80% between platforms
- [ ] Documentation quality: ≥90% satisfaction
- [ ] API discoverability: 100% DocC coverage

---

## Version History
| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-10-20 | Initial task plan created from PRD v1.0 | Claude |

---

## Notes
- **Priority Levels:**
  - **P0** = Critical for MVP, must be completed
  - **P1** = Important for quality, should be completed
  - **P2** = Nice to have, can be deferred to post-MVP

- **Estimation:**
  - Small task (S): 1-4 hours
  - Medium task (M): 4-8 hours
  - Large task (L): 1-3 days
  - Extra Large (XL): 3+ days

- **Update Frequency:** This task plan should be updated daily during active development with progress checkmarks and notes.

---

*This task plan is a living document. Update progress and add notes as implementation proceeds.*

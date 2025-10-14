# Getting Started

Follow the XP-inspired outside-in workflow described in `DOCS/RULES/02_TDD_XP_Workflow.md` when contributing to ISOInspector.【F:DOCS/RULES/02_TDD_XP_Workflow.md†L1-L112】 For the complete onboarding playbook, read `Docs/Guides/DeveloperOnboarding.md` before picking up a task.【F:Docs/Guides/DeveloperOnboarding.md†L1-L126】

## 1. Prerequisites
- Swift 6.0.1 or newer.【F:README.md†L17-L24】
- Xcode 15+ for Apple platform development.【F:README.md†L17-L24】
- Optional: enable repo-managed Markdown lint hooks via `git config core.hooksPath .githooks`.【F:README.md†L26-L40】

## 2. Build & Test Loop
```sh
swift build
swift test
```
Run these commands early to keep the workspace green and validate all targets.【F:README.md†L17-L32】

## 3. Next Steps
- Review the Developer Onboarding guide for architecture and API references.【F:Docs/Guides/DeveloperOnboarding.md†L1-L126】
- Capture design decisions in `Docs/Architecture/README.md` and DocC catalogs as you implement features.【F:README.md†L5-L41】
- Document new workflows in `Docs/Manuals` or task-specific notes under `DOCS/TASK_ARCHIVE/`.【F:README.md†L5-L41】

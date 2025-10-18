# App Icon Asset Update

## Overview
- The automated rasterization workflow (`scripts/generate_app_icon.py`) and its CI-exercised verification tests were removed.
- The application now ships a manually maintained `AppIcon.icon` resource inside the Xcode project, keeping the asset catalog in sync without generated PNG variants.
- Local and CI build steps no longer regenerate PNGs on demand; icon updates are performed by replacing the committed `.icon` asset directly.

## Implementation Notes
- Deleted the Python generator along with the `AppIconAssetTests` XCTest guard that enforced filename conventions tied to generated outputs.
- Updated documentation to reflect the manual workflow and removed references to regenerating app icon PNGs as part of release automation.
- `AppIcon.appiconset/Contents.json` remains in source control for Xcode integration but no longer requires scripted filename rewrites.

## Follow-Up
- When the brand icon changes, update the `AppIcon.icon` source and validate previews in Xcode; no scripted steps are required.
- Consider trimming any lingering build scripts or CI hooks that referenced the deleted generator if they reappear in future branches.

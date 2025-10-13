# Task Summary

- Restored `ParseTreeStore` failure handling so error states now include both localized and descriptive messages, ensuring UI assertions can surface underlying errors.
- Prevented `ParseTreeStreamingSelectionAutomationTests` from over-fulfilling its expectations by deduplicating detail emissions during streaming UI updates.
- Added main-thread shortcuts in `DocumentSessionController` and updated tests to await parse completion, eliminating race conditions around recents bookkeeping.
- Adjusted the outline view model to respect manual collapse state across rebuilds and aligned accessibility severity

  strings with formatter expectations.

- Verified changes via `swift test`.

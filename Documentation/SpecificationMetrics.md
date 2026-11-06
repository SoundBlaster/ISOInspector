# SpecificationMetrics

The [SpecificationMetrics](https://github.com/SoundBlaster/SpecificationMetrics)
workflow measures `Sources/` and `FoundationUI/Sources/` as production code.
Tests, examples, build products, documentation samples and other paths are
outside this cohort. The committed scope manifest is the source of truth.

On a pull request, the workflow collects both the event's base and head
revisions with the same config and produces a diagnostic comparison. On a
push to `main` or manual dispatch it measures the selected revision on both
sides. The Actions job summary displays S, U, S/U, collection statuses and
source locations; the downloadable artifact contains both snapshots, full
comparison, scope, config, provenance and the analyzer's exact commit. It does
not post a PR comment. Artifacts expire after 30 days.
If collection fails, an artifact can contain only partial evidence. Its
provenance records `collection_execution = started` until comparison and
rendering finish; `completed` describes the process, not metric readiness.

The config and scope used on both sides come from the workflow checkout; a PR
that changes them changes the cohort for both measurements. Review those files
as measurement policy. The workflow reads PR sources as data and does not
execute them. Its GitHub token has read-only contents access.
When a SpecificationMetrics update is merged upstream, prepare a focused pin
update for this workflow and validate its reports on both sides of a PR.

S counts recognized Specification declarations under the scanner's liveness
rules. U counts syntactic candidates; it does not assert that every condition
needs a Specification. Unknown liveness stays counted. `provisional` means the
result needs review, for example when Swift parsing reports errors. The summary
shows diagnostic counts and the JSON contains file-level details. Do not use
provisional totals as an authoritative baseline or compare different scope
contracts. Zero S does not establish absence of all possible Specifications.

Python CC/Cog and optional clone detection are disabled for this Swift pilot.
The scanner does not currently provide Swift CC/Cog through that adapter;
the existing Swift duplication workflow remains a separate observation. Metric
values are informational and do not gate code quality or merge readiness.

For the initial `main` snapshot `14c161f6d3989f18e1a4d4c3af2bb495ea8b8c38`,
local collection with analyzer `38091108bc18056e345599ed8eb14bd0fb9e563a`
included 290 application files and yielded S = 0, U = 2120. **This is
provisional:** 12 files had Swift parse issues. It is not evidence of source
errors or a reliable whole-project Specification count. PR #1112 is not part
of that snapshot. Review the recorded parse diagnostics before using this
measurement as a baseline.

# Next Tasks — G3 Expose CLI Sandbox Profile Guidance

- [ ] **In Progress** — Implement Task G4 zero-trust logging so CLI sandbox runs emit hashed telemetry and can be audited alongside bookmark activations. Coordinate with FilesystemAccessKit logging design to avoid duplicating scope identifiers. (Tracking in `DOCS/INPROGRESS/G4_Zero_Trust_Logging.md`.)
- [ ] Add end-to-end tests that exercise the `--open`/`--authorize` flags once automation harnesses land, ensuring bookmark resolution failures surface actionable errors.
- [ ] Capture notarized distribution example (DMG/ZIP) that bundles the sandbox profile and document the verification checklist in release notes.

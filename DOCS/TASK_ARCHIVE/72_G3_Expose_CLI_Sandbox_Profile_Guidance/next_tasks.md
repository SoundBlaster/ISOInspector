# Next Tasks — G3 Expose CLI Sandbox Profile Guidance

- [ ] Implement Task G4 zero-trust logging so CLI sandbox runs emit hashed telemetry and can be audited alongside bookmark activations. Coordinate with FilesystemAccessKit logging design to avoid duplicating scope identifiers.
- [ ] Add end-to-end tests that exercise the `--open`/`--authorize` flags once automation harnesses land, ensuring bookmark resolution failures surface actionable errors.
- [ ] Capture notarized distribution example (DMG/ZIP) that bundles the sandbox profile and document the verification checklist in release notes.

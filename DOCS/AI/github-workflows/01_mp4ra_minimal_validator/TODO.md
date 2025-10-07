# TODO: Integrate Minimal MP4RA JSON Validator

- [ ] Add the validator script to the repo at `scripts/validate_mp4ra_minimal.py`.
- [ ] Make the script executable: `chmod +x scripts/validate_mp4ra_minimal.py` (optional on Windows).
- [ ] Create a GitHub Actions workflow `.github/workflows/validate-mp4ra-minimal.yml`:

  ```yaml
  name: Validate MP4RA Catalog (Minimal)

  on:
    pull_request:
      paths:
        - 'MP4RABoxes.json'
        - 'scripts/validate_mp4ra_minimal.py'
    push:
      branches: [ main ]
      paths:
        - 'MP4RABoxes.json'
        - 'scripts/validate_mp4ra_minimal.py'

  jobs:
    validate:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: actions/setup-python@v5
          with:
            python-version: '3.12'
        - name: Run minimal validator
          run: python scripts/validate_mp4ra_minimal.py MP4RABoxes.json
  ```

- [ ] (Optional) Add a pre-commit hook to run the validator locally before commits.
- [ ] Document the maintenance flow in `README.md` (how to update MP4RA snapshot and run the validator).
- [ ] (Optional) Add a `make validate` target to ease local usage:

  ```makefile
  validate:
  	python scripts/validate_mp4ra_minimal.py MP4RABoxes.json
  ```

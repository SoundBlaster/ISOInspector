# 06 — Markdown Title Rules

## ✅ Required Rules

1. **Don’t use `"` characters in headings or titles.** They cause markdownlint to fail during CI. Keep headings plain text or use other punctuation when emphasis is needed.
   - Example CI failure message:

     ```text
     Error: DOCS/INPROGRESS/15_Monitor_VR006_Research_Log_Adoption.md:3 MD022/blanks-around-headings/blanks-around-headers Headings should be surrounded by blank lines [Expected: 1; Actual: 0; Below] [Context: "## 🎯 Objective"] https://github.com/DavidAnson/markdownlint/blob/v0.31.1/doc/md022.md
     ```

## 📌 Scope

These rules apply to every Markdown file in the repository, especially content under `DOCS/**` that participates in automated linting.

## 🛠 Recommended Practice

- Prefer descriptive wording or emojis instead of quotes when highlighting phrases.
- Run `python scripts/fix_markdown.py` before committing to normalize spacing around headings and lists.
- Validate with `markdownlint-cli2` locally if you introduce new heading patterns.

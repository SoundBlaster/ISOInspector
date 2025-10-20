# 05 — Markdown Style & Lint Rule

> ⚠️ **Status: Disabled** — This rule is temporarily paused while repository Markdown linting is turned off in CI. Retain the guidance for future reactivation. The legacy helper script `scripts/fix_markdown.py` has been retired and now acts as a no-op placeholder.

## 🧩 Purpose

Uniform Markdown style for all project docs and strict post-generation validation. The goal is for every
`DOCS/**` file to pass **markdownlint** checks when the rule is active again.

## 🔧 Enforcement Scope

Applies to all `.md` files in:

- `DOCS/INPROGRESS/**`
- `DOCS/COMMANDS/**`
- `DOCS/RULES/**`

## 📐 Style Rules (what the linter enforces)

1. **Headings** are surrounded by blank lines above and below. (**MD022**)
1. **Lists** (bulleted and ordered) are surrounded by blank lines above and below. (**MD032**)
1. **Fenced code blocks**:
   - Have a blank line before and after. (**MD031**)
   - Must specify a language after opening backticks (e.g., use fences like `\`\`\`md`, `\`\`\`bash`, `\`\`\`json`). (**MD040**)
1. **Single top-level heading (H1)** per file when a title is present. (**MD025**)
1. **Single trailing newline** at end of file—exactly one. (**MD047**)
1. **Ordered lists** may consistently use the `1.` style for all items. (**MD029**)
1. **Never simulate headings with emphasis.** Full-line italics/bold that read like a heading should be rewritten as

   real

   headings or plain sentences. (**MD036**)

> ℹ️ While line length is no longer lint-enforced, prefer natural sentence wrapping for readability. Leave list items unwrapped when longer context improves clarity.

## ⚙️ Linter Configuration

Create or update `.markdownlint.jsonc` at the repo root (line-length rule disabled to avoid unnecessary wrapping of narrative and list content):

```jsonc
{
  "default": true,

  "MD013": false,

  "MD025": { "level": 1 },
  "MD040": true,
  "MD022": true,
  "MD032": true,
  "MD031": true,
  "MD047": true,
  "MD029": { "style": "one" },
  "MD036": true
}

```

## 🤖 Agent Behavior (required sequence)

**Triggers:** Creating or modifying any `*.md` under the enforced paths.

**Agent must:**

1. **Auto-fix style (idempotent, when practical):**
   - Normalize newlines to `\n` and ensure exactly one trailing newline.
   - Insert blank lines around headings.
   - Insert blank lines around lists.
   - Insert blank lines around fenced code blocks.
   - Ensure fenced code blocks specify a language (use `text` if unknown).
   - Normalize ordered lists to the `1.` style.
   - Replace emphasis-only pseudo-headings with actual headings or plain sentences.

1. **Run markdownlint locally** on the three DOCS paths.

1. **Validate result:**
   - If any errors remain, attempt auto-fix again (up to 2 passes).
   - If errors still remain, **reject** the change (or mark task as “blocked”) and record a failure report with

     rule+line numbers.

   - If clean, proceed (commit/PR).

## 🧪 Local Check Command

```bash
npx markdownlint-cli2 "DOCS/INPROGRESS/**/*.md" "DOCS/COMMANDS/**/*.md" "DOCS/RULES/**/*.md"

```

## ✅ Definition of Done

- All touched `.md` files comply with `.markdownlint.jsonc`.
- `markdownlint-cli2` returns **0 errors** on the enforced paths.
- PR includes a successful linter log.

## 🚦 Optional GitHub Actions Snippet

```yaml
name: markdownlint
on:
  pull_request:
    paths:
      - 'DOCS/**.md'
      - '.markdownlint.jsonc'
  push:
    paths:
      - 'DOCS/**.md'
      - '.markdownlint.jsonc'

jobs:
  lint-md:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm i -g markdownlint-cli2
      - name: Run markdownlint
        run: |
          markdownlint-cli2 "DOCS/INPROGRESS/**/*.md" "DOCS/COMMANDS/**/*.md" "DOCS/RULES/**/*.md"

```

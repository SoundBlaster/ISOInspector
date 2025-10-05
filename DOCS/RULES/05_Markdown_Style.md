# 05 — Markdown Style & Lint Rule

## 🧩 Purpose

Uniform Markdown style for all project docs and strict post-generation validation. The goal is for every `DOCS/**` file to pass **markdownlint** checks.

## 🔧 Enforcement Scope

Applies to all `.md` files in:
- `DOCS/INPROGRESS/**`
- `DOCS/COMMANDS/**`
- `DOCS/RULES/**`

## 📐 Style Rules (what the linter enforces)

1. **Headings** are surrounded by blank lines above and below. (**MD022**)
2. **Lists** (bulleted and ordered) are surrounded by blank lines above and below. (**MD032**)
3. **Fenced code blocks**:
   - Have a blank line before and after. (**MD031**)
   - Must specify a language after opening backticks (e.g., ```md, ```bash, ```json). (**MD040**)
4. **Line length**:
   - Max 120 characters for normal text and list bodies. (**MD013**)
   - URLs and inline code may remain unwrapped (prefer keeping links intact).
5. **Single top-level heading (H1)** per file when a title is present. (**MD025**)
6. **Single trailing newline** at end of file—exactly one. (**MD047**)
7. **Ordered lists** may consistently use the `1.` style for all items. (**MD029**)

## ⚙️ Linter Configuration

Create or update `.markdownlint.jsonc` at the repo root:

```jsonc
{
  "default": true,

  "MD013": {
    "line_length": 120,
    "heading_line_length": 120,
    "code_blocks": false,
    "tables": false,
    "strict": false,
    "ignore_urls": true
  },

  "MD025": { "level": 1 },
  "MD040": true,
  "MD022": true,
  "MD032": true,
  "MD031": true,
  "MD047": true,
  "MD029": { "style": "one" }
}
```

## 🤖 Agent Behavior (required sequence)

**Triggers:** Creating or modifying any `*.md` under the enforced paths.

**Agent must:**

1. **Auto-fix style (idempotent):**
   - Normalize newlines to `\n` and ensure exactly one trailing newline.
   - Insert blank lines around headings.
   - Insert blank lines around lists.
   - Insert blank lines around fenced code blocks.
   - Ensure fenced code blocks specify a language (use `text` if unknown).
   - Soft-wrap long lines at 120 characters for paragraphs and list bodies; do **not** break URLs/inline code/tables/quotes.
   - Normalize ordered lists to the `1.` style.

2. **Run markdownlint locally** on the three DOCS paths.

3. **Validate result:**
   - If any errors remain, attempt auto-fix again (up to 2 passes).
   - If errors still remain, **reject** the change (or mark task as “blocked”) and record a failure report with rule+line numbers.
   - If clean, proceed (commit/PR).

## 🧪 Local Check Command

```bash
npx markdownlint-cli2 "DOCS/INPROGRESS/**/*.md" "DOCS/COMMANDS/**/*.md" "DOCS/RULES/**/*.md"
```

## 🛠 Recommended Auto-fix Script (reference)

Call an idempotent fixer before lint:
- Normalize trailing newline (MD047)
- Add blank lines for headings/lists/fences (MD022/MD032/MD031)
- Add language for code fences (MD040)
- Wrap long lines to 120, ignoring URLs/inline code/tables/quotes (MD013)
- Use `1.` for ordered lists (MD029)

*(If you already have a similar fixer, you can reuse it.)*

## ✅ Definition of Done

- All touched `.md` files comply with `.markdownlint.jsonc`.
- `markdownlint-cli2` returns **0 errors** on the enforced paths.
- PR includes a successful linter log.
- If MD013 remains due to unavoidable long URLs/tables, provide a short justification or rephrase text accordingly.

## 🚦 Optional GitHub Actions Snippet

```yaml
name: markdownlint
on:
  pull_request:
    paths:
      - 'DOCS/**.md'
      - '.markdownlint.jsonc'
      - 'scripts/fix_markdown.py'
  push:
    paths:
      - 'DOCS/**.md'
      - '.markdownlint.jsonc'
      - 'scripts/fix_markdown.py'

jobs:
  lint-md:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm i -g markdownlint-cli2
      - name: Auto-fix Markdown
        run: |
          python3 -V || sudo apt-get update && sudo apt-get install -y python3
          python3 scripts/fix_markdown.py || true
      - name: Run markdownlint
        run: |
          markdownlint-cli2 "DOCS/INPROGRESS/**/*.md" "DOCS/COMMANDS/**/*.md" "DOCS/RULES/**/*.md"
```

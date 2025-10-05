import re
from pathlib import Path

# ---- Настройки ----
GLOBS = [
    "DOCS/INPROGRESS/**/*.md",
    "DOCS/COMMANDS/**/*.md",
    "DOCS/RULES/**/*.md",
]
LINE_LIMIT = 120

# Регексы
RE_HEADING = re.compile(r"^(#{1,6})\s+")
RE_UL = re.compile(r"^([ \t]*)([-+*])\s+")
RE_OL = re.compile(r"^([ \t]*)(\d+)\.\s+")
RE_FENCE = re.compile(r"^```")
RE_TABLE = re.compile(r"^\s*\|")      # простая эвристика таблиц
RE_QUOTE = re.compile(r"^\s*>\s")     # цитаты
RE_URL = re.compile(r"https?://\S+")
RE_INLINE_CODE = re.compile(r"`[^`]*`")


def normalize_newlines(text: str) -> str:
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = re.sub(r"\s+\Z", "", text)  # срезаем хвостовые пробелы/переводы
    return text + "\n"                 # ровно один \n в конце (MD047)


def is_list_line(s: str) -> bool:
    return bool(RE_UL.match(s) or RE_OL.match(s))


def wrap_line(s: str, limit: int) -> list[str]:
    # Не переносим строки, если есть URL или инлайн-код (чтобы не ломать)
    if len(s) <= limit or RE_URL.search(s) or RE_INLINE_CODE.search(s):
        return [s]
    # мягкий перенос по пробелам
    out, cur = [], []
    length = 0
    words = re.split(r"(\s+)", s)  # сохраняем пробелы как токены
    for w in words:
        wlen = len(w)
        if length + wlen > limit and cur:
            out.append("".join(cur).rstrip())
            cur = [w.lstrip()]
            length = len(cur[0])
        else:
            cur.append(w)
            length += wlen
    if cur:
        out.append("".join(cur).rstrip())
    return out


def process_file(path: Path) -> bool:
    raw = path.read_text(encoding="utf-8")
    text = normalize_newlines(raw)
    lines = text.split("\n")

    # Первая проходка: добавить пустые строки вокруг заголовков и фенсов
    out = []
    in_fence = False
    for i, line in enumerate(lines):
        next_line = lines[i + 1] if i + 1 < len(lines) else ""

        if RE_FENCE.match(line):
            if out and out[-1] != "":
                out.append("")
            out.append(line)
            in_fence = not in_fence
            continue

        if RE_HEADING.match(line) and not in_fence:
            if out and out[-1] != "":
                out.append("")
            out.append(line)
            if next_line != "" and not RE_FENCE.match(next_line):
                out.append("")
            continue

        out.append(line)

    lines = out

    # Вторая проходка: пустые строки вокруг списков и после закрывающих фенсов
    out = []
    in_fence = False
    i = 0
    while i < len(lines):
        line = lines[i]
        if RE_FENCE.match(line):
            if in_fence:
                out.append(line)
                in_fence = False
                if i + 1 < len(lines) and lines[i + 1] != "":
                    out.append("")
            else:
                out.append(line)
                in_fence = True
            i += 1
            continue

        if not in_fence and is_list_line(line):
            if out and out[-1] != "":
                out.append("")
            j = i
            while j < len(lines) and is_list_line(lines[j]):
                out.append(lines[j])
                j += 1
            if j < len(lines) and lines[j] != "":
                out.append("")
            i = j
            continue

        out.append(line)
        i += 1

    lines = out

    # Третья проходка: перенос длинных строк (MD013)
    out = []
    in_fence = False
    for line in lines:
        if RE_FENCE.match(line):
            in_fence = not in_fence
            out.append(line)
            continue
        if in_fence or RE_TABLE.match(line) or RE_QUOTE.match(line):
            out.append(line)
            continue

        if RE_HEADING.match(line):
            out.append(line)
            continue

        m_ul = RE_UL.match(line)
        m_ol = RE_OL.match(line)
        if m_ul:
            indent, bullet = m_ul.groups()
            body = line[m_ul.end():].strip()
            wrapped = wrap_line(body, LINE_LIMIT - len(indent) - len(bullet) - 1)
            if wrapped:
                out.append(f"{indent}{bullet} {wrapped[0]}")
                for w in wrapped[1:]:
                    out.append(f"{indent}  {w}")
            else:
                out.append(line)
            continue
        if m_ol:
            indent, num = m_ol.groups()
            body = line[m_ol.end():].strip()
            prefix = f"{indent}1."
            wrapped = wrap_line(body, LINE_LIMIT - len(prefix) - 1)
            if wrapped:
                out.append(f"{prefix} {wrapped[0]}")
                for w in wrapped[1:]:
                    out.append(f"{indent}   {w}")
            else:
                out.append(f"{prefix} {body}" if body else f"{prefix}")
            continue

        if len(line) > LINE_LIMIT:
            for w in wrap_line(line, LINE_LIMIT):
                out.append(w)
        else:
            out.append(line)

    fixed = "\n".join(out)
    fixed = normalize_newlines(fixed)

    if fixed != raw:
        path.write_text(fixed, encoding="utf-8")
        return True
    return False


def main():
    changed = 0
    files: list[Path] = []
    for g in GLOBS:
        files += list(Path(".").glob(g))
    files = [p for p in files if p.is_file()]

    for p in files:
        if process_file(p):
            changed += 1
            print(f"fixed: {p}")

    print(f"done. files changed: {changed}")


if __name__ == "__main__":
    main()

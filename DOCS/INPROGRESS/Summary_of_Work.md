# Summary of Work — C10 `stco/co64` Chunk Offset Parser

## ✅ Completed

- Updated the chunk offset parser to display each offset as decimal plus hexadecimal, preserving width for `stco` (32-bit) and `co64` (64-bit) entries in box field details.
- Extended unit coverage (`StcoChunkOffsetParserTests`) to assert the new formatting for 32-bit, 64-bit, and truncated tables.
- Refreshed JSON snapshot fixtures so baseline exports now include the dual-format chunk offset values.

## 🧪 Validation

- `swift test`

## 🔜 Follow-Up

- Implement validation rule #15 to correlate chunk offsets with `stsc` chunk runs and `stsz/stz2` sample sizes (`todo.md` item #15).


# 📘 AI Agent Guide — Open ISO BMFF (MP4/MOV) Reverse Engineering Sources

## 🧭 Purpose
Guidance for AI Agents to analyze and reconstruct **ISO Base Media File Format (MP4/MOV/QuickTime)** structures using open and free sources — without relying on paid ISO/IEC 14496 standards.

---

## 🧩 1. Core Standards Mapping

| Topic | Official ISO Doc | Free & Open Equivalent |
|--------|------------------|------------------------|
| File structure & boxes | ISO/IEC 14496‑12 | Apple QuickTime File Format, Bento4, FFmpeg, GPAC |
| MP4 extensions | ISO/IEC 14496‑14 | MP4RA Registry + Bento4 |
| AVC/HEVC codecs | ISO/IEC 14496‑15 | FFmpeg/x264, Bento4 |
| Brands | Annex E of ISO BMFF | MP4RA.org |
| Fragments | §8 ISO BMFF | Bento4 + GPAC |
| Metadata | QuickTime atoms | Apple Docs + FFmpeg |

---

## 🧱 2. Reference Implementations

### Bento4
- https://github.com/axiomatic-systems/Bento4  
- Apache 2.0 License — cleanest reference for atoms.
- Inspect: `Ap4Atom.cpp`, `Ap4ContainerAtom.cpp`, `Ap4AtomFactory.cpp`.

### FFmpeg
- https://github.com/FFmpeg/FFmpeg  
- LGPL 2.1 — exhaustive box list.  
- Inspect: `libavformat/isom.c`, `mov.c`, `mov_chan.c`.

### GPAC (MP4Box)
- https://github.com/gpac/gpac  
- LGPL — fragmentation logic and hint tracks.  
- Inspect: `src/isomedia/isom_read.c`, `box_code_meta.c`.

### Apple QuickTime File Format
- https://developer.apple.com/library/archive/documentation/QuickTime/QTFF/QTFFChap1/qtff1.html  
- Historical but accurate for base atoms.

### MP4RA Registry
- https://mp4ra.org/#/  
- Canonical FourCC and UUID database.

### W3C ISO BMFF Byte Stream Format
- https://www.w3.org/TR/mse-byte-stream-format-isobmff/  
- Useful for fragment-level analysis.

---

## ⚙️ 3. Strategy by Task

| Task | Sources | Agent Instructions |
|------|----------|-------------------|
| Rebuild box tree | Bento4, FFmpeg | Extract atom structs → Swift equivalents. |
| Validate nesting | Bento4, GPAC | Model parent–child maps. |
| Handle fragments | GPAC, Bento4 | Read `moof`, `traf`, `trun`. |
| Detect codecs | MP4RA, RFC 6381 | Map `ftyp` brands + `codecs=` param. |
| Decode metadata | QuickTime Spec | Analyze `meta` / `ilst`. |
| Optimize performance | FFmpeg, GPAC | Copy I/O buffering strategies. |

---

## 🔐 4. Legal & Ethical Rules

| Rule | Description |
|------|--------------|
| Attribution | Always cite repo + file path. |
| Licensing | Respect Apache/LGPL; don’t redistribute closed code. |
| Reverse Engineering | Allowed if based on open code. |
| Documentation | Maintain traceability (commit hash). |
| Commercial Use | Only combine compatible licenses. |

---

## 🧠 5. Retrieval Patterns

### Example Queries
```text
site:github.com/axiomatic-systems/Bento4 "AP4_Atom" filename:Ap4*
site:github.com/FFmpeg/FFmpeg mov_default_parse_table
site:github.com/gpac/gpac gf_isom_parse_movie_fragment
```

### Web APIs
- MP4RA JSON endpoint for FourCC registry.
- FFmpeg and Bento4 GitHub API for file browsing.

---

## 🧰 6. Tooling

| Tool | Usage |
|------|--------|
| ffprobe | `ffprobe -show_boxes file.mp4` |
| MP4Box | `MP4Box -info file.mp4` |
| mp4dump | `mp4dump --format json` |
| jq | JSON diff validation |

---

## 🧭 7. Fallback Path When ISO Spec Needed
1. Compare Bento4 + FFmpeg + QuickTime → >99% overlap.  
2. Validate box codes via MP4RA.  
3. Never quote from ISO PDFs.

---

## ✅ Summary
AI Agents can reconstruct **MP4/ISO BMFF** fully from open codebases:  
- **Bento4** → structure & hierarchy.  
- **FFmpeg** → completeness & real-world handling.  
- **MP4RA** → canonical FourCCs.  
- **Apple QTFF** → conceptual explanation.

All without breaching ISO copyright.

---

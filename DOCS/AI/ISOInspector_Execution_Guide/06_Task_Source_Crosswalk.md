# ISOInspector Task-to-Source Crosswalk

Справочник сопоставляет задачи из `ISOInspector_Execution_Guide` с открытыми источниками из `02_ISOInspector_AI_Source_Guide.md`. Для каждого пункта из оригинальных документов приведены рекомендации по использованию доступных стандартов, репозиториев и инструментов.

## 1. `01_Project_Scope.md`
### 1.1 Deliverables
1. **ISOInspectorCore — Streaming ISO BMFF parser, validator, and metadata exporter**.【F:DOCS/AI/ISOInspector_Execution_Guide/01_Project_Scope.md†L6-L13】
   - Источники:
     1. Core Standards Mapping — File structure & boxes → Apple QuickTime File Format, Bento4, FFmpeg, GPAC.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L9-L18】
     2. Reference Implementations — Bento4 atom classes; FFmpeg `mov.c` для полного перечня боксов.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L24-L33】
     3. Strategy by Task — Rebuild box tree; Validate nesting; Handle fragments (Bento4, FFmpeg, GPAC).【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L60】
2. **ISOInspectorUI — SwiftUI component library for tree, detail, and hex visualization**.【F:DOCS/AI/ISOInspector_Execution_Guide/01_Project_Scope.md†L6-L13】
   - Источники:
     1. Strategy by Task — Rebuild box tree (Bento4, FFmpeg) для структуры дерева в UI.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L58】
     2. Strategy by Task — Decode metadata (QuickTime Spec) для заполнения панели деталей.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L62】
     3. Reference Implementations — MP4RA registry для отображения названий FourCC.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L43-L46】
3. **ISOInspectorCLI — Command-line interface wrapping the core parser**.【F:DOCS/AI/ISOInspector_Execution_Guide/01_Project_Scope.md†L6-L13】
   - Источники:
     1. Strategy by Task — Detect codecs (MP4RA, RFC 6381) для отчётов CLI.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L61】
     2. Tooling — ffprobe, MP4Box, mp4dump для примеров вывода и валидации CLI экспортов.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L95-L100】
     3. Reference Implementations — FFmpeg CLI поведение (`mov.c`) как эталон обработки ошибок.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L29-L33】
4. **ISOInspectorApp — macOS + iPadOS + iOS app integrating core and UI packages**.【F:DOCS/AI/ISOInspector_Execution_Guide/01_Project_Scope.md†L6-L13】
   - Источники:
     1. Core Standards Mapping — Fragments → Bento4 + GPAC для поддержки потоковых сценариев в приложении.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L13-L18】
     2. Strategy by Task — Handle fragments (GPAC, Bento4) для визуализации `moof/traf` сессий.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L60】
     3. Reference Implementations — W3C ISO BMFF Byte Stream Format для потоковых источников.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L47-L49】
5. **Documentation Suite — Developer onboarding, API reference, and user guides**.【F:DOCS/AI/ISOInspector_Execution_Guide/01_Project_Scope.md†L6-L13】
   - Источники:
     1. Legal & Ethical Rules — требования по атрибуции и лицензированию для документации.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L66-L75】
     2. Summary — Ключевые репозитории (Bento4, FFmpeg, MP4RA, Apple QTFF) как основа для разделов справочника.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L111-L118】

### 1.2 Success Criteria
- **Stream-parse files up to 20 GB; memory <100 MB; latency <200 ms**.【F:DOCS/AI/ISOInspector_Execution_Guide/01_Project_Scope.md†L15-L20】
  - Strategy by Task — Optimize performance (FFmpeg, GPAC) для буферизации и потоков.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L62】
- **100% automated test coverage; CI pipeline with build/test/lint/docs**.【F:DOCS/AI/ISOInspector_Execution_Guide/01_Project_Scope.md†L15-L20】
  - Reference Implementations — FFmpeg, Bento4 как база для тестовых сценариев; Tooling — `mp4dump`, `ffprobe` для проверок.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L24-L33】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L95-L100】

### 1.3 External Dependencies & Risks
- **ISO/IEC 14496-12 + MP4RA registry** как внешние зависимости.【F:DOCS/AI/ISOInspector_Execution_Guide/01_Project_Scope.md†L34-L39】
  - Core Standards Mapping — указывает бесплатные аналоги (QuickTime, Bento4, FFmpeg, GPAC, MP4RA).【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L9-L18】
- **Mitigation for vendor-specific atoms via research log**.【F:DOCS/AI/ISOInspector_Execution_Guide/01_Project_Scope.md†L41-L46】
  - Strategy by Task — Decode metadata (QuickTime Spec) и Detect codecs (MP4RA) для обработки нестандартных боксов.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L61】

## 2. `02_Product_Requirements.md`
### 2.1 Functional Requirements
1. **FR-CORE-001 — Streaming parse without full memory load**.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L6-L13】
   - Strategy by Task — Optimize performance (FFmpeg, GPAC) для буферизации; Reference Implementations — Bento4 потоковое чтение.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L24-L37】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L62】
2. **FR-CORE-002 — Validate box structure and hierarchy**.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L6-L13】
   - Strategy by Task — Validate nesting (Bento4, GPAC).【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L59】
3. **FR-CORE-003 — Catalog atom types using MP4RA metadata**.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L6-L13】
   - Reference Implementations — MP4RA registry entries; Strategy by Task — Detect codecs (MP4RA, RFC 6381).【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L43-L46】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L61】
4. **FR-CORE-004 — Export parse results as JSON/binary**.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L6-L13】
   - Tooling — `mp4dump --format json`, `jq` как эталон форматов и валидации.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L95-L100】
5. **FR-UI-001 — Hierarchical tree with search/filter**.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L13-L18】
   - Strategy by Task — Rebuild box tree (Bento4, FFmpeg) для структуры; Decode metadata (QuickTime Spec).【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L62】
6. **FR-UI-002 — Detail pane with metadata, hex viewer, validation**.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L13-L18】
   - Reference Implementations — Bento4 и QuickTime spec для полей; Strategy — Decode metadata.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L24-L41】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L62】
7. **FR-UI-003 — Session bookmarking and annotations**.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L13-L18】
   - Strategy by Task — Decode metadata (QuickTime) и Validate nesting для корректного сопоставления узлов.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L62】
8. **FR-CLI-001 / FR-CLI-002 — CLI commands and batch mode**.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L16-L18】
   - Tooling — ffprobe, MP4Box, mp4dump как ориентиры для интерфейса и отчётов.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L95-L100】
9. **FR-APP-001 — App shell with persistence**.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L18-L19】
   - Core Standards Mapping — Fragments (Bento4 + GPAC) для поддержки потоков и продолжения сессий.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L13-L18】
10. **FR-DOC-001 — Documentation suite**.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L19-L19】
    - Legal & Ethical Rules — требования по атрибуции; Summary — ключевые открытые источники для ссылок.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L66-L75】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L111-L118】

### 2.2 Non-Functional Requirements
- **NFR-PERF-001 / NFR-PERF-002 — Latency и throughput**.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L21-L27】
  - Strategy by Task — Optimize performance (FFmpeg, GPAC) и Reference Implementations для буферизации.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L24-L37】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L62】
- **NFR-RELI-001 — Robustness to malformed input**.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L26-L27】
  - Strategy by Task — Validate nesting; Handle fragments для устойчивости к ошибкам структуры.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L60】
- **NFR-USAB-001 — Accessibility**.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L27-L28】
  - Reference Implementations — Apple QuickTime doc для терминологии, MP4RA для точных названий в UI.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L39-L46】
- **NFR-SEC-001 — Offline & sandboxed**.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L28-L29】
  - Tooling — локальные утилиты (`ffprobe`, `mp4dump`) без сетевого доступа.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L95-L100】
- **NFR-MAINT-001 / NFR-DOC-001 — Coverage & docs**.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L29-L30】
  - Legal & Ethical Rules и Summary — подсказки по документированию открытых источников.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L66-L75】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L111-L118】

### 2.3 Flows, Edge Cases, Compliance
- **GUI/CLI/Metadata flows** используют MP4RA и Bento4 для справки по событиям и типам.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L32-L53】
  - Strategy by Task — Detect codecs, Decode metadata, Handle fragments.【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L62】
- **Edge cases (truncated boxes, unknown types, encrypted payloads)** требуют ссылок на Bento4/FFmpeg/MP4RA для обработчиков и классификации.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L55-L63】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L24-L46】
- **Compliance & Accessibility** — использовать QuickTime/MP4RA терминологию и юридические правила атрибуции.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L65-L69】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L39-L75】

## 3. `03_Technical_Spec.md`
### 3.1 Architecture & Modules
- **Слоистая архитектура Core/UI/CLI/App** требует источников по структуре боксов и потокам событий.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L3-L10】
  - Core Standards Mapping и Strategy by Task (Rebuild box tree, Validate nesting, Handle fragments).【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L9-L18】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L60】
- **Module Responsibilities**: Core.Parser и Core.Validation ссылаются на ISO/IEC 14496-12 → бесплатные аналоги (Bento4, FFmpeg, GPAC).【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L12-L25】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L13-L37】
- **Core.Metadata** поддерживается MP4RA registry; **UI.Detail** — QuickTime spec для метаданных.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L12-L25】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L39-L46】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L62】

### 3.2 Data Flow & Event Model
- **Streaming ingestion, parse pipeline, validation chain** опираются на стратегии Rebuild box tree, Validate nesting и Handle fragments из Bento4/FFmpeg/GPAC.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L27-L48】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L60】
- **Parsing algorithms** (large size, uuid, контейнеры) — использовать Core Standards Mapping и Reference Implementations как примеры реализации.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L50-L57】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L13-L37】
- **Validation Rules VR-001…VR-006** напрямую соотносятся с Validate nesting, Detect codecs, Decode metadata и MP4RA registry.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L59-L67】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L43-L62】

### 3.3 Quality, Packaging, Documentation
- **Concurrency, Error handling, Testing** — применять источники по оптимизации и эталонным реализациям (Bento4, FFmpeg, GPAC).【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L69-L88】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L24-L37】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L62】
- **Instrumentation & Tooling** — использовать рекомендованные утилиты (`ffprobe`, `MP4Box`, `mp4dump`, `jq`).【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L90-L99】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L95-L100】
- **Documentation strategy** — руководствоваться Legal & Ethical Rules и Summary для корректных ссылок на открытые источники.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L101-L105】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L66-L118】

## 4. `04_TODO_Workplan.md`
### 4.1 Phase A — Foundations & Infrastructure
- **A1–A3** (workspace, CI, DocC) требуют ссылок на Legal & Ethical Rules для лицензий и Tooling для интеграции статических анализаторов.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L5-L10】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L66-L100】

### 4.2 Phase B — Core Parsing Engine
- **B1 — Chunked file reader** ↔ Optimize performance (FFmpeg, GPAC).【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L20】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L29-L37】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L62】
- **B2 — Box header decoder** ↔ Rebuild box tree (Bento4, FFmpeg).【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L20】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L24-L33】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L58】
- **B3 — Streaming parse pipeline** ↔ Validate nesting & Handle fragments (Bento4, GPAC).【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L20】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L60】
- **B4 — MP4RA catalog integration** ↔ MP4RA registry и Detect codecs задача.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L20】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L43-L46】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L61】
- **B5 — Validation rules VR-001…VR-006** ↔ Strategy by Task (Validate nesting, Detect codecs) и Reference Implementations для примеров ошибок.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L20】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L24-L62】
- **B6 — JSON/binary export modules** ↔ Tooling `mp4dump`, `jq` и Reference Implementations для форматов отчётов.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L20】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L29-L33】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L95-L100】

### 4.3 Phase C — User Interface Package
- **C1–C5** (Combine bridge, tree view, detail pane, annotations, accessibility) ↔ Rebuild box tree, Decode metadata, MP4RA registry и QuickTime spec для названий и структуры UI, плюс Legal & Ethical Rules для отображения лицензий в документации UI.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L22-L29】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L39-L62】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L66-L75】

### 4.4 Phase D — CLI Interface
- **D1–D4** (CLI scaffold, commands, exports, batch mode) ↔ Tooling (ffprobe, MP4Box, mp4dump) и Strategy — Detect codecs/Handle fragments для соответствия поведения существующим инструментам.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L31-L37】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L61】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L95-L100】

### 4.5 Phase E — Application Shell
- **E1–E4** (app shell, pipeline integration, session persistence, distribution) ↔ Core Standards Mapping для фрагментов, Strategy — Handle fragments, Reference Implementations — W3C byte-stream guidance для потокового воспроизведения и Legal & Ethical Rules для пакета приложения.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L39-L45】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L13-L49】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L66-L75】

### 4.6 Phase F — Quality Assurance & Documentation
- **F1–F5** (fixtures, benchmarks, guides, manuals, release checklist) ↔ Reference Implementations (Bento4, FFmpeg) для образцов, Tooling (`ffprobe`, `mp4dump`, `jq`) для валидации, Legal & Ethical Rules и Summary для документации и лицензий.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L47-L54】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L24-L118】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L95-L100】

## 5. `05_Research_Gaps.md`
### 5.1 Open Research Tasks
- **R1 — MP4RA Synchronization** ↔ MP4RA registry и Detect codecs стратегия для автоматизации обновлений.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L5-L14】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L43-L61】
- **R2 — Fixture Acquisition** ↔ Reference Implementations (Bento4, FFmpeg, GPAC) и Tooling (`ffprobe`, `MP4Box`) для анализа образцов.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L5-L14】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L24-L37】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L95-L99】
- **R3 — Accessibility Guidelines** ↔ QuickTime spec и MP4RA для точных меток UI; Legal & Ethical Rules для корректных ссылок.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L5-L14】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L39-L46】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L66-L75】
- **R4 — Large File Performance Benchmarks** (Completed — see `DOCS/TASK_ARCHIVE/93_R4_Large_File_Performance_Benchmarks/R4_Large_File_Performance_Benchmarks.md`) ↔ Optimize performance стратегия (FFmpeg, GPAC) и Tooling (`mp4dump`) для тестов.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L5-L14】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L29-L37】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L62】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L95-L100】
- **R5 — Export Schema Standardization** ↔ Tooling `mp4dump --format json`, `jq` и Reference Implementations (Bento4) для существующих JSON схем.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L5-L14】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L24-L33】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L95-L100】
- **R6 — Annotation Persistence Strategy** ↔ Decode metadata/Validate nesting для корректного сопоставления узлов и Legal & Ethical Rules для хранения пользовательских данных.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L5-L14】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L55-L62】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L66-L75】
- **R7 — CLI Distribution** ↔ Tooling (ffprobe, MP4Box) как ориентир для распространения и Legal & Ethical Rules для соблюдения лицензий.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L5-L14】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L66-L100】

### 5.2 Tracking & Reporting
- **Поддерживайте связь с Workplan** через таблицу прогресса и используйте Summary источников для фиксирования в итоговой документации.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L16-L19】【F:DOCS/AI/02_ISOInspector_AI_Source_Guide.md†L111-L118】

## 6. `09_FilesystemAccessKit_PRD.md`
- **FilesystemAccessKit Objectives FS-OBJ-01…04** ↔ Apple App Sandbox Design Guide и Security-Scoped Bookmark документация для реализации open/save/bookmark API с единой абстракцией.【F:DOCS/AI/ISOInspector_Execution_Guide/09_FilesystemAccessKit_PRD.md†L5-L24】【F:DOCS/AI/ISOInspector_Execution_Guide/09_FilesystemAccessKit_PRD.md†L33-L45】
- **Dependencies & Research** ↔ Task E4 архив (entitlements) и Apple UIDocumentPicker руководства для платформенных адаптеров.【F:DOCS/AI/ISOInspector_Execution_Guide/09_FilesystemAccessKit_PRD.md†L33-L45】【F:DOCS/TASK_ARCHIVE/55_E4_Prepare_App_Distribution_Configuration/54_E4_Prepare_App_Distribution_Configuration.md†L1-L47】
- **Implementation Plan P1–P5** ↔ Workplan Phase G задачам (G1–G4) и CLI sandbox профилям; следите за соответствием в `DOCS/INPROGRESS/next_tasks.md`.【F:DOCS/AI/ISOInspector_Execution_Guide/09_FilesystemAccessKit_PRD.md†L47-L70】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L75-L92】

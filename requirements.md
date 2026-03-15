# Requirements: SysML v2 LSP MCP extension (project scope + impact/rename/context)

Model-first: these requirements drive the SysML model and the implementation plan. Reference: [SYSML_V2_LSP_MCP_EXTENSION_ANALYSIS.md](../../../docs/SYSML_V2_LSP_MCP_EXTENSION_ANALYSIS.md).

---

## 0. Are these what we need? Do they improve efficiency?

**The SysML modeling job in this repo:** Refactor shared libs (`libs/common/parts/*.sysml`, `connections.sysml`), rename part/port/connection defs, add or remove ports, and keep multiple projects (foam, online-liquid, auto-inplaced, etc.) consistent. One lib change can touch 15–25+ files. Today: grep + open files + manual check; rename = find-replace or edit each file by hand. Risk: missing a reference → broken BDD/IBD or subtle inconsistency.

| What we need for the job | In our requirements? | Efficiency impact |
|--------------------------|------------------------|-------------------|
| **“Load this project so I can ask cross-file questions”** | Yes — loadProject | **High.** Without: agent must parse N files one-by-one (N MCP calls). With: one loadProject → full graph. Saves time and makes impact/rename possible. |
| **“If I change or rename X, what breaks?”** | Yes — impact | **High.** Without: grep + open each file. With: one impact(symbol) → list of refs and URIs. Fewer missed refs, faster review. |
| **“Rename X to Y everywhere, safely”** | Yes — rename (dry_run) | **High.** Without: find-replace (risky) or manual edits. With: rename(symbol, newName, dryRun=true) → review edits → apply. Safer and faster for multi-file renames. |
| **“Tell me everything about this symbol in one shot”** | Yes — context (R2.5) | **Medium.** One call: definition + refs (in) + what it references (out) + hierarchy. Clearer for human and agent before editing. |
| **“Find symbols by name or kind”** | Optional — query | **Low–medium.** Grep can do name; query is structured and can filter by kind. Nice for discovery. |
| **“What changed since last load?”** | No — detect_changes | **Low** for typical flow. Out of scope for first phase. |
| **“Custom graph query”** | No — cypher | **Low** for now. Out of scope for first phase. |

**Verdict:** We need loadProject, impact, rename, and **context**. They improve efficiency: fewer round-trips, fewer missed refs, safer renames, and one-shot symbol context. Query is optional; detect_changes and cypher are later.

---

## 1. Goals

- **R1.0** Support **project-scoped** SysML v2 models: load all model files for a project in one go (from a config), so agents and tools can run impact/rename/context across the whole project.
- **R1.1** Provide **impact analysis** before editing: given a symbol name, report all references, affected URIs, optional direction (upstream/downstream), and a simple risk indication.
- **R1.2** Provide **safe rename**: given a symbol name and new name, return (or apply) text edits across all loaded documents, with dry-run.
- **R1.3** Provide **context** for one symbol: definition, all references (in), symbols it references (out), and parent/children hierarchy in a single response.
- **R1.4** (Optional) Provide **query**: find symbols by name substring or kind across the loaded project.

---

## 2. Functional requirements

### 2.1 Load project

- **R2.1.1** The MCP SHALL provide a tool **loadProject** that loads multiple SysML documents into the current MCP session’s symbol table.
- **R2.1.2** loadProject SHALL accept either:
  - **(A1)** `projectRoot`: string path; server reads `config.yaml` and model files from disk, or
  - **(A2)** `projectRoot` + `files`: array of `{ uri, code }`; client supplies file contents.
- **R2.1.3** When using A1, the server SHALL resolve paths relative to `projectRoot` and SHALL support the config schema: `model_dir` (optional), `model_files` (list of paths).
- **R2.1.4** loadProject SHALL call the existing parser/symbol builder for each file in the order given by `model_files` and SHALL retain all symbols in the session’s single SymbolTable.
- **R2.1.5** loadProject SHALL return a summary: number of files loaded, total symbol count, and parse errors per file (if any).

### 2.2 Impact

- **R2.2.1** The MCP SHALL provide a tool **impact** that, given a symbol name, returns all references to that symbol across loaded documents.
- **R2.2.2** impact SHALL accept `symbolName`: string; optional `uri` to restrict to one document; optional `direction`: `"upstream"` | `"downstream"` | `"both"` (default `"both"`).
- **R2.2.3** impact SHALL use the existing SymbolTable `findReferences(name)` and SHALL return: `symbolName`, `referenceCount`, `references` (list of symbol + uri + range + kind), and `affectedUris` (distinct list). When direction is upstream: only references to this symbol (usages, type refs). When downstream: only symbols that this definition references (e.g. subtypes if the symbol is a def). When both: union (default).
- **R2.2.4** impact SHALL include subtypes when direction is downstream or both: symbols whose `typeNames` include the definition’s qualified name (for definition symbols).
- **R2.2.5** impact MAY return a simple **risk** hint (e.g. `"low"` | `"medium"` | `"high"`) based on referenceCount and number of affected URIs (e.g. high when referenceCount > 10 or affectedUris.length > 5) to help the agent or user decide whether to proceed with care.

### 2.3 Rename

- **R2.3.1** The MCP SHALL provide a tool **rename** that, given a symbol name and a new name, returns or applies text edits across all loaded documents.
- **R2.3.2** rename SHALL accept `symbolName`, `newName`, and optional `dryRun` (default true). Optional `uri` to limit scope.
- **R2.3.3** When `dryRun` is true, rename SHALL return `edits`: array of `{ uri, range, newText }` and SHALL NOT modify any document.
- **R2.3.4** Edits SHALL target the identifier(s) that denote the symbol (definition name, usage names, type references) so that a client can apply them via workspace edits.
- **R2.3.5** (Optional) When `dryRun` is false, the server MAY apply edits to in-memory `loadedDocuments` and return the same edit list; applying to disk is out of scope (client responsibility).

### 2.4 Query (optional)

- **R2.4.1** The MCP MAY provide a tool **query** that finds symbols by name substring or kind across all loaded documents.
- **R2.4.2** query SHALL accept a string (and optionally filters) and SHALL return a list of symbols in the same shape as getSymbols.

### 2.5 Context

- **R2.5.1** The MCP SHALL provide a tool **context** that, given a symbol name (or qualified name), returns a single combined view: the definition (if any), all references to this symbol (incoming), symbols this symbol references (outgoing, e.g. typeNames), and parent/children hierarchy.
- **R2.5.2** context SHALL accept `symbolName`: string (or qualified name) and optional `uri` to disambiguate when multiple symbols share the same name.
- **R2.5.3** context SHALL return: `definition` (getDefinition result or null), `references` (findReferences result), `referencesOut` (symbols referenced by this one: for usages, their typeNames resolved to symbol entries; for defs, subtypes or empty), `hierarchy` (parent qualifiedName, children qualifiedNames — same shape as getHierarchy). All lists SHALL use the same symbol format (name, kind, qualifiedName, uri, range) for consistency.
- **R2.5.4** When the symbol is not found, context SHALL return a clear `found: false` and MAY suggest near matches (e.g. findByName substring).

---

## 3. Constraints and non-functional requirements

- **R3.1** Extension SHALL be **MCP-only** in the first phase: no changes to LSP server.ts or DocumentManager; only mcpCore.ts and mcpServer.ts (and helpers).
- **R3.2** Existing MCP tools (parse, validate, getSymbols, getDefinition, getReferences, getHierarchy, preview, getDiagnostics, getComplexity) SHALL remain unchanged and SHALL continue to work for single-document and multi-document (post loadProject) usage.
- **R3.3** The implementation SHALL reuse the existing parser (parseDocument), SymbolTable (build, findReferences, findByName, getSymbolsForUri, getAllSymbols), and McpContext; no new parser or symbol implementation.
- **R3.4** For A1 (loadProject from disk): the server SHALL assume it has read access to the workspace (e.g. Cursor MCP cwd = repo root). For sandboxed environments, A2 (client-supplied files) SHALL be supported.
- **R3.5** Config schema SHALL be compatible with the SystemDesign project layout: `config.yaml` with `model_dir` and `model_files` (paths relative to project directory).

---

## 4. Implementation priority (phases)

| Phase | Scope | Rationale |
|-------|--------|-----------|
| **Phase 1** | loadProject (R2.1), impact (R2.2), rename (R2.3) | Core refactor loop: load → assess impact → rename with dry_run. Unblocks real use. |
| **Phase 2** | context (R2.5) | One-shot symbol view; aligns with GitNexus workflow and reduces round-trips before editing. |
| **Phase 3** (optional) | query (R2.4) | Discovery by name/kind; nice-to-have. |
| **Later** | detect_changes, cypher | If needed; not required for the SysML modeling job in this repo. |

---

## 5. Success criteria (done when)

- An agent (or user) can **loadProject** for a SystemDesign project (e.g. foam-detection) with one MCP call and receive a summary (files loaded, symbol count, any parse errors).
- For any symbol name in the loaded set, the agent can call **impact(symbolName)** and receive references, affectedUris, and optionally direction and risk.
- The agent can call **rename(symbolName, newName, dryRun: true)** and receive a list of edits that, when applied by the client, rename the symbol consistently across all loaded documents.
- The agent can call **context(symbolName)** and receive definition, references (in), referencesOut, and hierarchy in one response.

---

## 6. Out of scope (first phase)

- LSP project awareness (auto-load on workspace open).
- Applying rename edits to disk from the server.
- Full semantic cross-file type resolution (existing single-doc or best-effort multi-doc only).
- New diagram types or preview changes.
- detect_changes (scope of edits vs. baseline).
- cypher (custom graph query language).

---

## 7. Traceability (for SysML)

| Requirement | Satisfied by (model element / implementation) |
|-------------|-----------------------------------------------|
| R1.0, R2.1.x | loadProject tool; McpServer + McpContext |
| R1.1, R2.2.x | impact tool; SymbolTableLayer, McpServer |
| R1.2, R2.3.x | rename tool; McpServer, Providers (rename logic reference) |
| R1.3, R2.5.x | context tool; McpServer (getDefinition + getReferences + getHierarchy + refsOut) |
| R1.4, R2.4.x | query tool (optional); McpServer |
| R3.1–R3.5 | Design constraint on McpServer, mcpCore; no change to LanguageServer, DocumentManager |

These can be formalized as `requirement def` and `satisfy` in the SysML model once the structure is updated.

---

## 8. Comparison with GitNexus

GitNexus provides: **query** (by concept), **context** (360° view of one symbol), **impact** (blast radius, direction, risk), **detect_changes** (pre-commit scope), **rename** (safe multi-file, dry_run), **cypher** (custom graph).

| GitNexus tool       | Our extension | Status |
|---------------------|---------------|-----|
| **query**           | query (R2.4)  | Ours is by name/kind only; GitNexus is by *concept* (semantic over execution flows). We have no execution flows — only symbol refs. |
| **context**         | context (R2.5) | **Covered.** Definition + refs (in) + refsOut + hierarchy in one response. |
| **impact**          | impact (R2.2) | **Covered.** Refs + affectedUris + direction + optional risk hint. |
| **detect_changes**  | —             | Out of scope for first phase. “what changed in the project” or “which symbols are affected by current edits”. Would need diff vs. last loaded state or baseline. |
| **rename**          | rename (R2.3) | Covered: dry_run, edits across docs. |
| **cypher**          | —             | Out of scope for first phase. “all part defs that reference port X”). Would require exposing the symbol graph (nodes/edges) to a query language. |
| *(index/load)*      | loadProject   | GitNexus indexes repo once (CLI); we load project on demand via MCP. |

**Summary:** We cover **loadProject**, **impact** (with direction and risk), **rename**, and **context**. That aligns the extension with the GitNexus-style workflow for the SysML modeling job. Query is optional; detect_changes and cypher are later.
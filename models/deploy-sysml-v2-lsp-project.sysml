/*
  SysML v2 model of the sysml-v2-lsp-project architecture: Language Server, MCP server, parser, symbols, providers, clients.
  Primary use: Cursor (LSP for .sysml editing + MCP for loadProject, impact, rename, context). See fork https://github.com/chouswei/sysml-v2-lsp.
  Traceability (model ↔ implementation): PLAN §10. Memory: single project in session; parse tree not retained; PLAN §11.
  Structure: MCP tool actions → workflow/state → part defs (layers, server, clients) → McpExtensionCore → SysMLv2LspProjectDeployment.
*/
package SysMLv2LspProject {
  private import ScalarValues::*;
  private import ISQ::*;
  private import SI::*;
  private import SysMLv2LspProjectRequirements::*;

  // ─── MCP tool actions (Phase 1–3, PLAN §4–5) ─────────────────────────────────
  action def LoadProject {
    doc /*
      MCP tool (Phase 1). Load multiple SysML documents into the current session symbol table. Contract (PLAN §4.1): In — projectRoot (string), files (optional array of { uri, code }). Out — filesLoaded, symbolCount, parseErrorsByUri, errors[]. A1: server reads config.yaml and files from disk; A2: client supplies files. Session is replaced (clear then load), not merged. Uses parser and symbolTable.build(uri, result) per file; clearAll() before load. On success, project graph index is updated (buildFromSymbolTable). Implementation order: clearAll then loadProject (A2 then A1). PLAN §13: index = graph DB; loadProject on success updates graph.
    */
  }

  action def Impact {
    doc /*
      MCP tool (Phase 1). Return all references to a symbol across loaded documents. Contract (PLAN §4.2): In — symbolName, uri (optional), direction (optional upstream|downstream|both). Out — symbolName, referenceCount, references[], affectedUris[], risk (optional low|medium|high). When nothing loaded: message "No project loaded; call loadProject first." Uses symbolTable.findReferences(name); downstream includes subtypes (typeNames includes target.qualifiedName). May use projectGraphIndex for assist (graph traversal for downstream/risk). PLAN §13.
    */
  }

  action def Rename {
    doc /*
      MCP tool (Phase 1). Return or apply text edits for a symbol rename across all loaded documents. Contract (PLAN §4.3): In — symbolName, newName, dryRun (optional, default true), uri (optional). Out — found, edits[{ uri, range, newText }], message. When dryRun true: no state change. When dryRun false: apply to loadedDocuments and re-parse per URI. Multiple symbols same name without uri: error "provide uri to disambiguate". Uses findReferences then selectionRange per symbol; may use projectGraphIndex for assist. Reuse: LSP renameProvider.ts (findWordOccurrences, identUtils.isIdentPart) for identifier ranges.
    */
  }

  action def Context {
    doc /*
      MCP tool (Phase 2). Single combined view for one symbol. Contract (PLAN §4.5): In — symbolName (or qualified name), uri (optional). Out — found, definition, references (in), referencesOut (typeNames resolved; subtypes for defs), hierarchy. When not found: found false, optional nearMatches. Multiple same name without uri: first match only. Uses getDefinition, findReferences, getHierarchy, typeNames resolution; may use projectGraphIndex for hierarchy/out-edges. PLAN §13.
    */
  }

  action def Query {
    doc /*
      MCP tool (Phase 3, optional). Find symbols by name substring or kind across loaded documents. In — query (string), filters (optional, e.g. kind). Out — count, symbols[] (same shape as getSymbols). Filter getAllSymbols() by name/qualifiedName contains query and optional kind. PLAN §4 Phase 3.
    */
  }

  action def RenewIndex {
    doc /*
      MCP tool (PLAN §13). Rebuild the project graph index from the current session symbol table without re-parsing. In — none. Out — nodeCount, edgeCount, message. Use when symbol table is already loaded; graph is cleared then built from symbolTable (DEFINES, REFERENCES, SUBTYPE edges). Optional; loadProject on success already updates the graph.
    */
  }

  part def ProjectGraphIndex {
    doc /*
      Graph index (PLAN §13): symbol and reference graph for the loaded project. Nodes = symbols (qualifiedName, uri, kind, name); edges = REFERENCES (usage→def), SUBTYPE (typeNames), DEFINES (scope). buildFromSymbolTable(symbolTable) populates from current symbol table; clear() on session clear. loadProject on success calls buildFromSymbolTable; impact/rename/context may query the graph for assist (downstream traversal, risk, hierarchy). renewIndex MCP tool rebuilds from symbol table without re-load. Implementation: in-memory graph or embedded DB (e.g. Kuzu). Files: projectGraphIndex.ts (or graph/).
    */
  }

  // ─── Workflow actions and session state ─────────────────────────────────────
  action def RefactorLoop {
    doc /*
      User/agent workflow (orchestrated by client, e.g. Cursor): (1) loadProject (A1 from disk or A2 with files) so session is loaded; (2) impact(symbolName) to see refs and risk; (3) rename(symbolName, newName, dryRun: true) to get edits; (4) client applies edits to workspace. Success criteria: PLAN §6. No state change until client applies; dryRun is default. Performed by deployment (extensionCore.mcpServer provides tools; cursorClient drives the loop).
    */
  }

  action def SymbolContextLookup {
    doc /*
      One-shot symbol view: context(symbolName, uri?) returns definition, references in/out, hierarchy. Used before editing or impact. Performed by deployment via extensionCore.mcpServer (Context tool).
    */
  }

  attribute def LoadProjectRequest {
    doc /* Event: loadProject (A1 or A2) completed; session now loaded. */
  }
  attribute def ClearSessionRequest {
    doc /* Event: session cleared (clearAll or replace); session empty. */
  }

  state def SessionStates {
    doc /*
      MCP session lifecycle. empty: no project loaded; impact/rename/context return "No project loaded". loaded: after loadProject; symbolTable and loadedDocuments populated; tools available. Transitions: LoadProjectRequest → loaded; ClearSessionRequest → empty.
    */
    entry;
    then empty;

    state empty {
      doc /* No project in session; loadProject required before impact/rename/context. */
    }
    state loaded {
      doc /* Project loaded; impact, rename, context, query available. */
    }
    transition t_load
      first empty
      accept LoadProjectRequest
      then loaded;
    transition t_clear
      first loaded
      accept ClearSessionRequest
      then empty;
  }

  // ─── Part defs: core layers (parser, symbols, documents, MCP context, graph) ─
  part def ParserLayer {
    doc /*
      ANTLR4 lexer and parser. Key: parseDocument(text) → ParseResult (tree, errors, timing). ParseResult is used only inside parseAndBuild; tree and token stream are not retained (PLAN §11). Produces parse tree (AST) and syntax errors. Files: server/src/parser/.
    */
  }

  part def SymbolTableLayer {
    doc /*
      Symbol table and scope tree from parse tree. Key: build(uri, parseResult), clearAll() (session reset for loadProject — iterates Array.from(symbolsByUri.keys()) then removeUri; PLAN §4.1), findReferences(name) [may be extended for qualified name for cross-package accuracy], findByName(name), getSymbol(qualifiedName), getSymbolsForUri(uri), getAllSymbols(), removeUri(uri). Index by qualified name and URI. Files: symbolTable.ts, scope.ts, sysmlElements.ts. PLAN §3.2, §5.
    */
  }

  part def DocumentManager {
    doc /*
      LSP document cache only: caches parse results by document URI/version; workspace-wide symbol table for LSP. Re-parses only on content change. getWorkspaceSymbolTable() merges all cached docs. No project/config concept in LSP path. MCP path does NOT use DocumentManager — loadProject/impact/rename/context use McpContext + SymbolTable only (R3.1). Unchanged in Phase 1.
    */
  }

  part def McpContext {
    doc /*
      MCP session state: one SymbolTable instance, loadedDocuments (uri→text), loadedDocumentHashes, lastParseErrors, lastParseTiming. Files: mcpCore.ts. parseAndBuild(ctx, code, uri) updates ctx.symbolTable and ctx.loadedDocuments. Session is replaced (not merged) on each loadProject: clear then load; session clear also clears extensionCore.projectGraphIndex. Parse tree and token stream are not retained (PLAN §11). Invariant: every URI in symbolTable.symbolsByUri is in loadedDocuments with the text last parsed.
    */
  }

  // ─── Part defs: server and feature components ───────────────────────────────
  part def LanguageServer {
    doc /*
      LSP server: connection, capability registration, document lifecycle. Communicates with Cursor, VS Code, or other LSP client via JSON-RPC.
    */
  }

  part def McpServer {
    doc /*
      MCP server: tool registration — existing (parse, validate, getSymbols, getDefinition, getReferences, getHierarchy, preview, getDiagnostics, getComplexity) plus loadProject, impact, rename, context, query (optional), renewIndex (optional, PLAN §13). Stdio transport; Cursor runs with cwd = workspace root. Files: mcpServer.ts (register tools), mcpCore.ts (handlers). PLAN §5.
    */
    perform loadProject : LoadProject;
    perform impact : Impact;
    perform rename : Rename;
    perform context : Context;
    perform query : Query;
    perform renewIndex : RenewIndex;
  }

  part def Providers {
    doc /*
      LSP feature providers: diagnostics, completion, hover, definition, references, documentSymbol, semanticTokens, folding, rename (single-doc; renameProvider.ts), codeAction. Use workspace symbol table for cross-doc go-to-def and find-refs within IDE. MCP rename can reuse renameProvider logic (findWordOccurrences, identUtils.isIdentPart) for identifier boundaries. Unchanged per R3.1.
    */
  }

  part def Analysis {
    doc /*
      Complexity analyzer: structural metrics, composite index, hotspot detection. MCP getComplexity tool.
    */
  }

  part def MermaidGenerator {
    doc /*
      MCP: diagram generation (activity, state, sequence, use case, interconnection, general). Preview tool returns Mermaid markup.
    */
  }

  // ─── Part defs: clients ─────────────────────────────────────────────────────
  part def CursorClient {
    doc /*
      Cursor IDE: VS Code-based; runs SysML v2 LSP (for .sysml editing) and MCP client (for loadProject, impact, rename, context). Primary client for this repo; MCP cwd = workspace root.
    */
  }

  part def VsCodeClient {
    doc /*
      VS Code (without Cursor): extension language client to LSP; diagnostics, completions, hover, go-to-def, find refs, semantic tokens, rename. MCP can be configured separately.
    */
  }

  part def WebClient {
    doc /*
      Browser SPA + Node HTTP bridge. Live editor, diagnostics, symbol outline, Mermaid diagrams.
    */
  }

  part def PythonClient {
    doc /*
      Zero-dependency Python script and Jupyter notebook; drives LSP over stdio.
    */
  }

  // ─── Composite: MCP extension core ──────────────────────────────────────────
  part def McpExtensionCore {
    doc /*
      MCP-only extension boundary (R3.1): parser, symbol table, document manager (LSP cache; not used in MCP call path), MCP session context, MCP server, and project graph index (PLAN §13). mcpServer performs LoadProject, Impact, Rename, Context, Query (optional), RenewIndex (optional). Reuses parser (parseDocument), SymbolTable (build, clearAll, findReferences), McpContext, ProjectGraphIndex (buildFromSymbolTable on load success; clear on session clear). Session state: sessionState (empty | loaded). PLAN §2, §5.
    */
    part parser : ParserLayer;
    part symbolTable : SymbolTableLayer;
    part documentManager : DocumentManager;
    part mcpContext : McpContext;
    part projectGraphIndex : ProjectGraphIndex;
    part mcpServer : McpServer;
    state sessionState : SessionStates;
  }

  // ─── Top-level deployment ───────────────────────────────────────────────────
  part def SysMLv2LspProjectDeployment {
    doc /*
      Top-level deployment: MCP extension core (load/impact/rename/context), language server,
      providers, analysis, Mermaid generator. Primary client: Cursor (LSP + MCP); also VS Code, web, Python.
      Refactor loop (Phase 1): loadProject (A1 or A2) → impact(symbol) → rename(symbol, newName, dryRun: true) → client applies edits. Success when: one loadProject call loads project; impact returns refs/affectedUris/risk; rename dryRun returns edits; context returns definition+refs+hierarchy (PLAN §6). Out of scope: LSP project awareness, rename to disk, detect_changes, cypher (PLAN §9).

      Data flow: LSP path — client ↔ languageServer (JSON-RPC) ↔ providers, documentManager (workspace symbol table). MCP path — client ↔ mcpServer (stdio) ↔ extensionCore (symbolTable, projectGraphIndex, mcpContext).

      Parts (roles and behaviour):
      — extensionCore: MCP path; holds parser, symbolTable, documentManager, mcpContext, projectGraphIndex, mcpServer; session state (empty|loaded). Performs LoadProject, Impact, Rename, Context, Query, RenewIndex (optional). loadProject on success updates projectGraphIndex. impact/rename/context may query graph for assist. Used by refactorLoop and symbolContextLookup.
      — languageServer: LSP path; JSON-RPC connection, document open/change/close; does not use project/config; satisfies reqExistingToolsUnchanged.
      — providers: LSP features (diagnostics, completion, hover, definition, references, documentSymbol, semanticTokens, folding, rename, codeAction); use workspace symbol table from documentManager.
      — analysis: complexity metrics, composite index, hotspot; MCP getComplexity tool.
      — mermaidGenerator: diagram generation (activity, state, sequence, use case, interconnection); MCP preview tool.
      — cursorClient: primary client; drives LSP (editing) and MCP (loadProject, impact, rename, context); orchestrates refactorLoop; cwd = workspace root.
      — vsCodeClient: VS Code LSP client; MCP configurable separately.
      — webClient: browser SPA + Node bridge; live editor, diagnostics, outline, Mermaid.
      — pythonClient: Python/Jupyter; LSP over stdio.

      Graph index (PLAN §13): extensionCore.projectGraphIndex. Symbol/reference graph built from symbol table; updated on loadProject success; clear on session clear. renewIndex rebuilds from current symbol table. impact/rename/context may query graph for assist. Satisfies ReqIndexAssistFuture.
    */
    part extensionCore : McpExtensionCore;
    part languageServer : LanguageServer;
    part providers : Providers;
    part analysis : Analysis;
    part mermaidGenerator : MermaidGenerator;
    part cursorClient : CursorClient;
    part vsCodeClient : VsCodeClient;
    part webClient : WebClient;
    part pythonClient : PythonClient;

    perform refactorLoop : RefactorLoop;
    perform symbolContextLookup : SymbolContextLookup;

    requirement reqProjectScoped : ReqProjectScoped;
    requirement reqImpactAnalysis : ReqImpactAnalysis;
    requirement reqSafeRename : ReqSafeRename;
    requirement reqContext : ReqContext;
    requirement reqQuery : ReqQuery;
    requirement reqLoadProjectTool : ReqLoadProjectTool;
    requirement reqLoadProjectInputs : ReqLoadProjectInputs;
    requirement reqLoadProjectSummary : ReqLoadProjectSummary;
    requirement reqPathSecurity : ReqPathSecurity;
    requirement reqSessionReplace : ReqSessionReplace;
    requirement reqImpactTool : ReqImpactTool;
    requirement reqImpactDirection : ReqImpactDirection;
    requirement reqImpactRisk : ReqImpactRisk;
    requirement reqRenameTool : ReqRenameTool;
    requirement reqRenameDryRun : ReqRenameDryRun;
    requirement reqContextTool : ReqContextTool;
    requirement reqContextOutputShape : ReqContextOutputShape;
    requirement reqMcpOnly : ReqMcpOnly;
    requirement reqWorkspaceOrClientFiles : ReqWorkspaceOrClientFiles;
    requirement reqConfigSchema : ReqConfigSchema;
    requirement reqExistingToolsUnchanged : ReqExistingToolsUnchanged;
    requirement reqReuseParserAndSymbols : ReqReuseParserAndSymbols;
    requirement reqCursorSupport : ReqCursorSupport;
    requirement reqIndexAssistFuture : ReqIndexAssistFuture;

    satisfy reqProjectScoped by extensionCore;
    satisfy reqImpactAnalysis by extensionCore;
    satisfy reqSafeRename by extensionCore;
    satisfy reqContext by extensionCore;
    satisfy reqQuery by extensionCore.mcpServer;
    satisfy reqLoadProjectTool by extensionCore.mcpServer;
    satisfy reqLoadProjectInputs by extensionCore;
    satisfy reqLoadProjectSummary by extensionCore;
    satisfy reqPathSecurity by extensionCore;
    satisfy reqSessionReplace by extensionCore;
    satisfy reqImpactTool by extensionCore.mcpServer;
    satisfy reqImpactDirection by extensionCore.mcpServer;
    satisfy reqImpactRisk by extensionCore.mcpServer;
    satisfy reqRenameTool by extensionCore.mcpServer;
    satisfy reqRenameDryRun by extensionCore;
    satisfy reqContextTool by extensionCore.mcpServer;
    satisfy reqContextOutputShape by extensionCore;
    satisfy reqWorkspaceOrClientFiles by extensionCore;
    satisfy reqConfigSchema by extensionCore;
    satisfy reqMcpOnly by extensionCore;
    satisfy reqReuseParserAndSymbols by extensionCore;
    satisfy reqExistingToolsUnchanged by languageServer;
    satisfy reqExistingToolsUnchanged by providers;
    satisfy reqExistingToolsUnchanged by extensionCore.documentManager;
    satisfy reqCursorSupport by extensionCore;
    satisfy reqCursorSupport by cursorClient;
    satisfy reqIndexAssistFuture by extensionCore.projectGraphIndex;
  }
}

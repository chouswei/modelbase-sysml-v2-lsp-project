/*
  SysML v2 model of the sysml-v2-lsp-project architecture: Language Server, MCP server, parser, symbols, providers, clients.
  Primary use: Cursor (LSP for .sysml editing + MCP for loadProject, impact, rename, context). See fork https://github.com/chouswei/sysml-v2-lsp.
  Traceability (model ↔ implementation): PLAN §10. Memory: single project in session; parse tree not retained; PLAN §11.
*/
package SysMLv2LspProject {
  private import ScalarValues::*;
  private import ISQ::*;
  private import SI::*;
  private import SysMLv2LspProjectRequirements::*;

  action def LoadProject {
    doc /*
      MCP tool (Phase 1). Load multiple SysML documents into the current session symbol table. Contract (PLAN §4.1): In — projectRoot (string), files (optional array of { uri, code }). Out — filesLoaded, symbolCount, parseErrorsByUri, errors[]. A1: server reads config.yaml and files from disk; A2: client supplies files. Session is replaced (clear then load), not merged. Uses parser and symbolTable.build(uri, result) per file; clearAll() before load. Implementation order: clearAll then loadProject (A2 then A1).
    */
  }

  action def Impact {
    doc /*
      MCP tool (Phase 1). Return all references to a symbol across loaded documents. Contract (PLAN §4.2): In — symbolName, uri (optional), direction (optional upstream|downstream|both). Out — symbolName, referenceCount, references[], affectedUris[], risk (optional low|medium|high). When nothing loaded: message "No project loaded; call loadProject first." Uses symbolTable.findReferences(name); downstream includes subtypes (typeNames includes target.qualifiedName).
    */
  }

  action def Rename {
    doc /*
      MCP tool (Phase 1). Return or apply text edits for a symbol rename across all loaded documents. Contract (PLAN §4.3): In — symbolName, newName, dryRun (optional, default true), uri (optional). Out — found, edits[{ uri, range, newText }], message. When dryRun true: no state change. When dryRun false: apply to loadedDocuments and re-parse per URI. Multiple symbols same name without uri: error "provide uri to disambiguate". Uses findReferences then selectionRange per symbol. Reuse: LSP renameProvider.ts (findWordOccurrences, identUtils.isIdentPart) for identifier ranges.
    */
  }

  action def Context {
    doc /*
      MCP tool (Phase 2). Single combined view for one symbol. Contract (PLAN §4.5): In — symbolName (or qualified name), uri (optional). Out — found, definition, references (in), referencesOut (typeNames resolved; subtypes for defs), hierarchy. When not found: found false, optional nearMatches. Multiple same name without uri: first match only. Uses getDefinition, findReferences, getHierarchy, typeNames resolution.
    */
  }

  action def Query {
    doc /*
      MCP tool (Phase 3, optional). Find symbols by name substring or kind across loaded documents. In — query (string), filters (optional, e.g. kind). Out — count, symbols[] (same shape as getSymbols). Filter getAllSymbols() by name/qualifiedName contains query and optional kind. PLAN §4 Phase 3.
    */
  }

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
      MCP session state: one SymbolTable instance, loadedDocuments (uri→text), loadedDocumentHashes, lastParseErrors, lastParseTiming. Files: mcpCore.ts. parseAndBuild(ctx, code, uri) updates ctx.symbolTable and ctx.loadedDocuments. Session is replaced (not merged) on each loadProject: clear then load. Parse tree and token stream are not retained (PLAN §11). Invariant: every URI in symbolTable.symbolsByUri is in loadedDocuments with the text last parsed.
    */
  }

  part def LanguageServer {
    doc /*
      LSP server: connection, capability registration, document lifecycle. Communicates with Cursor, VS Code, or other LSP client via JSON-RPC.
    */
  }

  part def McpServer {
    doc /*
      MCP server: tool registration — existing (parse, validate, getSymbols, getDefinition, getReferences, getHierarchy, preview, getDiagnostics, getComplexity) plus loadProject, impact, rename, context, query (optional). Stdio transport; Cursor runs with cwd = workspace root. Files: mcpServer.ts (register tools), mcpCore.ts (handlers). PLAN §5.
    */
    perform loadProject : LoadProject;
    perform impact : Impact;
    perform rename : Rename;
    perform context : Context;
    perform query : Query;
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

  part def McpExtensionCore {
    doc /*
      MCP-only extension boundary (R3.1): parser, symbol table, document manager (LSP cache; not used in MCP call path), MCP session context, and MCP server. mcpServer performs LoadProject, Impact, Rename, Context, Query (optional). Reuses parser (parseDocument), SymbolTable (build, clearAll, findReferences), McpContext; no changes to LSP server or DocumentManager interface. PLAN §2, §5.
    */
    part parser : ParserLayer;
    part symbolTable : SymbolTableLayer;
    part documentManager : DocumentManager;
    part mcpContext : McpContext;
    part mcpServer : McpServer;
  }

  part def SysMLv2LspProjectDeployment {
    doc /*
      Top-level deployment: MCP extension core (load/impact/rename/context), language server,
      providers, analysis, Mermaid generator. Primary client: Cursor (LSP + MCP); also VS Code, web, Python.
      Refactor loop (Phase 1): loadProject (A1 or A2) → impact(symbol) → rename(symbol, newName, dryRun: true) → client applies edits. Success when: one loadProject call loads project; impact returns refs/affectedUris/risk; rename dryRun returns edits; context returns definition+refs+hierarchy (PLAN §6). Out of scope: LSP project awareness, rename to disk, detect_changes, cypher (PLAN §9).
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
  }
}

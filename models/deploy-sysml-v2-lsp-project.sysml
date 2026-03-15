/*
  SysML v2 model of the sysml-v2-lsp-project architecture: Language Server, MCP server, parser, symbols, providers, clients.
  Primary use: Cursor (LSP for .sysml editing + MCP for loadProject, impact, rename, context). See fork https://github.com/chouswei/sysml-v2-lsp.
*/
package SysMLv2LspProject {
  private import ScalarValues::*;
  private import ISQ::*;
  private import SI::*;
  private import SysMLv2LspProjectRequirements::*;

  action def LoadProject {
    doc /*
      MCP tool: load multiple SysML documents into the current session symbol table. Input: projectRoot (A1) or projectRoot + files[] (A2). Output: summary (filesLoaded, symbolCount, parseErrors). Uses parser and symbolTable.build(uri, result) per file.
    */
  }

  action def Impact {
    doc /*
      MCP tool: return all references to a symbol across loaded documents. Input: symbolName; optional uri, direction (upstream|downstream|both). Output: referenceCount, references[], affectedUris[], optional risk. Uses symbolTable.findReferences(name).
    */
  }

  action def Rename {
    doc /*
      MCP tool: return or apply text edits for a symbol rename across all loaded documents. Input: symbolName, newName; optional dryRun (default true), uri. Output: edits[{ uri, range, newText }]. Uses findReferences then identifier ranges per symbol.
    */
  }

  action def Context {
    doc /*
      MCP tool: single combined view for one symbol. Input: symbolName (or qualified name); optional uri. Output: definition, references (in), referencesOut, hierarchy. Uses getDefinition, findReferences, getHierarchy, typeNames resolution.
    */
  }

  part def ParserLayer {
    doc /*
      ANTLR4 lexer and parser. Key: parseDocument(code, uri), errorListener, positionUtils. Produces parse tree (AST) and syntax errors. Files: server/src/parser/ (or equivalent).
    */
  }

  part def SymbolTableLayer {
    doc /*
      Symbol table and scope tree from parse tree. Key: build(uri, parseResult), findReferences(name), findByName(name), getSymbolsForUri(uri), getAllSymbols(), removeUri(uri). Index by qualified name and URI. Files: symbolTable.ts, scope.ts, sysmlElements.ts.
    */
  }

  part def DocumentManager {
    doc /*
      Caches parse results by document URI/version; workspace-wide symbol table for LSP. Re-parses only on content change. getWorkspaceSymbolTable() merges all cached docs. No project/config concept in LSP path.
    */
  }

  part def McpContext {
    doc /*
      MCP session state: one SymbolTable instance, loadedDocuments (uri→text), loadedDocumentHashes, lastParseErrors, lastParseTiming. Files: mcpCore.ts. parseAndBuild(ctx, code, uri) updates ctx.symbolTable and ctx.loadedDocuments.
    */
  }

  part def LanguageServer {
    doc /*
      LSP server: connection, capability registration, document lifecycle. Communicates with Cursor, VS Code, or other LSP client via JSON-RPC.
    */
  }

  part def McpServer {
    doc /*
      MCP server: tool registration — existing (parse, validate, getSymbols, getDefinition, getReferences, getHierarchy, preview, getDiagnostics, getComplexity) plus loadProject, impact, rename, context. Stdio transport; Cursor runs with cwd = workspace root. Files: mcpServer.ts (register tools), mcpCore.ts (handlers).
    */
    perform loadProject : LoadProject;
    perform impact : Impact;
    perform rename : Rename;
    perform context : Context;
  }

  part def Providers {
    doc /*
      LSP feature providers: diagnostics, completion, hover, definition, references, documentSymbol, semanticTokens, folding, rename (single-doc), codeAction. Use workspace symbol table for cross-doc go-to-def and find-refs within IDE.
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
      MCP-only extension boundary (R3.1): parser, symbol table, document manager, MCP session context,
      and MCP server. mcpServer performs LoadProject, Impact, Rename, Context. Reuses parser (parseDocument),
      SymbolTable (build, findReferences), McpContext; no changes to LSP server or DocumentManager interface.
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
    requirement reqImpactTool : ReqImpactTool;
    requirement reqImpactParamsAndRisk : ReqImpactParamsAndRisk;
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

    satisfy reqProjectScoped by extensionCore;
    satisfy reqImpactAnalysis by extensionCore;
    satisfy reqSafeRename by extensionCore;
    satisfy reqContext by extensionCore;
    satisfy reqQuery by extensionCore;
    satisfy reqLoadProjectTool by extensionCore;
    satisfy reqLoadProjectInputs by extensionCore;
    satisfy reqLoadProjectSummary by extensionCore;
    satisfy reqImpactTool by extensionCore;
    satisfy reqImpactParamsAndRisk by extensionCore;
    satisfy reqRenameTool by extensionCore;
    satisfy reqRenameDryRun by extensionCore;
    satisfy reqContextTool by extensionCore;
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

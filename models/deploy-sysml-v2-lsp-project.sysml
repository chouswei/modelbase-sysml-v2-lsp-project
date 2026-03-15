/*
  SysML v2 model of the sysml-v2-lsp-project architecture: Language Server, MCP server, parser, symbols, providers, clients.
  See https://github.com/daltskin/sysml-v2-lsp and fork https://github.com/chouswei/sysml-v2-lsp.
*/
package SysMLv2LspProject {
  private import ScalarValues::*;
  private import ISQ::*;
  private import SI::*;

  part def ParserLayer {
    doc /*
      ANTLR4 lexer and parser; parseDocument, errorListener, positionUtils. Produces parse tree (AST) and syntax errors.
    */
  }

  part def SymbolTableLayer {
    doc /*
      Symbol table and scope tree built from parse tree. symbolTable.ts, scope.ts, sysmlElements.ts. Index by qualified name and URI.
    */
  }

  part def DocumentManager {
    doc /*
      Caches parse results by document URI/version; workspace-wide symbol table for LSP. Re-parses only on content change.
    */
  }

  part def McpContext {
    doc /*
      MCP session state: one SymbolTable, loadedDocuments (uri→text), loadedDocumentHashes, lastParseErrors, lastParseTiming.
    */
  }

  part def LanguageServer {
    doc /*
      LSP server: connection, capability registration, document lifecycle. Communicates with VS Code (or other LSP client) via JSON-RPC.
    */
  }

  part def McpServer {
    doc /*
      MCP server: tool registration (parse, validate, getSymbols, getDefinition, getReferences, getHierarchy, preview, etc.). Stdio transport.
    */
  }

  part def Providers {
    doc /*
      LSP feature providers: diagnostics, completion, hover, definition, references, documentSymbol, semanticTokens, folding, rename, codeAction.
    */
  }

  part def Analysis {
    doc /*
      Complexity analyzer; structural metrics, composite index, hotspot detection.
    */
  }

  part def MermaidGenerator {
    doc /*
      MCP: diagram generation (activity, state, sequence, use case, interconnection, general). Preview tool.
    */
  }

  part def VsCodeClient {
    doc /*
      VS Code extension: language client, IPC to LSP server. Diagnostics, completions, hover, go-to-def, find refs, semantic tokens, rename.
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

  part def SysMLv2LspProjectDeployment {
    doc /*
      Top-level deployment: one language server process, one MCP server (or combined), parser and symbol layers, document manager, providers, and optional clients (VS Code, web, Python).
    */
    part parser : ParserLayer;
    part symbolTable : SymbolTableLayer;
    part documentManager : DocumentManager;
    part mcpContext : McpContext;
    part languageServer : LanguageServer;
    part mcpServer : McpServer;
    part providers : Providers;
    part analysis : Analysis;
    part mermaidGenerator : MermaidGenerator;
    part vsCodeClient : VsCodeClient;
    part webClient : WebClient;
    part pythonClient : PythonClient;
  }
}

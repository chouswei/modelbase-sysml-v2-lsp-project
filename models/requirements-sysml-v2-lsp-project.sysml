/*
  Requirements for the SysML v2 LSP MCP extension: project-scoped load, impact, rename, context.
  Source: requirements.md §1–3; behaviour and traceability: PLAN.md §4–5, §10. Satisfy links in deploy-sysml-v2-lsp-project.sysml.
*/
package SysMLv2LspProjectRequirements {
  private import ScalarValues::String;

  requirement def ReqProjectScoped {
    attribute requirementId : String = "R1.0";
    doc
    /*
      Goal: Support project-scoped SysML v2 models — load all model files for a project in one go (from a config),
      so agents and tools can run impact/rename/context across the whole project. Source: requirements.md §1.
    */
  }

  requirement def ReqImpactAnalysis {
    attribute requirementId : String = "R1.1";
    doc
    /*
      Goal: Provide impact analysis before editing — given a symbol name, report all references, affected URIs,
      optional direction (upstream/downstream), and a simple risk indication. Source: requirements.md §1.
    */
  }

  requirement def ReqSafeRename {
    attribute requirementId : String = "R1.2";
    doc
    /*
      Goal: Provide safe rename — given a symbol name and new name, return (or apply) text edits across all
      loaded documents, with dry-run. Source: requirements.md §1.
    */
  }

  requirement def ReqContext {
    attribute requirementId : String = "R1.3";
    doc
    /*
      Goal: Provide context for one symbol — definition, all references (in), symbols it references (out),
      and parent/children hierarchy in a single response. Source: requirements.md §1.
    */
  }

  requirement def ReqQuery {
    attribute requirementId : String = "R1.4";
    doc
    /*
      Goal (optional): Provide query — find symbols by name substring or kind across the loaded project.
      Source: requirements.md §1, §2.4.
    */
  }

  requirement def ReqLoadProjectTool {
    attribute requirementId : String = "R2.1.1";
    doc
    /*
      The MCP SHALL provide a tool loadProject that loads multiple SysML documents into the current
      MCP session's symbol table. Source: requirements.md §2.1.
    */
  }

  requirement def ReqLoadProjectInputs {
    attribute requirementId : String = "R2.1.2";
    doc
    /*
      loadProject SHALL accept (A1) projectRoot only (server reads config.yaml and files from disk) or
      (A2) projectRoot + files array { uri, code } (client supplies contents). Source: requirements.md §2.1.
    */
  }

  requirement def ReqLoadProjectSummary {
    attribute requirementId : String = "R2.1.5";
    doc
    /*
      loadProject SHALL return a summary: number of files loaded, total symbol count, parse errors per file (if any).
      When model_files is [], session is cleared and filesLoaded is 0. Source: requirements.md §2.1, PLAN §4.1.
    */
  }

  requirement def ReqPathSecurity {
    attribute requirementId : String = "R2.1.path";
    doc
    /*
      Constraint: loadProject A1 SHALL reject paths that resolve outside projectRoot (path traversal).
      Normalize and ensure resolved path is under projectRoot; skip and add to errors otherwise. PLAN §3.2, §7.
    */
  }

  requirement def ReqSessionReplace {
    attribute requirementId : String = "R2.1.session";
    doc
    /*
      Constraint: loadProject SHALL replace the entire session (clear then load); no merge with previous load.
      Second loadProject always replaces all previous URIs and symbols. PLAN §4.1, §4.5.
    */
  }

  requirement def ReqImpactTool {
    attribute requirementId : String = "R2.2.1";
    doc
    /*
      The MCP SHALL provide a tool impact that, given a symbol name, returns all references to that
      symbol across loaded documents. Source: requirements.md §2.2.
    */
  }

  requirement def ReqImpactParamsAndRisk {
    attribute requirementId : String = "R2.2.2/R2.2.5";
    doc
    /*
      impact SHALL accept symbolName; optional uri, direction (upstream|downstream|both). impact MAY return
      a risk hint (low|medium|high) from referenceCount and affectedUris. Source: requirements.md §2.2.
    */
  }

  requirement def ReqRenameTool {
    attribute requirementId : String = "R2.3.1";
    doc
    /*
      The MCP SHALL provide a tool rename that, given a symbol name and a new name, returns or applies
      text edits across all loaded documents. Source: requirements.md §2.3.
    */
  }

  requirement def ReqRenameDryRun {
    attribute requirementId : String = "R2.3.3";
    doc
    /*
      When dryRun is true, rename SHALL return edits array { uri, range, newText } and SHALL NOT modify documents.
      Source: requirements.md §2.3.
    */
  }

  requirement def ReqContextTool {
    attribute requirementId : String = "R2.5.1";
    doc
    /*
      The MCP SHALL provide a tool context that, given a symbol name (or qualified name), returns a
      single combined view: definition, references (in), symbols referenced (out), and hierarchy.
      Source: requirements.md §2.5.
    */
  }

  requirement def ReqContextOutputShape {
    attribute requirementId : String = "R2.5.3";
    doc
    /*
      context SHALL return definition, references, referencesOut, hierarchy; symbol format (name, kind,
      qualifiedName, uri, range) for consistency. When not found: found false, optional near matches.
      Source: requirements.md §2.5.
    */
  }

  requirement def ReqMcpOnly {
    attribute requirementId : String = "R3.1";
    doc
    /*
      Constraint: Extension SHALL be MCP-only in the first phase — no changes to LSP server.ts or DocumentManager;
      only mcpCore.ts and mcpServer.ts (and helpers). Source: requirements.md §3.
    */
  }

  requirement def ReqExistingToolsUnchanged {
    attribute requirementId : String = "R3.2";
    doc
    /*
      Constraint: Existing MCP tools (parse, validate, getSymbols, getDefinition, getReferences, getHierarchy,
      preview, getDiagnostics, getComplexity) SHALL remain unchanged and work for single-document and
      multi-document (post loadProject) usage. Source: requirements.md §3.
    */
  }

  requirement def ReqReuseParserAndSymbols {
    attribute requirementId : String = "R3.3";
    doc
    /*
      Constraint: Implementation SHALL reuse the existing parser (parseDocument), SymbolTable (build,
      findReferences, findByName, getSymbolsForUri, getAllSymbols), and McpContext; no new parser or
      symbol implementation. Source: requirements.md §3.
    */
  }

  requirement def ReqCursorSupport {
    attribute requirementId : String = "R3.Cursor";
    doc
    /*
      Constraint: Extension SHALL support Cursor as MCP client: stdio transport, MCP cwd = workspace root
      for loadProject (A1), and all MCP tools (loadProject, impact, rename, context) available to the agent.
      Primary use case for this repo.
    */
  }

  requirement def ReqWorkspaceOrClientFiles {
    attribute requirementId : String = "R3.4";
    doc
    /*
      Constraint: For loadProject A1 the server SHALL assume read access to workspace (e.g. Cursor MCP cwd = repo root).
      For sandboxed environments, A2 (client-supplied files) SHALL be supported. Source: requirements.md §3.
    */
  }

  requirement def ReqConfigSchema {
    attribute requirementId : String = "R3.5";
    doc
    /*
      Constraint: Config schema SHALL be compatible with SystemDesign: config.yaml with model_dir (optional)
      and model_files (paths relative to project directory). Source: requirements.md §3.
    */
  }
}

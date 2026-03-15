/*
  Root package for SysML v2 model of sysml-v2-lsp-project. Aligned with PLAN §12: requirements (R1–R3, ReqIndexAssistFuture),
  MCP tools Phase 1–3 (loadProject, impact, rename, context, query) and PLAN §13 (renewIndex, index, cypher).
  Part docs: clearAll, MCP vs LSP path, session invariants, ParseResult not retained; satisfy by extensionCore.mcpServer.
  Refactor loop: loadProject → impact → rename(dryRun) → client applies. Success: PLAN §6. Out of scope: PLAN §9.
  Traceability: PLAN §10. Memory: PLAN §11. Graph: projectGraphIndex; loadProject updates it; index builds without load; renewIndex; cypher read-only; impact/rename/context may query for assist.
  Deployment: SysMLv2LspProjectDeployment — extensionCore, languageServer, providers, analysis, mermaidGenerator, clients (primary: Cursor).
*/
package SysMLv2LspProjectRoot {
  private import SysMLv2LspProject::*;
}

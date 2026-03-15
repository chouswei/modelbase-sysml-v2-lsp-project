/*
  Root package for SysML v2 model of sysml-v2-lsp-project. Aligned with PLAN.md §12: requirements (goals, tools, constraints,
  path security, session replace), MCP tool actions (LoadProject, Impact, Rename, Context, Query, RenewIndex) with Phase 1/2/3 and in/out in doc,
  part docs (clearAll, MCP vs LSP path, session invariants, ParseResult not retained), satisfy by extensionCore.mcpServer for tool reqs.
  Refactor loop: loadProject → impact → rename(dryRun) → client applies. Success criteria: PLAN §6. Out of scope: PLAN §9.
  Traceability: PLAN §10. Memory: PLAN §11. Graph index: PLAN §13 — extensionCore.projectGraphIndex; loadProject updates it; renewIndex rebuilds; impact/rename/context may query for assist.
  Deployment: SysMLv2LspProjectDeployment — extension core (parser, symbolTable, projectGraphIndex, mcpContext, mcpServer), LSP, providers, clients (primary: Cursor).
*/
package SysMLv2LspProjectRoot {
  private import SysMLv2LspProject::*;
}

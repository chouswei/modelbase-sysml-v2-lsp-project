/*
  Root package for SysML v2 model of sysml-v2-lsp-project. Aligned with PLAN.md §12: requirements (goals, tools, constraints,
  path security, session replace), MCP tool actions (LoadProject, Impact, Rename, Context, Query) with Phase 1/2/3 and in/out in doc,
  part docs (clearAll, MCP vs LSP path, session invariants, ParseResult not retained), satisfy by extensionCore.mcpServer for tool reqs.
  Refactor loop: loadProject → impact → rename(dryRun) → client applies. Success criteria: PLAN §6. Out of scope: PLAN §9.
  Traceability: PLAN §10. Memory: PLAN §11. Future: PLAN §13 (ReqIndexAssistFuture).
  Deployment: SysMLv2LspProjectDeployment — extension core, LSP, providers, clients (primary: Cursor).
*/
package SysMLv2LspProjectRoot {
  private import SysMLv2LspProject::*;
}

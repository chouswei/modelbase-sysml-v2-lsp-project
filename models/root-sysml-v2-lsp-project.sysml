/*
  Root package for SysML v2 model of sysml-v2-lsp-project. Aligned with PLAN.md §12: requirements (goals, tools, constraints,
  path security, session replace), MCP tool actions (LoadProject, Impact, Rename, Context, Query) with in/out contract in doc,
  part docs (clearAll, MCP vs LSP path, session invariants), satisfy by extensionCore.mcpServer for tool reqs.
  Deployment: SysMLv2LspProjectDeployment — extension core, LSP, providers, clients (primary: Cursor).
*/
package SysMLv2LspProjectRoot {
  private import SysMLv2LspProject::*;
}

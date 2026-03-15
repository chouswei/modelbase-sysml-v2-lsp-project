# SysML v2 model: sysml-v2-lsp-project

SysML v2 model of the **sysml-v2-lsp-project** (LSP/MCP) architecture: parser, symbol table, MCP server, providers, and clients.

## Use in SystemDesign

This repo is included as a **submodule** at `sysml-v2-models/projects/sysml-v2-lsp-project` when used from [SystemDesign](https://github.com/chouswei/SystemDesign). From the SystemDesign repo root, generate diagrams:

```bash
cd sysml-v2-models
python scripts/visualize.py --project sysml-v2-lsp-project --diagram bdd --format png
```

## Standalone

When cloned alone, you need the SysML v2 Kernel and library (e.g. from [Systems-Modeling/SysML-v2-Release](https://github.com/Systems-Modeling/SysML-v2-Release)) at a sibling path or adjust `config.yaml` `model_files` accordingly.

## Layout

- `config.yaml` — project config and model load order
- `models/` — root, deploy (structure), optional behaviour/requirements
- `outputs/` — generated diagrams and docs

# RISU Agent MCP (mcphost-native)

This directory packages a mcphost-native RISU agent that focuses on **single host diagnostics**. It provides two builtin MCP servers that enable LLMs to run RISU diagnostics interactively via `mcphost`.

## Contents
```
roles/ansible-ollama_mcphost/mcp_servers/risu-agent/
├── README.md
├── config.yml             # MCP server configuration
└── system-prompt          # System prompt (auto-discovered by role)
```

## Quick start

1. Deploy the role and enable the RISU agent (selects all servers from this directory):
   ```bash
   ansible-playbook deploy.yml -e "mcp_servers=['risu-agent']"
   ```
   
   This will automatically load all MCP servers defined in `risu-agent/config.yml` (e.g., `risu-agent-filesystem`, `risu-agent-bash`) and use the `system-prompt` file if it exists.

2. Run `mcphost` interactively:
   ```bash
   mcphost
   ```

3. Ask the LLM to run RISU diagnostics:
   ```
   Run RISU diagnostics on this system
   ```

The LLM will use the available MCP tools (`risu-agent-bash` and `risu-agent-filesystem`) to execute RISU commands and analyze the results.

## How it works

1. **Scoped servers** – The config defines two builtin MCP servers:
   - `risu-agent-filesystem`: Read-only access to the RISU installation (via `RISU_AGENT_ROOT`) and `/tmp` for reading RISU JSON output
   - `risu-agent-bash`: Executes RISU commands (`risu -l`, `risu --list-plugins`, etc.) and ansible-playbook for remediation

2. **Interactive use** – When you run `mcphost` interactively, the LLM has access to these tools and can:
   - Run RISU diagnostics via the bash server
   - Read RISU JSON output via the filesystem server
   - Analyze results and suggest remediation steps

## Configuration

### RISU Installation Path

The RISU installation path is determined by:
- `RISU_AGENT_ROOT` environment variable (if set)
- Default: `/usr/share/risu` (standard RISU package location)

To use a custom RISU checkout, set the environment variable:
```bash
export RISU_AGENT_ROOT=/path/to/risu
mcphost
```

### System Prompt

The `system-prompt` file in this directory is automatically discovered and used by the Ansible role when:
- No explicit system prompt is configured via `mcphost_system_prompt` or `mcphost_system_prompt_file`
- The `risu-agent` MCP server is enabled

This provides a RISU-specific system prompt that guides the LLM on how to interact with RISU diagnostics.

## Relationship to other RISU MCP servers

- Use `roles/ansible-ollama_mcphost/mcp_servers/risu-insights` if you need multi-host orchestration via FastMCP/Ansible.
- Use `risu-agent` when a lightweight, local-only workflow is preferred. It has no Python dependencies and rides entirely on mcphost's builtin capabilities.

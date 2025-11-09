# MCP Servers Directory

This directory contains MCP server configurations that can be automatically discovered and deployed by the `ansible-ollama_mcphost` role.

**Note:** This directory already contains ready-to-use examples (`filesystem`, `bash-commands`, `web-fetcher`, RISU agent, etc.). Drop additional MCP servers here (or under `~/mcp_servers`) and rerun the playbook to pick them up.

## Quick Start

### Example: RISU Agent (bundled)

The RISU diagnostics helper (filesystem + constrained bash servers plus helper
scripts) already lives in this directory under `risu-agent/`. To use it, just
run the main playbook:

```bash
ansible-playbook deploy.yml
# or limit the deployment to only the RISU helper servers
ansible-playbook deploy.yml \
  -e "mcp_servers=['risu-agent-filesystem','risu-agent-bash']"
```

Set `RISU_AGENT_ROOT` (or edit the files inside `risu-agent/`) if you want to
point at a different RISU checkout.

> **Heads-up:** Some servers expect supporting assets (playbooks, helper
> scripts, inventories, etc.). Keep those assets alongside the `config.yml`
> file so auto-discovery picks up everything the next time you run the
> playbook.
> The `risu-agent` example already ships with placeholder `inventory/` and
> `docs/` directories so the builtin filesystem server has a valid path—replace
> their contents with the artifacts from your RISU checkout as needed.
> By default the helper points at `/usr/share/risu`. Set `RISU_AGENT_ROOT`
> before launching `mcphost` (or override `risu_agent_root_default` when running
> the Ansible role) if your checkout lives elsewhere.

### Adding Your Own MCP Server

1. **Create or copy your MCP server into this directory:**
   ```bash
   cd roles/ansible-ollama_mcphost/mcp_servers/
   mkdir your-server
   # or: git clone <your-server-repo> your-server
   ```

2. **Create a `config.yml` file:**
   ```yaml
   # mcp_servers/your-server/config.yml
   your-server:
     type: "local"
     command: ["./run-server.sh"]
     cwd: "{{ server_dir }}"
     environment:
       VAR_NAME: "value"
       API_KEY: "${env://MY_API_KEY}"  # Use environment variable substitution
     description: "Your server description"
   ```

3. **Deploy using the role (from the repository root):**
   ```bash
   cd ../../../..
ansible-playbook deploy.yml -e "mcp_servers=['your-server']"
   ```

## Directory Structure

```
roles/ansible-ollama_mcphost/mcp_servers/
├── README.md                    # This file
├── filesystem/                  # Example from package (builtin)
│   └── config.yml
├── bash-commands/               # Example from package (builtin)
│   └── config.yml
├── web-fetcher/                 # Example from package (builtin)
│   └── config.yml
├── filesystem_tmp_rw/           # Example from package (builtin)
│   └── config.yml
├── filesystem_etc_ro/           # Example from package (builtin)
│   └── config.yml
├── risu-agent/                  # RISU diagnostics helper (bundled)
│   ├── config.yml
│   └── scripts/
└── custom-server/               # Your own MCP server
    ├── config.yml
    └── ...
```

## Config File Format

Each MCP server directory must contain a `config.yml` file in **mcphost's native format** - just the `mcpServers` section. The role will automatically merge it into the main config.

**Important:** The `config.yml` file should contain only the server configuration dictionary, not wrapped in `mcpServers:`. The role handles the wrapping automatically.

### Local Server Example

```yaml
# mcp_servers/my-server/config.yml
# This is the actual mcphost config format
# {{ server_dir }} will be replaced with the absolute path to this server directory
my-server:
  type: "local"
  command: ["./run-server.sh"]
  cwd: "{{ server_dir }}"
  environment:
    VAR_NAME: "value"
    ANOTHER_VAR: "{{ server_dir }}/path"
    API_KEY: "${env://MY_API_KEY}"  # Use environment variable substitution
  description: "Server description"
```

**Note:** 
- The server name (key) must match the directory name or be unique
- Use `{{ server_dir }}` for paths relative to the server directory
- Use `${env://VAR_NAME}` for environment variable substitution in environment variables
- The `command` can be a string or a list: `command: "./script.sh"` or `command: ["python3", "server.py"]`

### Builtin Server Example

```yaml
filesystem:
  type: "builtin"
  name: "fs"
  options:
    allowed_directories: ["/tmp"]
  allowedTools:
    - "read_file"
    - "write_file"
```

### Remote Server Example

```yaml
remote-server:
  type: "remote"
  url: "https://api.example.com/mcp"
  description: "Remote MCP server"
```

## Available Variables in config.yml

When using `config.yml`, the following Jinja2 variable is available:

- `{{ server_dir }}` - Absolute path to the MCP server directory (automatically replaced by the role)

**Note:** The config file is in mcphost's native format - just write the server configuration exactly as it would appear under `mcpServers:` in the main mcphost config file.

## Auto-Discovery

**Important:** MCP servers are only auto-discovered when explicitly selected via `mcphost_mcp_servers_filter`. If no filter is specified, no servers are configured.

### Selecting MCP Servers by Directory

When you specify a directory name in `mcphost_mcp_servers_filter`, the role will:

1. Load **all** MCP servers defined in that directory's `config.yml` file
2. Use the `system-prompt` file from that directory (if it exists)

**Example:**
```bash
# Select risu-agent directory - loads ALL servers from risu-agent/config.yml
ansible-playbook deploy.yml -e "mcp_servers=['risu-agent']"
```

This will load:
- All servers from `risu-agent/config.yml` (e.g., `risu-agent-filesystem`, `risu-agent-bash`)
- The `system-prompt` file from `risu-agent/` directory (if it exists)

### Multiple Directories

You can select multiple directories:
```bash
ansible-playbook deploy.yml -e "mcp_servers=['risu-agent','filesystem']"
```

This will:
- Load all servers from `risu-agent/config.yml`
- Load all servers from `filesystem/config.yml`
- Use the first `system-prompt` file found from the selected directories

### System Prompt Discovery

- If a `system-prompt` file exists in a selected MCP server directory, it will be automatically used as the system prompt
- **Scoped discovery**: Only `system-prompt` files from selected directories are considered
- This only applies if no explicit system prompt is configured via `mcphost_system_prompt` or `mcphost_system_prompt_file`
- If multiple selected directories have `system-prompt` files, the first one discovered is used

## Disabling Auto-Discovery

To disable auto-discovery and use manual configuration:

```yaml
mcphost_mcp_servers_auto_discover: false
```

## Multiple Server Locations

You can configure multiple directories to search:

```yaml
mcphost_mcp_servers_dirs:
  - "{{ role_path }}/mcp_servers"
  - "~/mcp_servers"
  - "/opt/mcp_servers"
```

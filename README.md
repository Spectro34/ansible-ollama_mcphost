# Ollama + MCPHost Ansible Role

Reusable Ansible role for setting up local AI with [mcphost](https://github.com/mark3labs/mcphost) and Ollama.

## Features

**Model Selection** - Any Ollama model
**Multiple MCP Servers** - Configure unlimited MCP servers  
**Fully Extensible** - All parameters customizable  
**Cleanup Support** - Complete removal option  
**Tag-Based Execution** - Run specific parts only  

## Quick Start

```bash
# 1. Clone
git clone <repo> && cd ollama-mcphost-setup

# 2. Run example
ansible-playbook example-basic.yml          # Basic: ollama + mcphost only
ansible-playbook example-risu-insights.yml  # With RISU Insights MCP
ansible-playbook example-multiple-mcp.yml   # Multiple MCP servers

# 3. Start using
mcphost
```

## Usage

### Basic Installation

```yaml
- hosts: localhost
  roles:
    - ollama_mcphost
```

### With Custom Model

```yaml
- hosts: localhost
  roles:
    - role: ollama_mcphost
      ollama_model: "llama3.2:3b"  # 2GB, faster
      temperature: 0.4
```

### With MCP Servers

```yaml
- hosts: localhost
  roles:
    - role: ollama_mcphost
      mcp_servers:
        - name: "my-mcp"
          path: "/path/to/mcp_server.py"
          description: "My MCP server"
        
        - name: "another-mcp"
          path: "/path/to/another.py"
          project_root: "/path/to/project"  # For ANSIBLE_LIBRARY etc
          description: "Another server"
          env:  # Optional extra env vars
            CUSTOM_VAR: "value"
```

### Cleanup

```bash
ansible-playbook your-playbook.yml --tags cleanup
```

## Variables

### Model Selection

```yaml
ollama_model: "mistral:7b"  # Default
```

**Available models**:
| Model | Size | RAM | Best For |
|-------|------|-----|----------|
| mistral:7b | 4.1GB | 8GB | General/sysadmin (default) |
| llama3.2:3b | 2GB | 4GB | Fast, efficient |
| codellama:7b | 3.8GB | 8GB | Code/scripts |
| phi3:3.8b | 2.3GB | 4GB | Efficient |

### Generation Parameters

```yaml
temperature: 0.3      # 0.0-1.0 (lower = deterministic)
max_tokens: 2048      # Response length
max_steps: 20         # Agent steps
enable_streaming: true
enable_debug: false
```

### MCP Servers

```yaml
mcp_servers:
  - name: "server-name"           # Required
    path: "/path/to/mcp.py"       # Required
    description: "Description"    # Optional
    project_root: "/path"         # Optional (for ANSIBLE_LIBRARY)
    env:                          # Optional
      VAR_NAME: "value"
```

### Control

```yaml
install_packages: true           # Install ollama/mcphost
packages_to_install: [ollama, mcphost]
cleanup_models: true             # Remove models on cleanup
cleanup_config: true             # Remove config on cleanup
```

## Tags

```bash
--tags install    # Install packages only
--tags model      # Pull model only
--tags config     # Configure only
--tags verify     # Verify only
--tags cleanup    # Remove everything
```

## Examples

### Example 1: RISU Insights

```yaml
- hosts: localhost
  roles:
    - role: ollama_mcphost
      mcp_servers:
        - name: "risu-insights"
          path: "/home/user/risu-insights/risu_insights_mcp.py"
          project_root: "/home/user/risu-insights"
          description: "RISU diagnostics"
```

### Example 2: Multiple MCP Servers

```yaml
- hosts: localhost
  roles:
    - role: ollama_mcphost
      ollama_model: "mistral:7b"
      mcp_servers:
        - name: "risu"
          path: "/home/user/risu-insights/risu_insights_mcp.py"
          project_root: "/home/user/risu-insights"
        
        - name: "custom-tools"
          path: "/home/user/tools/mcp_server.py"
```

### Example 3: Lightweight

```yaml
- hosts: localhost
  roles:
    - role: ollama_mcphost
      ollama_model: "llama3.2:3b"  # Only 2GB
      temperature: 0.4
      max_tokens: 1024
```

## Configuration File

Role creates `~/.mcphost.yml`:

```yaml
model: "ollama:mistral:7b"
provider-url: "http://localhost:11434"
temperature: 0.3
max-tokens: 2048

mcpServers:
  your-mcp-server:
    type: "local"
    command: ["python3", "/path/to/mcp.py"]
```

To add more MCP servers later, either:
1. Run role again with updated `mcp_servers` list
2. Manually edit `~/.mcphost.yml`

## Using mcphost

```bash
# Start interactive
mcphost

# Commands
> /servers    # List MCP servers
> /tools      # Show available tools
> Your query here

# Non-interactive
mcphost -p "Your query" --quiet
```

## Cleanup

```bash
# Remove everything
ansible-playbook your-playbook.yml --tags cleanup

# Keep config
ansible-playbook your-playbook.yml --tags cleanup -e "cleanup_config=false"
```

## Requirements

- Ansible 2.9+
- Linux with package manager (zypper/yum/apt)
- ollama and mcphost packages available
- 8GB+ RAM (for default model)

## Project Structure

```
ollama-mcphost-setup/
├── roles/
│   └── ollama_mcphost/
│       ├── tasks/main.yml           # Role tasks
│       ├── defaults/main.yml        # Default variables
│       ├── templates/
│       │   └── mcphost-config.yml.j2  # Config template
│       ├── meta/main.yml            # Role metadata
│       └── README.md                # Role documentation
├── example-basic.yml                # Example: basic setup
├── example-risu-insights.yml        # Example: RISU Insights MCP
├── example-multiple-mcp.yml         # Example: multiple MCP servers
└── README.md                        # This file
```

## License

MIT

## Author

Harshvardhan Sharma

## References

- [mcphost](https://github.com/mark3labs/mcphost)
- [Ollama](https://ollama.com/)
- [Model Context Protocol](https://modelcontextprotocol.io/)

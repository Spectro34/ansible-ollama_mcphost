# ansible-ollama_mcphost

Composable Ansible role for provisioning [Ollama](https://ollama.com/) and the
[`mcphost`](https://github.com/mark3labs/mcphost) CLI. The role supports both
installation and cleanup flows, optional GPU enablement, and additional MCP
server registrations.

## Quick Start

```bash
git clone git@github.com:Spectro34/ansible-ollama_mcphost.git
cd ansible-ollama_mcphost
ansible-playbook examples/risu-insights.yml
```

Reference configs for other projects live under `examples/`:

- `risu-insights.yml` – wires the RISU Insights MCP server
- `ansible-runner.yml` – GPU-focused setup that registers the Ansible Runner MCP

## Role Parameters

| Variable | Description |
|----------|-------------|
| `ollama_state` | `present` (default) installs Ollama, `absent` removes it |
| `ollama_pull_models` | List of models to pre-pull (`[]` by default) |
| `ollama_gpu_enabled` | Create a systemd drop-in that enables GPU offload |
| `mcphost_state` | Install or remove the mcphost CLI and config |
| `mcphost_local_servers` | Local MCP definitions (`[{name, command, ...}]`) |
| `mcphost_endpoints` | Remote MCP endpoints (`[{name, endpoint}]`) |
| `risu_mcp_configure_endpoint` | Automatically add the RISU Insights MCP endpoint |

All defaults are in `defaults/main.yml`.

## Handlers

- `Reload Ollama daemon` – runs `systemctl daemon-reload` and restarts the
  Ollama service when GPU configuration changes.

## Tags

| Tag | Purpose |
|-----|---------|
| `ollama` | Target Ollama tasks |
| `mcphost` | Target mcphost tasks |
| `install` | Run install/config steps |
| `cleanup` | Remove stack and config |

## Examples

```yaml
# Minimal install
- hosts: target
  roles:
    - role: ansible-ollama_mcphost
      risu_mcp_host: "controller.example.com"
```

```yaml
# GPU + custom model
- hosts: gpu-node
  roles:
    - role: ansible-ollama_mcphost
      ollama_gpu_enabled: true
      ollama_pull_models:
        - "qwen2.5:32b"
```

```yaml
# Register local MCP server
- hosts: localhost
  roles:
    - role: ansible-ollama_mcphost
      mcphost_local_servers:
        - name: "risu-insights"
          command: ["python3", "/opt/risu-insights/server.py"]
          cwd: "/opt/risu-insights"
```

## License

MIT

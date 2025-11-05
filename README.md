# ansible-ollama_mcphost

Composable Ansible role for provisioning [Ollama](https://ollama.com/) and the
[`mcphost`](https://github.com/mark3labs/mcphost) CLI. The role supports both
installation and cleanup flows, optional GPU enablement, and additional MCP
server registrations.

## Quick Start

When used alongside RISU Insights, place this repository next to
`risu-insights/` so Ansible can pick it up via a relative `roles_path`.

```bash
git clone https://github.com/Spectro34/ansible-ollama_mcphost.git
cd ansible-ollama_mcphost
ansible-playbook examples/risu-insights.yml
```

Reference configs for other projects live under `examples/`:

- `risu-insights.yml` – wires the RISU Insights MCP server
- `ansible-runner.yml` – GPU-focused setup that registers the Ansible Runner MCP

## Role Parameters

| Variable | Description |
|----------|-------------|
| `package_auto_refresh` | Auto-refresh package metadata (with key import) on zypper hosts (`true` by default) |
| `package_refresh_command` | Command (list) used when refreshing packages (defaults to `zypper --non-interactive --gpg-auto-import-keys refresh`) |
| `ollama_state` | `present` (default) installs Ollama, `absent` removes it |
| `ollama_package_name` | Package name to install (`ollama` by default) |
| `ollama_model` | Default model tag (`qwen3-coder:30b`) |
| `ollama_pull_models` | Models pulled up-front (defaults to `["qwen3-coder:30b"]`) |
| `ollama_gpu_enabled` | Enable GPU drop-in (`true` by default) |
| `ollama_gpu_runtime` | GPU runtime (`rocm` by default; switch to `cuda` for NVIDIA) |
| `mcphost_state` | Install or remove the mcphost CLI and config |
| `mcphost_package_name` | Package name to install (`mcphost` by default) |
| `mcphost_local_servers` | Local MCP definitions (`[{name, command, ...}]`) |
| `mcphost_endpoints` | Remote MCP endpoints (`[{name, endpoint}]`) |
| `risu_mcp_configure_endpoint` | Automatically add the RISU Insights MCP endpoint |

All defaults are in `defaults/main.yml`.

By default both Ollama and mcphost are pulled from system packages
(`ansible.builtin.package`), so ensure the appropriate repositories are
configured (e.g. add the Ollama RPM repository on openSUSE). The role runs the
refresh command automatically on zypper-based hosts so GPG keys are trusted; set
`package_auto_refresh=false` if you prefer to handle that manually. Override the
package names if your distribution publishes them under different identifiers.

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

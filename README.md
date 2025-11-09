# ansible-ollama_mcphost

![Ansible Lint](https://github.com/Spectro34/ansible-ollama_mcphost/actions/workflows/ansible-lint.yml/badge.svg?branch=main)

Composable Ansible role for provisioning [Ollama](https://ollama.com/) and the [`mcphost`](https://github.com/mark3labs/mcphost) CLI. The role supports both installation and cleanup flows, optional GPU enablement, multiple model providers, and flexible MCP server configurations for *testing*.

## Features

- **Flexible Model Provider Support**: Ollama, OpenAI, Anthropic, Google
- **Multiple MCP Server Types**: Builtin (filesystem, bash, http), local (command-based), and remote (URL-based)
- **Auto-Discovery of MCP Servers**: Automatically discover and configure MCP servers from standard directories
- Discovers servers from `roles/ansible-ollama_mcphost/mcp_servers/` (shipped examples) and `~/mcp_servers/`
- **SLE16 Support**: Explicit support for SUSE Linux Enterprise 16.0 with automatic repository configuration
- **Example Configurations**: Ready-to-use samples (filesystem, bash-commands, web-fetcher, RISU agent, etc.) already live under `roles/ansible-ollama_mcphost/mcp_servers/`
- **GPU Support**: Optional GPU acceleration for Ollama (ROCm, CUDA)
- **Comprehensive Configuration**: Full support for all mcphost configuration options

## Quick Start

### Installation

#### Option 1: Run the playbook in-place (Recommended)

`deploy.yml` contains everything. Just run it—there’s no need to edit files or wire up roles paths manually (the bundled `ansible.cfg` already points Ansible at this checkout). Every MCP server placed under `roles/ansible-ollama_mcphost/mcp_servers/` (or `~/mcp_servers`) is picked up automatically:

```bash
git clone https://github.com/Spectro34/ansible-ollama_mcphost.git
cd ansible-ollama_mcphost
ansible-playbook deploy.yml
```

#### Option 2: Reference the role from your own playbooks

If you want to call the role from other playbooks or CI jobs, either clone it into a directory that already lives in `ANSIBLE_ROLES_PATH` or temporarily extend the path when running Ansible:

```bash
git clone https://github.com/Spectro34/ansible-ollama_mcphost.git
cd ansible-ollama_mcphost
ANSIBLE_ROLES_PATH=$(pwd):${ANSIBLE_ROLES_PATH:-$HOME/.ansible/roles} \
  ansible-playbook your-playbook.yml
```

### Basic Usage

**Standard flow (interactive CLI wrapper):**
```bash
./deploy.sh
```

The wrapper walks you through every core setting (model tag, GPU toggle, auto-discovery,
MCP servers, API key, system prompt). Accept the defaults by pressing **Enter**, or pass
flags (e.g., `./deploy.sh --model qwen2.5:14b --enable-gpu --servers filesystem`).
Run `./deploy.sh --help` to see every option and how to forward extra arguments to
`ansible-playbook`.
When you finish the short questionnaire the script simply shells out to
`ansible-playbook deploy.yml` with the collected settings.

**For CI / advanced users:**
```bash
ansible-playbook deploy.yml
```

The bare playbook no longer prompts; it reads everything from `-e` overrides or the
defaults shown below. By default it installs Ollama + mcphost and writes `~/.mcphost.yml`,
but **it does not enable any MCP servers** until you either set `auto_discover=true` or
pass a list via `-e "mcp_servers=['filesystem']"`. This keeps first runs predictable.

Need to override something? Pass `-e` values when running Ansible—for example:

```bash
ansible-playbook deploy.yml \
  -e "mcp_servers=['filesystem','bash-commands']" \
  -e "model=qwen2.5:14b" \
  -e "gpu_enabled=true" \
  -e "gpu_runtime=cuda"
```

**Note:** The repository ships with ready-to-use MCP server examples under `roles/ansible-ollama_mcphost/mcp_servers/`. Drop your own servers into that directory (or `~/mcp_servers`) and rerun the playbook to pick them up automatically.

### Core Operations

- `./deploy.sh` — interactive, default CPU-only Ollama and **no** MCP servers until you opt-in.
- `./deploy.sh --no-prompt --model qwen2.5:14b --enable-gpu --servers filesystem` — skip questions and drive everything through CLI flags.
- `ansible-playbook deploy.yml -e "mcp_servers=['filesystem','bash-commands']"` — run Ansible directly (CI-friendly).
- `ansible-playbook deploy.yml -e "gpu_enabled=true" -e "gpu_runtime=cuda"` — enable GPU acceleration explicitly.
- `ansible-playbook deploy.yml -e "ollama_state=absent" -e "mcphost_state=absent"` — remove everything that was previously installed.

Combine any number of `-e` overrides to match your environment; otherwise the defaults are used.


### Adding MCP Servers (Easy Workflow)

The role supports auto-discovery of MCP servers from multiple sources:

1. **Role's `roles/ansible-ollama_mcphost/mcp_servers/` directory**: YAML format server configs (e.g., `roles/ansible-ollama_mcphost/mcp_servers/bash-example/config.yml`)
2. **User's `~/mcp_servers/` directory**: Custom user-defined servers in YAML format
**Example workflow:**

1. **Create (or copy) the MCP server directory under `roles/ansible-ollama_mcphost/mcp_servers/`:**
   ```bash
   cd roles/ansible-ollama_mcphost/mcp_servers/
   mkdir my-server
   # Optional: copy files into my-server/ or drop an existing checkout there
   ```
   The repository already ships with ready-to-use examples such as `filesystem`, `bash-commands`, `web-fetcher`, and `risu-agent`, so you can deploy immediately without adding anything new. Creating a directory is only necessary when you want to add your own server.

2. **Create a `config.yml` file for each server:**
   ```bash
   cat > my-server/config.yml <<'YAML'
   my-server:
     type: "local"
     command: ["./run-server.sh"]
     cwd: "{{ server_dir }}"
     description: "Example custom server"
   YAML
   ```

3. **Deploy - then opt into the servers you need when prompted (CLI wrapper):**
   ```bash
   cd ../../../..
   ./deploy.sh
   # or drive it non-interactively
   ./deploy.sh --no-prompt --servers "bash,filesystem"
  ```
   When the script prompts you, answer **“y”** to auto-discover every server, or
   type the specific server names (e.g., `my-server,filesystem`) to enable only those.
   Tip: entering `risu-agent` automatically expands to
   `risu-agent-filesystem,risu-agent-bash`, so you only need to type the friendly alias once.

**Config File Format (`config.yml`):**
- Each `config.yml` should be in **mcphost's native format** - just the server configuration dictionary
- The file should contain only the server config, not wrapped in `mcpServers:` (the role handles that)
- Use `{{ server_dir }}` for paths relative to the server directory (automatically replaced)
- Use `${env://VAR_NAME}` for environment variable substitution in server environment variables
- The server name (key) should match the directory name or be unique
- See [roles/ansible-ollama_mcphost/mcp_servers/README.md](roles/ansible-ollama_mcphost/mcp_servers/README.md) for detailed examples

**API Keys:**
- **Recommended:** Use Ansible Vault to encrypt API keys in playbooks or variable files
  ```bash
  # Create encrypted variable file
  ansible-vault create group_vars/all/vault.yml
  # Add: mcphost_provider_api_key: "your-encrypted-key"
  
  # Or encrypt inline in playbook
  mcphost_provider_api_key: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          6638643965396631613264626361396530...
  ```
- **Alternative:** Use environment variables: `export OPENAI_API_KEY="your-key"` then set `mcphost_provider_api_key_env_var: "OPENAI_API_KEY"`
- **Less secure:** Set directly: `mcphost_provider_api_key: "your-key-here"` (not recommended for production)
- Ollama typically doesn't require API keys (uses local server)

See [roles/ansible-ollama_mcphost/mcp_servers/README.md](roles/ansible-ollama_mcphost/mcp_servers/README.md) for detailed MCP server configuration.

### RISU single-host workflows

`roles/ansible-ollama_mcphost/mcp_servers/risu-agent/` packages two builtin MCP servers that enable LLMs to run RISU diagnostics interactively:

- `risu-agent-filesystem` — readonly access to RISU installation (via `RISU_AGENT_ROOT`) and `/tmp` for reading RISU JSON output
- `risu-agent-bash` — executes RISU commands (`risu -l`, `risu --list-plugins`, etc.) and ansible-playbook for remediation

It's included in the default auto-discovery pass, so running `ansible-playbook deploy.yml` is enough. To run *only* the RISU agent helpers, pass `-e "mcp_servers=['risu-agent-filesystem','risu-agent-bash']"` (or simply enter `risu-agent` when the CLI wrapper asks for server names). 

After deployment, run `mcphost` interactively and ask the LLM to run RISU diagnostics. The LLM will use the available MCP tools to execute RISU commands and analyze results.

By default the helper points at `/usr/share/risu` (matching the packaged layout). If you have a custom checkout, set `RISU_AGENT_ROOT=/path/to/risu` in your shell before running `mcphost`.

See `roles/ansible-ollama_mcphost/mcp_servers/risu-agent/README.md` for detailed instructions.

### SLE16 Installation

```bash
ansible-playbook examples/sle16-example.yml
```

See [INSTALL.md](INSTALL.md) for detailed installation instructions.

## Requirements

- Ansible 2.9 or higher
- Target system: SLES 16.0+, openSUSE, EL 8/9, Fedora, Ubuntu, Debian
- For SLE16: Access to SUSE Customer Center or OBS repositories

## Role Variables

### Package Management

| Variable | Default | Description |
|----------|---------|-------------|
| `package_auto_refresh` | `true` | Auto-refresh package metadata (with key import) on zypper hosts |
| `package_refresh_command` | `["zypper", "--non-interactive", "--gpg-auto-import-keys", "refresh"]` | Command used when refreshing packages |
| `sle16_mcp_repo_enabled` | `true` | Automatically add SLE16 MCP repository when on SLES 16+ |
| `sle16_mcp_repo_url` | `"https://download.opensuse.org/repositories/science:/machinelearning:/mcp/SLE_16.0/science:machinelearning:mcp.repo"` | SLE16 MCP repository URL |
| `sle16_mcp_repo_name` | `"science:machinelearning:mcp"` | SLE16 MCP repository name |

### Ollama Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ollama_state` | `present` | `present` to install, `absent` to remove |
| `ollama_package_name` | `"ollama"` | Package name to install |
| `ollama_binary_path` | `"/usr/bin/ollama"` | Path to ollama binary |
| `ollama_service_name` | `"ollama"` | Systemd service name |
| `ollama_host` | `"localhost"` | Ollama service host |
| `ollama_service_port` | `11434` | Ollama service port |
| `ollama_model` | `"gpt-oss:20b"` | Default model tag |
| `ollama_pull_models` | `["gpt-oss:20b"]` | List of models to pull during installation |
| `ollama_gpu_enabled` | `false` | Enable GPU acceleration (opt-in, disabled by default) |
| `ollama_gpu_runtime` | `"rocm"` | GPU runtime: `"rocm"` or `"cuda"` |
| `ollama_cleanup_models` | `true` | Remove models when `ollama_state=absent` |
| `ollama_cleanup_data` | `true` | Remove data directory when `ollama_state=absent` |
| `ollama_cleanup_config` | `true` | Remove config when `ollama_state=absent` |
| `ollama_cleanup_binary` | `true` | Remove package when `ollama_state=absent` |

### mcphost Configuration

> **Managed config.** Each run rewrites `~/.mcphost.yml` using the values below plus the discovered MCP servers. Adjust these variables (or edit `templates/mcphost-config.yml.j2`) if you need different defaults.

#### Basic Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `mcphost_state` | `present` | `present` to install, `absent` to remove |
| `mcphost_package_name` | `"mcphost"` | Package name to install |
| `mcphost_executable` | `"mcphost"` | mcphost executable name |
| `mcphost_config_path` | `"{{ ansible_env.HOME }}/.mcphost.yml"` | Path to mcphost configuration file |

#### Model / Provider Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `mcphost_model_provider` | `"ollama"` | Provider used when bootstrapping |
| `mcphost_model_name` | `"{{ ollama_model }}"` | Model name used when bootstrapping |
| `mcphost_provider_url` | `"http://{{ ollama_host }}:{{ ollama_service_port }}"` | Provider URL |
| `mcphost_provider_api_key` | `""` | API key (optional) |
| `mcphost_provider_api_key_env_var` | `""` | Environment variable name to read API key from |
| `mcphost_tls_skip_verify` | `false` | Skip TLS validation |
| `mcphost_temperature` | `0.7` | Default temperature |
| `mcphost_max_tokens` | `4096` | Default max tokens |
| `mcphost_top_p` | `0.95` | Default top-p |
| `mcphost_top_k` | `40` | Default top-k |
| `mcphost_stop_sequences` | `[]` | Default stop sequences |
| `mcphost_max_steps` | `0` | Default tool-calling steps |
| `mcphost_stream` | `true` | Enable streaming |
| `mcphost_debug` | `false` | Enable debug logging |
| `mcphost_system_prompt` | `""` | Inline system prompt |
| `mcphost_system_prompt_file` | `""` | System prompt file |

> **Need different defaults?** Edit `.mcphost.yml` after the run or adjust the variables below when invoking `ansible-playbook`.

#### MCP Server Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `mcphost_mcp_servers` | `[]` | Manual MCP server definitions |
| `mcphost_mcp_servers_auto_discover` | `true` | Automatically discover MCP servers |
| `mcphost_mcp_servers_dirs` | `["{{ role_path }}/mcp_servers", "{{ lookup('env', 'HOME') }}/mcp_servers"]` | Directories to search for MCP server config files |
| `mcphost_mcp_servers_filter` | `[]` | Optional filter when auto-discovering |
| `mcphost_servers_base_path` | `""` | Base directory for resolving relative paths |
| `mcphost_cleanup_package` | `false` | Uninstall package when state=absent |

### Legacy Variables (Deprecated)

| Variable | Default | Description |
|----------|---------|-------------|
| `mcphost_local_servers` | `[]` | Legacy local server definitions (use `mcphost_mcp_servers` instead) |
| `mcphost_endpoints` | `[]` | Legacy remote endpoint definitions (use `mcphost_mcp_servers` instead) |

## MCP Server Types

The `mcphost_mcp_servers` variable accepts a list of server definitions. Each server must have a `name` and `type` field.

### Builtin Servers

Builtin servers are integrated into mcphost. Available builtin servers:

- **`fs`** (filesystem): File system operations
- **`bash`**: Bash command execution
- **`http`**: HTTP requests

#### Builtin Server Configuration

```yaml
mcphost_mcp_servers:
  - name: "filesystem_tmp"
    type: "builtin"
    builtin_name: "fs"  # Required: "fs", "bash", or "http"
    options:  # Optional: server-specific options
      allowed_directories: ["/tmp", "/home/user/documents"]
    allowed_tools:  # Optional: restrict available tools
      - "read_file"
      - "write_file"
      - "list_directory"
```

**Filesystem Server Options:**
- `allowed_directories`: List of directories the server can access

**Filesystem Server Tools:**
- `read_file`: Read file contents
- `write_file`: Write to files
- `list_directory`: List directory contents

### Local Servers

Local servers run as separate processes via command execution.

#### Local Server Configuration

```yaml
mcphost_mcp_servers:
  - name: "monitor"
    type: "local"
    command: ["mcp-server-monitor"]  # Required: command and arguments
    cwd: "/opt/monitor"  # Optional: working directory
    environment:  # Optional: environment variables
      DEBUG: "true"
      API_KEY: "${env://MCP_API_KEY}"  # Use environment variable substitution
    description: "System monitoring server"  # Optional: description
```

**Note:** Use `${env://VAR_NAME}` syntax for environment variable substitution in configuration files.

### Remote Servers

Remote servers connect to MCP servers via HTTP/HTTPS.

#### Remote Server Configuration

```yaml
mcphost_mcp_servers:
  - name: "remote-server"
    type: "remote"
    url: "https://api.example.com/mcp"  # Required: server URL
    description: "Remote MCP server"  # Optional: description
```

## Example Playbooks

The role includes several example playbooks in the `examples/` directory:

**Note:** Basic examples (minimal, monitoring, built-ins, RISU agent, etc.) already live under `roles/ansible-ollama_mcphost/mcp_servers/`. Drop additional servers there (or under `~/mcp_servers`) and rerun the playbook to enable them.

### SLE16 Example

```yaml
# examples/sle16-example.yml
- hosts: localhost
  become: true
  roles:
    - role: ansible-ollama_mcphost
      sle16_mcp_repo_enabled: true
      ollama_model: "gpt-oss:20b"
      mcphost_mcp_servers:
        - name: "filesystem"
          type: "builtin"
          builtin_name: "fs"
          options:
            allowed_directories: ["/tmp"]
```

### OpenAI Provider

```yaml
# examples/openai-example.yml
- hosts: localhost
  roles:
    - role: ansible-ollama_mcphost
      ollama_state: absent
      mcphost_model_provider: "openai"
      mcphost_model_name: "gpt-4"
      mcphost_provider_url: "https://api.openai.com/v1"
      # Set API key via environment variable: export OPENAI_API_KEY="your-key"
      mcphost_mcp_servers:
        - name: "filesystem"
          type: "builtin"
          builtin_name: "fs"
          options:
            allowed_directories: ["/tmp"]
```

### Remote Server

```yaml
# examples/remote-server-example.yml
- hosts: localhost
  roles:
    - role: ansible-ollama_mcphost
      mcphost_mcp_servers:
        - name: "filesystem"
          type: "builtin"
          builtin_name: "fs"
          options:
            allowed_directories: ["/tmp"]
        - name: "remote-server"
          type: "remote"
          url: "https://api.example.com/mcp"
          description: "Remote MCP server"
```

### Available Examples

The role includes the following example playbooks:

- **`examples/sle16-example.yml`**: SLE16-specific configuration with repository setup
- **`examples/openai-example.yml`**: OpenAI provider configuration
- **`examples/remote-server-example.yml`**: Remote MCP server configuration
- **`examples/ansible-runner.yml`**: Ansible Runner MCP server integration
- **`examples/risu-agent.yml`**: RISU diagnostics helper (filesystem + bash helpers)

Need more? Add your own MCP servers under `roles/ansible-ollama_mcphost/mcp_servers/` (or `~/mcp_servers`) and rerun the playbook—they’ll be merged automatically.

## Deployment Types

### 1. Local Development

Minimal setup for local development with Ollama:

```yaml
- hosts: localhost
  roles:
    - role: ansible-ollama_mcphost
      ollama_model: "gpt-oss:20b"
      mcphost_mcp_servers:
        - name: "filesystem"
          type: "builtin"
          builtin_name: "fs"
          options:
            allowed_directories: ["/tmp"]
```

### 2. Production with GPU

Production setup with GPU acceleration:

```yaml
- hosts: gpu-servers
  become: true
  roles:
    - role: ansible-ollama_mcphost
      ollama_gpu_enabled: true
      ollama_gpu_runtime: "cuda"  # or "rocm"
      ollama_pull_models:
        - "qwen2.5:32b"
        - "gpt-oss:20b"
      mcphost_temperature: 0.3
      mcphost_max_tokens: 8192
```

### 3. Cloud Provider Integration

Use cloud provider APIs (OpenAI, Anthropic, Google):

```yaml
- hosts: localhost
  roles:
    - role: ansible-ollama_mcphost
      ollama_state: absent
      mcphost_model_provider: "openai"
      mcphost_model_name: "gpt-4"
      mcphost_provider_api_key: "{{ vault_openai_api_key }}"  # From Ansible Vault
```

### 4. Multi-Server MCP Setup

Connect to multiple MCP servers (local and remote):

```yaml
- hosts: localhost
  roles:
    - role: ansible-ollama_mcphost
      mcphost_mcp_servers:
        - name: "filesystem"
          type: "builtin"
          builtin_name: "fs"
          options:
            allowed_directories: ["/tmp"]
        - name: "monitor"
          type: "local"
          command: ["mcp-server-monitor"]
        - name: "remote-api"
          type: "remote"
          url: "https://api.example.com/mcp"
```

### 5. RISU Agent Example

The RISU agent helper (filesystem + constrained bash servers) already lives in this repository under
`roles/ansible-ollama_mcphost/mcp_servers/risu-agent/`. No cloning or
additional setup is required—just run the standard playbook.

```bash
# Deploy with every bundled MCP server (RISU agent included)
ansible-playbook deploy.yml

# Limit the deployment to only the RISU agent helpers
ansible-playbook deploy.yml \
  -e "mcp_servers=['risu-agent-filesystem','risu-agent-bash']"
```

After deployment, run `mcphost` interactively and ask the LLM to run RISU diagnostics.

Need a dedicated playbook? Use `examples/risu-agent.yml`:

```yaml
- hosts: localhost
  become: true
  roles:
    - role: ansible-ollama_mcphost
      ollama_gpu_enabled: true          # Optional
      ollama_gpu_runtime: "rocm"        # or "cuda"
      mcphost_mcp_servers_auto_discover: true
      # RISU agent servers are discovered automatically from
      # roles/ansible-ollama_mcphost/mcp_servers/risu-agent/
      # Set RISU_AGENT_ROOT to point at a different checkout if needed.
```

Set the `RISU_AGENT_ROOT` environment variable (or edit the files under
`roles/ansible-ollama_mcphost/mcp_servers/risu-agent/`) if you want the helper
to inspect a different RISU checkout.

### 6. SLE16 Enterprise Deployment

SLE16-specific deployment with example configs:

```yaml
- hosts: sle16-servers
  become: true
  roles:
    - role: ansible-ollama_mcphost
      sle16_mcp_repo_enabled: true
      ollama_model: "gpt-oss:20b"
      mcphost_mcp_servers:
        - name: "filesystem"
          type: "builtin"
          builtin_name: "fs"
          options:
            allowed_directories: ["/tmp"]
```

## Security Best Practices

1. **API Keys**: Never hardcode API keys in playbooks. Use:
   - **Ansible Vault (Recommended)**: Encrypt API keys in variable files
     ```bash
     # Create encrypted variable file
     ansible-vault create group_vars/all/vault.yml
     # Add: mcphost_provider_api_key: "your-api-key-here"
     
     # Run playbook with vault password
     ansible-playbook playbook.yml --ask-vault-pass
     # Or: ansible-playbook playbook.yml --vault-password-file ~/.vault_pass
     ```
     See [examples/vault-api-key-example.yml](examples/vault-api-key-example.yml) for a complete example.
   - **Environment Variables**: `export OPENAI_API_KEY="key"` then use `mcphost_provider_api_key_env_var: "OPENAI_API_KEY"`
   - **Runtime Variables**: `--extra-vars "mcphost_provider_api_key=key"` (less secure)

2. **Filesystem Access**: Always restrict filesystem servers to specific directories:
   ```yaml
   options:
     allowed_directories: ["/tmp", "/home/user/documents"]
   ```

3. **Tool Restrictions**: Limit available tools when possible:
   ```yaml
   allowed_tools: ["read_file", "list_directory"]  # Read-only
   ```

4. **TLS Verification**: Never disable TLS verification in production:
   ```yaml
   mcphost_tls_skip_verify: false  # Always false in production
   ```

## Handlers

- `Reload Ollama daemon`: Runs `systemctl daemon-reload` and restarts the Ollama service when GPU configuration changes

## Tags

| Tag | Purpose |
|-----|---------|
| `ollama` | Target Ollama tasks |
| `mcphost` | Target mcphost tasks |
| `install` | Run install/config steps |
| `cleanup` | Remove stack and config |

## Dependencies

None.

## License

MIT

## References

- [mcphost GitHub Repository](https://github.com/mark3labs/mcphost)
- [Ollama Documentation](https://ollama.com/)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [SLE16 Documentation](https://documentation.suse.com/sles/16.0/)

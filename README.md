# ansible-ollama_mcphost

![Ansible Lint](https://github.com/Spectro34/ansible-ollama_mcphost/action/workflows/ansible-lint.yml/badge.svg?branch=main)

Composable Ansible role for provisioning [Ollama](https://ollama.com/) and the [`mcphost`](https://github.com/mark3labs/mcphost) CLI. The role supports both installation and cleanup flows, optional GPU enablement, multiple model providers, and flexible MCP server configurations.

## Features

- **Flexible Model Provider Support**: Ollama, OpenAI, Anthropic, Google
- **Multiple MCP Server Types**: Builtin (filesystem, bash, http), local (command-based), and remote (URL-based)
- **Auto-Discovery of MCP Servers**: Automatically discover and configure MCP servers from standard directories
  - Discovers servers from `mcp_servers/` directories (YAML format)
  - Integrates with `mcphost-example-configs` package (JSON format)
  - Supports custom MCP servers in `~/mcp_servers/`
- **SLE16 Support**: Explicit support for SUSE Linux Enterprise 16.0 with automatic repository configuration
- **Example Configurations**: Works seamlessly with `mcphost-example-configs` package examples
- **GPU Support**: Optional GPU acceleration for Ollama (ROCm, CUDA)
- **Comprehensive Configuration**: Full support for all mcphost configuration options

## Quick Start

### Installation

#### Option 1: Install to Default Roles Path (Recommended)

This allows the role to be used from anywhere:

```bash
git clone https://github.com/Spectro34/ansible-ollama_mcphost.git
cd ansible-ollama_mcphost
./install-symlink.sh
```

The role will be available as `ansible-ollama_mcphost` in all playbooks.

#### Option 2: Use Directly from Repository

```bash
git clone https://github.com/Spectro34/ansible-ollama_mcphost.git
cd ansible-ollama_mcphost
ansible-playbook deploy.yml
# or use a specific example
ansible-playbook examples/sle16-example.yml
```

### Basic Usage

**Simplest way (recommended):**
```bash
./deploy.sh
```

**Or using playbook directly:**
```bash
ansible-playbook deploy.yml
```

**Note:** The role now integrates with `mcphost-example-configs` package. Examples like minimal, medium-reasoning, high-reasoning, monitoring, and built-ins are available from the package and can be selected using `./deploy.sh --servers <server1,server2>`. For detailed documentation, examples, and configuration reference, see the package documentation at `/usr/share/doc/packages/mcphost-example-configs/` (after installation).

### Everyday Commands

- `./deploy.sh` — install Ollama + mcphost with all discovered servers.
- `./deploy.sh --servers filesystem,bash-commands,risu-insights` — only enable the listed servers (use exact server names such as `bash-commands`, not shorthand like `bash`).
- `./deploy.sh --enable-gpu --gpu-runtime rocm` — turn on GPU acceleration (use `cuda` if needed).
- `./deploy.sh update` — re-run configuration after changing configs or secrets.
- `./deploy.sh remove` — uninstall everything, honoring cleanup flags.
- `./deploy.sh status` — sanity check that services, configs, and models are in place.

Each command is just a wrapper around `ansible-playbook deploy.yml`, so any additional Ansible variables can be passed with `ANSIBLE_EXTRA_VARS` or by editing `deploy.yml`.


### Adding MCP Servers (Easy Workflow)

The role supports auto-discovery of MCP servers from multiple sources:

1. **Role's `mcp_servers/` directory**: YAML format server configs (e.g., `mcp_servers/bash-example/config.yml`)
2. **User's `~/mcp_servers/` directory**: Custom user-defined servers in YAML format
3. **`mcphost-example-configs` package**: JSON format example configs from the package (if installed)

**Example workflow:**

1. **Clone MCP server repositories into `mcp_servers/` directory:**
   ```bash
   cd mcp_servers/
   git clone https://github.com/Spectro34/risu-insights.git risu-insights
   ```

2. **Create a `config.yml` file for each server:**
   ```bash
   # The config.yml file should already exist in risu-insights/
   # If not, see mcp_servers/risu-insights/README.md for setup instructions
   ```

3. **Deploy - all servers are automatically discovered and merged:**
   ```bash
   ./deploy.sh
   # or select specific servers
   ./deploy.sh --servers bash,filesystem,bash-commands
   ```

**Config File Format (`config.yml`):**
- Each `config.yml` should be in **mcphost's native format** - just the server configuration dictionary
- The file should contain only the server config, not wrapped in `mcpServers:` (the role handles that)
- Use `{{ server_dir }}` for paths relative to the server directory (automatically replaced)
- Use `${env://VAR_NAME}` for environment variable substitution in server environment variables
- The server name (key) should match the directory name or be unique
- See [mcp_servers/README.md](mcp_servers/README.md) for detailed examples

**Package Integration:**
- The `mcphost-example-configs` package is **automatically installed on SLES/openSUSE** systems
- On other systems, set `mcphost_example_configs_install: true` to install it
- The role extracts examples from the package and converts them to YAML format in `mcp_servers/`
- Package JSON configs are also auto-discovered directly (if package is installed)
- Both sources use the **same server names** (e.g., `filesystem`, `bash-commands`, `web-fetcher`)
- Use `--servers` option to select which servers to enable
- Examples in `mcp_servers/` are populated from the package for consistency

**Package Documentation and Information:**
- The `mcphost-example-configs` package includes comprehensive documentation and example configurations
- Package files are installed to `/usr/share/doc/packages/mcphost-example-configs/`
- Refer to the package documentation for:
  - Detailed MCP server configuration examples
  - Best practices for server setup
  - Additional configuration options and patterns
  - Reference implementations for different use cases
- View package contents: `rpm -ql mcphost-example-configs` (on RPM-based systems)
- Access package documentation: `ls /usr/share/doc/packages/mcphost-example-configs/`

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

See [mcp_servers/README.md](mcp_servers/README.md) for detailed MCP server configuration.

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
| `mcphost_example_configs_package` | `"mcphost-example-configs"` | Package name for example configs |
| `mcphost_example_configs_install` | `true` on SLES/openSUSE, `false` otherwise | Auto-install mcphost-example-configs package on SLES/openSUSE systems |

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

#### Basic Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `mcphost_state` | `present` | `present` to install, `absent` to remove |
| `mcphost_package_name` | `"mcphost"` | Package name to install |
| `mcphost_executable` | `"mcphost"` | mcphost executable name |
| `mcphost_config_path` | `"{{ ansible_env.HOME }}/.mcphost.yml"` | Path to mcphost configuration file |

#### Model Provider Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `mcphost_model_provider` | `"ollama"` | Provider: `"ollama"`, `"openai"`, `"anthropic"`, `"google"` |
| `mcphost_model_name` | `"{{ ollama_model }}"` | Model name (e.g., `"gpt-oss:20b"`, `"gpt-4"`, `"claude-sonnet-4-20250514"`) |
| `mcphost_provider_url` | `"http://{{ ollama_host }}:{{ ollama_service_port }}"` | Base URL for provider API |
| `mcphost_provider_api_key` | `""` | API key (recommended: use Ansible Vault for encryption) |
| `mcphost_provider_api_key_env_var` | `""` | Environment variable name to read API key from (e.g., "OPENAI_API_KEY") |
| `mcphost_tls_skip_verify` | `false` | Skip TLS certificate verification (WARNING: insecure) |

#### Model Generation Parameters

| Variable | Default | Description |
|----------|---------|-------------|
| `mcphost_temperature` | `0.7` | Controls randomness (0.0-1.0) |
| `mcphost_max_tokens` | `4096` | Maximum tokens in response |
| `mcphost_top_p` | `0.95` | Nucleus sampling (0.0-1.0) |
| `mcphost_top_k` | `40` | Top K tokens to sample from |
| `mcphost_stop_sequences` | `[]` | Custom stop sequences (list of strings) |

#### Agent Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `mcphost_max_steps` | `0` | Maximum agent steps (0 for unlimited) |
| `mcphost_stream` | `true` | Enable streaming responses |
| `mcphost_debug` | `false` | Enable debug logging |

#### System Prompt

| Variable | Default | Description |
|----------|---------|-------------|
| `mcphost_system_prompt` | `""` | System prompt text (empty = no system prompt) |
| `mcphost_system_prompt_file` | `""` | Path to system prompt file (alternative to `mcphost_system_prompt`) |

#### MCP Server Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `mcphost_mcp_servers` | `[]` | List of MCP server definitions (see MCP Server Types below) |
| `mcphost_mcp_servers_auto_discover` | `true` | Automatically discover MCP servers from configured directories |
| `mcphost_mcp_servers_dirs` | `["{{ role_path }}/mcp_servers", "{{ lookup('env', 'HOME') }}/mcp_servers", "/usr/share/doc/packages/mcphost-example-configs"]` | Directories to search for MCP server config files (YAML: `config.yml`, JSON: `*.json`) |
| `mcphost_servers_base_path` | `""` | Base directory for resolving relative paths in server configurations |
| `mcphost_cleanup_package` | `false` | Uninstall package when `mcphost_state=absent` |

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

**Note:** Basic examples (minimal, medium-reasoning, high-reasoning, monitoring, built-ins) are now provided by the `mcphost-example-configs` package. Install the package and use `./deploy.sh --servers <server1,server2>` to select them. The examples below show role-specific configurations.

### SLE16 Example

```yaml
# examples/sle16-example.yml
- hosts: localhost
  become: true
  roles:
    - role: ansible-ollama_mcphost
      sle16_mcp_repo_enabled: true
      ollama_model: "gpt-oss:20b"
      mcphost_example_configs_install: true
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
- **`examples/risu-insights.yml`**: RISU Insights MCP server deployment

**Package Examples:** The `mcphost-example-configs` package provides additional examples and documentation:
- Minimal configuration
- Medium and high reasoning configurations
- System monitoring setup
- Built-in tools reference
- Comprehensive documentation and configuration guides

For detailed documentation and examples, refer to the package files at `/usr/share/doc/packages/mcphost-example-configs/` after installation.

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

### 5. RISU Insights Server Setup

Deploy RISU Insights MCP server (requires server setup first):

```bash
# 1. Clone the repository
cd mcp_servers/
git clone https://github.com/Spectro34/risu-insights.git risu-insights

# 2. Set up dependencies
cd risu-insights
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 3. Deploy using the role
cd ../..
./deploy.sh --servers risu-insights --enable-gpu --gpu-runtime rocm
```

Or use the example playbook:

```yaml
- hosts: localhost
  roles:
    - role: ansible-ollama_mcphost
      ollama_gpu_enabled: true
      ollama_gpu_runtime: "rocm"
      # risu-insights will be auto-discovered from mcp_servers/risu-insights/config.yml
```

See [mcp_servers/risu-insights/README.md](mcp_servers/risu-insights/README.md) for detailed setup instructions.

### 6. SLE16 Enterprise Deployment

SLE16-specific deployment with example configs:

```yaml
- hosts: sle16-servers
  become: true
  roles:
    - role: ansible-ollama_mcphost
      sle16_mcp_repo_enabled: true
      mcphost_example_configs_install: true
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

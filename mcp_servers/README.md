# MCP Servers Directory

This directory contains MCP server configurations that can be automatically discovered and deployed by the `ansible-ollama_mcphost` role.

**Note:** The examples in this directory (`filesystem`, `bash-commands`, `web-fetcher`) are extracted from the `mcphost-example-configs` package and converted to YAML format for auto-discovery. They use the same server names as the package for consistency.

## Quick Start

### Example: RISU Insights Server

1. **Clone the RISU Insights repository:**
   ```bash
   cd mcp_servers/
   git clone https://github.com/Spectro34/risu-insights.git risu-insights
   ```

2. **Set up the server dependencies:**
   ```bash
   cd risu-insights
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Deploy using the role:**
   ```bash
   # From the role directory
   ./deploy.sh --servers risu-insights --enable-gpu --gpu-runtime rocm
   # Or use the example playbook
   ansible-playbook examples/risu-insights.yml
   ```

4. **Verify the setup:**
   ```bash
   mcphost
   ```

The role will automatically discover and configure all MCP servers in this directory. See [risu-insights/README.md](risu-insights/README.md) for detailed RISU Insights setup instructions.

### Adding Your Own MCP Server

1. **Clone or create your MCP server in this directory:**
   ```bash
   cd mcp_servers/
   git clone <your-server-repo> <server-name>
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

3. **Deploy using the role:**
   ```bash
   ./deploy.sh --servers your-server
   ```

## Directory Structure

```
mcp_servers/
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
├── risu-insights/               # Custom MCP server repository
│   ├── config.yml               # Server configuration (auto-discovered)
│   └── ...                     # Other server files
└── another-server/              # Another custom MCP server
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

The role automatically discovers MCP servers by:

1. Looking in `mcp_servers/` directory (configurable via `mcphost_mcp_servers_dir`)
2. Finding subdirectories that contain a `config.yml` file
3. Loading and merging configurations into `mcphost_mcp_servers`

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

## Package Documentation

The `mcphost-example-configs` package includes comprehensive documentation and example configurations:

- **Package Location**: `/usr/share/doc/packages/mcphost-example-configs/`
- **View Package Contents**: `rpm -ql mcphost-example-configs` (on RPM-based systems)
- **Access Documentation**: `ls /usr/share/doc/packages/mcphost-example-configs/`

The package documentation provides:
- Detailed MCP server configuration examples
- Best practices for server setup
- Additional configuration options and patterns
- Reference implementations for different use cases
- JSON format example configurations that are auto-discovered by the role

Refer to the package documentation for additional examples and detailed configuration reference beyond what's provided in this role.


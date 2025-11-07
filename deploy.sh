#!/bin/bash
# Universal deployment wrapper script for ansible-ollama_mcphost
# Provides a user-friendly interface for deploying Ollama and mcphost

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROLE_NAME="ansible-ollama_mcphost"

# Default values
MODEL="gpt-oss:20b"
GPU_ENABLED="false"  # GPU is opt-in, not enabled by default
GPU_RUNTIME="rocm"
AUTO_DISCOVER="false"  # Disabled by default - servers must be explicitly selected
MCP_SERVERS=""  # Empty = all discovered servers
ACTION="deploy"
ROLE_PATH=""
API_KEY=""
API_KEY_ENV_VAR=""
SYSTEM_PROMPT=""
SYSTEM_PROMPT_FILE=""

# Function to print usage
usage() {
    cat << EOF
Universal Deployment Script for ansible-ollama_mcphost

Usage:
    $0 [OPTIONS] [ACTION]

Actions:
    deploy          Deploy Ollama and mcphost (default)
    remove          Remove Ollama and mcphost
    update          Update configuration
    status          Show deployment status

Options:
    --model MODEL           Model to use (default: gpt-oss:20b)
    --enable-gpu            Enable GPU acceleration (opt-in, disabled by default)
    --gpu-runtime RUNTIME   GPU runtime: rocm or cuda (default: rocm)
    --servers SERVERS       Comma-separated list of MCP servers to deploy (default: all)
    --api-key KEY           API key for provider (use --api-key-env-var for security)
    --api-key-env-var VAR   Environment variable name containing API key (e.g., OPENAI_API_KEY)
    --system-prompt TEXT    System prompt text for mcphost
    --system-prompt-file PATH  Path to system prompt file (alternative to --system-prompt)
    --role-path PATH        Path to role (auto-detected if not specified)
    --help                  Show this help message

Examples:
    # Deploy with defaults
    $0

    # Deploy specific model
    $0 --model mistral:7b

    # Deploy with GPU enabled
    $0 --enable-gpu

    # Deploy specific MCP servers
    $0 --servers risu-insights,monitor

    # Deploy with GPU and specific servers
    $0 --enable-gpu --servers risu-insights

    # Deploy with system prompt
    $0 --system-prompt "You are a helpful assistant."

    # Deploy with system prompt file
    $0 --system-prompt-file /path/to/prompt.txt

    # Remove deployment
    $0 remove

    # Update configuration
    $0 update

MCP Server Selection:
    MCP servers must be explicitly selected using --servers option.
    Auto-discovery is disabled by default. To enable:
    - Use --servers option to specify which servers to deploy
    - Example: --servers filesystem,bash,risu-insights

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --model)
            if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                echo "Error: --model requires a value" >&2
                usage
                exit 1
            fi
            MODEL="$2"
            shift 2
            ;;
        --enable-gpu)
            GPU_ENABLED="true"
            shift
            ;;
        --gpu-runtime)
            if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                echo "Error: --gpu-runtime requires a value (rocm or cuda)" >&2
                usage
                exit 1
            fi
            GPU_RUNTIME="$2"
            shift 2
            ;;
        --servers)
            if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                echo "Error: --servers requires a value (comma-separated list)" >&2
                usage
                exit 1
            fi
            MCP_SERVERS="$2"
            shift 2
            ;;
        --api-key)
            if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                echo "Error: --api-key requires a value" >&2
                usage
                exit 1
            fi
            API_KEY="$2"
            shift 2
            ;;
        --api-key-env-var)
            if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                echo "Error: --api-key-env-var requires a value" >&2
                usage
                exit 1
            fi
            API_KEY_ENV_VAR="$2"
            shift 2
            ;;
        --system-prompt)
            if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                echo "Error: --system-prompt requires a value" >&2
                usage
                exit 1
            fi
            SYSTEM_PROMPT="$2"
            shift 2
            ;;
        --system-prompt-file)
            if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                echo "Error: --system-prompt-file requires a value" >&2
                usage
                exit 1
            fi
            SYSTEM_PROMPT_FILE="$2"
            shift 2
            ;;
        --role-path)
            if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
                echo "Error: --role-path requires a value" >&2
                usage
                exit 1
            fi
            ROLE_PATH="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        deploy|remove|update|status)
            ACTION="$1"
            shift
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

# Auto-detect role path
if [ -z "$ROLE_PATH" ]; then
    # Check if we're in the role directory
    if [ -f "$SCRIPT_DIR/deploy.yml" ] && [ -d "$SCRIPT_DIR/tasks" ]; then
        ROLE_PATH="$SCRIPT_DIR"
    # Check if role is installed in default location
    elif [ -d "$HOME/.ansible/roles/$ROLE_NAME" ]; then
        ROLE_PATH="$HOME/.ansible/roles/$ROLE_NAME"
    # Check ANSIBLE_ROLES_PATH
    elif [ -n "${ANSIBLE_ROLES_PATH:-}" ]; then
        # Try first path in ANSIBLE_ROLES_PATH
        FIRST_PATH=$(echo "$ANSIBLE_ROLES_PATH" | cut -d: -f1)
        if [ -d "$FIRST_PATH/$ROLE_NAME" ]; then
            ROLE_PATH="$FIRST_PATH/$ROLE_NAME"
        fi
    fi
fi

# Validate role path
if [ -z "$ROLE_PATH" ] || [ ! -f "$ROLE_PATH/deploy.yml" ]; then
    echo "Error: Could not find role directory" >&2
    echo "Please specify --role-path or install the role using:"
    echo "  cd $SCRIPT_DIR && ./install-symlink.sh"
    exit 1
fi

echo "========================================"
echo "ansible-ollama_mcphost Deployment"
echo "========================================"
echo ""
echo "Role path: $ROLE_PATH"
echo "Action: $ACTION"
echo ""

# Build ansible-playbook command
ANSIBLE_CMD="ansible-playbook"
ANSIBLE_ARGS=(
    "$ROLE_PATH/deploy.yml"
    "-e" "deployment_model=$MODEL"
    "-e" "deployment_gpu_enabled=$GPU_ENABLED"
    "-e" "deployment_gpu_runtime=$GPU_RUNTIME"
    "-e" "deployment_auto_discover=$AUTO_DISCOVER"
    "-e" "deployment_api_key=$API_KEY"
    "-e" "deployment_api_key_env_var=$API_KEY_ENV_VAR"
    "-e" "role_path_detected=$ROLE_PATH"
)

# Add system prompt if specified
if [ -n "$SYSTEM_PROMPT" ]; then
    ANSIBLE_ARGS+=("-e" "deployment_system_prompt=$SYSTEM_PROMPT")
fi

# Add system prompt file if specified
if [ -n "$SYSTEM_PROMPT_FILE" ]; then
    ANSIBLE_ARGS+=("-e" "deployment_system_prompt_file=$SYSTEM_PROMPT_FILE")
fi

# Add MCP servers if specified
if [ -n "$MCP_SERVERS" ]; then
    # Convert comma-separated to YAML list format properly
    # Split by comma, wrap each in quotes, join with comma
    # Use python for reliable YAML list generation
    MCP_SERVERS_YAML=$(python3 -c "import sys; items = sys.argv[1].split(','); print('[' + ','.join([\"'\" + item.strip() + \"'\" for item in items]) + ']')" "$MCP_SERVERS")
    ANSIBLE_ARGS+=("-e" "mcp_servers=$MCP_SERVERS_YAML")
fi

# Handle different actions
case $ACTION in
    deploy)
        echo "Deploying with:"
        echo "  Model: $MODEL"
        echo "  GPU: $GPU_ENABLED" 
        if [ "$GPU_ENABLED" = "true" ]; then
            echo "  GPU Runtime: $GPU_RUNTIME"
        fi
        if [ -n "$MCP_SERVERS" ]; then
            echo "  MCP Servers: $MCP_SERVERS"
        else
            echo "  Warning: No MCP servers specified. Use --servers to select servers."
        fi
        if [ -n "$SYSTEM_PROMPT" ]; then
            echo "  System Prompt: (text provided)"
        elif [ -n "$SYSTEM_PROMPT_FILE" ]; then
            echo "  System Prompt File: $SYSTEM_PROMPT_FILE"
        fi
        echo ""
        $ANSIBLE_CMD "${ANSIBLE_ARGS[@]}"
        ;;
    remove)
        echo "Removing Ollama and mcphost..."
        $ANSIBLE_CMD "$ROLE_PATH/deploy.yml" \
            -e "ollama_state=absent" \
            -e "mcphost_state=absent" \
            -e "role_path=$ROLE_PATH"
        ;;
    update)
        echo "Updating configuration..."
        $ANSIBLE_CMD "${ANSIBLE_ARGS[@]}"
        ;;
    status)
        echo "Deployment Status:"
        echo ""
        if command -v ollama >/dev/null 2>&1; then
            echo "Ollama installed"
            ollama list 2>/dev/null || echo "  (Ollama service may not be running)"
        else
            echo "Ollama not installed"
        fi
        echo ""
        if command -v mcphost >/dev/null 2>&1; then
            echo "mcphost installed"
            if [ -f "$HOME/.mcphost.yml" ]; then
                echo "Configuration file exists"
                echo "  Location: $HOME/.mcphost.yml"
            else
                echo "Configuration file not found"
            fi
        else
            echo "mcphost not installed"
        fi
        echo ""
        # Check for MCP servers
        if [ -d "$ROLE_PATH/mcp_servers" ]; then
            SERVER_COUNT=$(find "$ROLE_PATH/mcp_servers" -name "config.yml" 2>/dev/null | wc -l)
            if [ "$SERVER_COUNT" -gt 0 ]; then
                echo "Found $SERVER_COUNT MCP server(s) in role directory"
            fi
        fi
        if [ -d "$HOME/mcp_servers" ]; then
            SERVER_COUNT=$(find "$HOME/mcp_servers" -name "config.yml" 2>/dev/null | wc -l)
            if [ "$SERVER_COUNT" -gt 0 ]; then
                echo "Found $SERVER_COUNT MCP server(s) in home directory"
            fi
        fi
        ;;
    *)
        echo "Error: Unknown action: $ACTION" >&2
        usage
        exit 1
        ;;
esac

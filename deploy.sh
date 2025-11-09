#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}"

MODEL="gpt-oss:20b"
GPU_ENABLED="false"
GPU_RUNTIME="rocm"
AUTO_DISCOVER="false"
MCP_SERVERS=""
API_KEY=""
API_KEY_ENV_VAR=""
SYSTEM_PROMPT=""
SYSTEM_PROMPT_FILE=""
PROMPT=true
ANSIBLE_ARGS=()

usage() {
  cat <<'USAGE'
Usage: ./deploy.sh [options] [-- <ansible-playbook args>]

Options:
  --model MODEL             Model tag (default: gpt-oss:20b)
  --enable-gpu              Enable GPU acceleration (default: disabled)
  --gpu-runtime RUNTIME     GPU runtime (rocm or cuda, default: rocm)
  --servers LIST            Comma separated MCP server directory names (e.g., risu-agent,filesystem)
                            Each directory will load ALL servers from its config.yml
  --auto-discover           Auto-discover every MCP server found on disk
  --api-key KEY             Provider API key (not recommended; prefer env var)
  --api-key-env-var VAR     Environment variable that contains the provider API key
  --system-prompt TEXT      Inline system prompt text
  --system-prompt-file PATH Path to a system prompt file
  --no-prompt               Skip interactive questions and rely solely on CLI flags
  -h, --help                Show this help

Any arguments after `--` are passed straight to ansible-playbook.
USAGE
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model)
        MODEL="$2"; shift 2;;
      --enable-gpu)
        GPU_ENABLED="true"; shift;;
      --gpu-runtime)
        GPU_RUNTIME="$2"; shift 2;;
      --servers)
        MCP_SERVERS="$2"; shift 2;;
      --auto-discover)
        AUTO_DISCOVER="true"; shift;;
      --api-key)
        API_KEY="$2"; shift 2;;
      --api-key-env-var)
        API_KEY_ENV_VAR="$2"; shift 2;;
      --system-prompt)
        SYSTEM_PROMPT="$2"; shift 2;;
      --system-prompt-file)
        SYSTEM_PROMPT_FILE="$2"; shift 2;;
      --no-prompt)
        PROMPT=false; shift;;
      -h|--help)
        usage; exit 0;;
      --)
        shift
        ANSIBLE_ARGS+=("$@")
        break;;
      *)
        echo "Unknown option: $1" >&2
        usage
        exit 1;;
    esac
  done
}

prompt_if_needed() {
  $PROMPT || return 0

  read -r -p "Model tag [${MODEL}]: " input
  if [[ -n "$input" ]]; then
    MODEL="$input"
  fi

  read -r -p "Enable GPU acceleration? (y/N): " input
  if [[ "${input,,}" =~ ^(y|yes)$ ]]; then
    GPU_ENABLED="true"
    read -r -p "GPU runtime [${GPU_RUNTIME}]: " runtime
    if [[ -n "$runtime" ]]; then
      GPU_RUNTIME="$runtime"
    fi
  fi

  read -r -p "Auto-discover ALL MCP servers? (y/N): " input
  if [[ "${input,,}" =~ ^(y|yes)$ ]]; then
    AUTO_DISCOVER="true"
  fi

  read -r -p "Comma separated MCP server directory names to enable (blank for none, e.g., risu-agent): " input
  if [[ -n "$input" ]]; then
    MCP_SERVERS="$input"
  fi

  read -r -p "Environment variable for provider API key (blank to skip): " input
  if [[ -n "$input" ]]; then
    API_KEY_ENV_VAR="$input"
  fi

  if [[ -z "$API_KEY_ENV_VAR" ]]; then
    read -r -s -p "Provider API key (leave blank to skip): " input
    echo
    if [[ -n "$input" ]]; then
      API_KEY="$input"
    fi
  fi

  read -r -p "System prompt file path (blank to skip): " input
  if [[ -n "$input" ]]; then
    SYSTEM_PROMPT_FILE="$input"
  fi

  if [[ -z "$SYSTEM_PROMPT_FILE" ]]; then
    read -r -p "Inline system prompt text (blank to skip): " input
    if [[ -n "$input" ]]; then
      SYSTEM_PROMPT="$input"
    fi
  fi
}

# No longer needed - the role now handles directory-based selection
# expand_server_aliases() {
#   # This function is deprecated - directory names are passed directly to the role
# }

build_playbook_cmd() {
  local -a extra_vars
  extra_vars+=("-e" "model=${MODEL}")
  extra_vars+=("-e" "gpu_enabled=${GPU_ENABLED}")
  extra_vars+=("-e" "gpu_runtime=${GPU_RUNTIME}")
  extra_vars+=("-e" "auto_discover=${AUTO_DISCOVER}")

  if [[ -n "$MCP_SERVERS" ]]; then
    extra_vars+=("-e" "mcp_servers=${MCP_SERVERS}")
  fi
  if [[ -n "$API_KEY" ]]; then
    extra_vars+=("-e" "api_key=${API_KEY}")
  fi
  if [[ -n "$API_KEY_ENV_VAR" ]]; then
    extra_vars+=("-e" "api_key_env_var=${API_KEY_ENV_VAR}")
  fi
  if [[ -n "$SYSTEM_PROMPT" ]]; then
    extra_vars+=("-e" "system_prompt=${SYSTEM_PROMPT}")
  fi
  if [[ -n "$SYSTEM_PROMPT_FILE" ]]; then
    extra_vars+=("-e" "system_prompt_file=${SYSTEM_PROMPT_FILE}")
  fi

  CMD=(ansible-playbook "${REPO_ROOT}/deploy.yml" "${extra_vars[@]}" "${ANSIBLE_ARGS[@]}")
}

main() {
  parse_args "$@"
  prompt_if_needed
  # expand_server_aliases removed - role now handles directory-based selection
  build_playbook_cmd
  (
    cd "${REPO_ROOT}"
    echo "Executing: ${CMD[*]}"
    "${CMD[@]}"
  )
}

main "$@"

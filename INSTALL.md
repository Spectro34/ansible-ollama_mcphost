# Installation Guide

## Quick installation (recommended)

Use the provided playbook directly from the cloned repository—no symlink or wrapper script is required. Run it as-is to accept the defaults, or pass `-e` overrides if you need something specific. The bundled `ansible.cfg` already adds the current directory to `roles_path`, so Ansible can find the role automatically.

```bash
git clone https://github.com/Spectro34/ansible-ollama_mcphost.git
cd ansible-ollama_mcphost
ansible-playbook deploy.yml
```

That command configures Ollama, mcphost, and any selected MCP servers in one pass. Re-run it whenever you change variables or want to remove/update the deployment (e.g., `ansible-playbook deploy.yml -e "ollama_state=absent" -e "mcphost_state=absent"` to uninstall).

## Using the role inside your own playbooks

If you prefer to call the role from custom playbooks or CI pipelines, you have two options:

1. **Extend `ANSIBLE_ROLES_PATH` when running Ansible** (simple, no additional install):
   ```bash
   git clone https://github.com/Spectro34/ansible-ollama_mcphost.git
   cd ansible-ollama_mcphost
   ANSIBLE_ROLES_PATH=$(pwd):${ANSIBLE_ROLES_PATH:-$HOME/.ansible/roles} \
     ansible-playbook your-playbook.yml
   ```
2. **Copy the role into an existing roles directory** (persistent):
   ```bash
   git clone https://github.com/Spectro34/ansible-ollama_mcphost.git
   mkdir -p ~/.ansible/roles
   cp -a ansible-ollama_mcphost ~/.ansible/roles/ansible-ollama_mcphost
   ```

After either approach, include the role normally:

```yaml
- hosts: localhost
  roles:
    - role: ansible-ollama_mcphost
      ollama_model: "gpt-oss:20b"
```

## Verification

Run a simple playbook (or one of the examples under `examples/`) with `ANSIBLE_ROLES_PATH` pointing at the clone/copy to confirm everything resolves correctly:

```bash
ANSIBLE_ROLES_PATH=/path/to/ansible-ollama_mcphost ansible-playbook examples/openai-example.yml
```

## Removal

- If you run the role straight from the repository, simply delete the clone directory.
- If you copied it into `~/.ansible/roles`, remove that directory: `rm -rf ~/.ansible/roles/ansible-ollama_mcphost`.

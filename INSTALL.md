# Installation Guide

## Quick Installation

This role can be used from anywhere by creating a symlink to the default Ansible roles path.

### Automatic Installation

Run the installation script:

```bash
./install-symlink.sh
```

### Manual Installation

Create a symlink to the default Ansible roles path:

```bash
# Create roles directory if it doesn't exist
mkdir -p ~/.ansible/roles

# Create symlink (adjust path as needed)
ln -sf $(pwd) ~/.ansible/roles/ansible-ollama_mcphost
```

### Verify Installation

Check that the role is accessible:

```bash
# List installed roles
ansible-galaxy role list

# Or test with a playbook
ansible-playbook -e "roles_path=~/.ansible/roles" your-playbook.yml
```

## Using the Role

Once installed, you can use the role from anywhere:

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

## Alternative: Using roles_path

You can also specify the roles path directly in your playbook or ansible.cfg:

```yaml
# In ansible.cfg
[defaults]
roles_path = ~/.ansible/roles:/path/to/other/roles
```

Or in your playbook:

```bash
ansible-playbook -e "roles_path=~/.ansible/roles" your-playbook.yml
```

## Uninstallation

To remove the symlink:

```bash
rm ~/.ansible/roles/ansible-ollama_mcphost
```

## System-wide Installation (Optional)

For system-wide access (requires root):

```bash
sudo mkdir -p /usr/share/ansible/roles
sudo ln -sf $(pwd) /usr/share/ansible/roles/ansible-ollama_mcphost
```


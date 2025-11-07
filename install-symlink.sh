#!/bin/bash
# Install symlink to default Ansible roles path
# This allows the role to be used from anywhere

set -e

ROLE_NAME="ansible-ollama_mcphost"
ROLE_DIR="$(cd "$(dirname "$0")" && pwd)"
ANSIBLE_ROLES_DIR="${HOME}/.ansible/roles"
SYMLINK_PATH="${ANSIBLE_ROLES_DIR}/${ROLE_NAME}"

echo "============================================"
echo "Installing ${ROLE_NAME} to Ansible roles path"
echo "============================================"
echo "Role directory: ${ROLE_DIR}"
echo "Symlink target: ${SYMLINK_PATH}"
echo ""

# Create roles directory if it doesn't exist
if [ ! -d "${ANSIBLE_ROLES_DIR}" ]; then
    echo "Creating Ansible roles directory: ${ANSIBLE_ROLES_DIR}"
    mkdir -p "${ANSIBLE_ROLES_DIR}"
fi

# Remove existing symlink if it exists
if [ -L "${SYMLINK_PATH}" ]; then
    echo "Removing existing symlink: ${SYMLINK_PATH}"
    rm "${SYMLINK_PATH}"
elif [ -e "${SYMLINK_PATH}" ]; then
    echo "Warning: ${SYMLINK_PATH} exists and is not a symlink"
    echo "Please remove it manually and run this script again"
    exit 1
fi

# Create symlink
echo "Creating symlink: ${SYMLINK_PATH} -> ${ROLE_DIR}"
ln -sf "${ROLE_DIR}" "${SYMLINK_PATH}"

# Verify symlink
if [ -L "${SYMLINK_PATH}" ] && [ -e "${SYMLINK_PATH}" ]; then
    echo ""
    echo "✓ Symlink created successfully!"
    echo ""
    echo "Verification:"
    ls -la "${SYMLINK_PATH}"
    echo ""
    echo "The role is now available as: ${ROLE_NAME}"
    echo ""
    echo "You can now use it in playbooks from anywhere:"
    echo "  - role: ${ROLE_NAME}"
    echo ""
else
    echo "✗ Error: Symlink creation failed"
    exit 1
fi


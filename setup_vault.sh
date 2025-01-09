#!/usr/bin/env bash

set -e  # Exit on error

TEMPLATE_FILE="group_vars/all/secrets_template.yml"
VAULT_FILE="group_vars/all/secrets.yml"

if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "ERROR: Template file $TEMPLATE_FILE not found!"
  exit 1
fi

echo "Copying $TEMPLATE_FILE -> $VAULT_FILE..."
cp "$TEMPLATE_FILE" "$VAULT_FILE"

# Extract placeholders from lines that are NOT commented out.
PLACEHOLDERS=$(grep -vE '^\s*#' "$TEMPLATE_FILE" | grep -Eo 'PLACEHOLDER_[A-Za-z0-9_]+' | sort -u)

if [ -z "$PLACEHOLDERS" ]; then
  echo "No placeholders found in non-commented lines. Nothing to replace."
else
  echo "Detected placeholders: $PLACEHOLDERS"

  # For each unique placeholder, prompt user once.
  for placeholder in $PLACEHOLDERS; do
    varname="${placeholder#PLACEHOLDER_}"
    read -srp "Enter value for $varname: " userval
    echo ""

    # Use a cross-platform compatible sed command
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS: Use empty '' with -i to prevent creating backup files
      sed -i '' "s%$placeholder%$userval%g" "$VAULT_FILE"
    else
      # Linux: Use -i without ''
      sed -i "s%$placeholder%$userval%g" "$VAULT_FILE"
    fi
  done
fi

echo "All placeholders replaced in $VAULT_FILE."

# Encrypt the vault file with Ansible Vault
echo "Encrypting $VAULT_FILE using Ansible Vault..."
ansible-vault encrypt "$VAULT_FILE"

if [[ $? -eq 0 ]]; then
  echo "Vault file $VAULT_FILE has been successfully encrypted."
else
  echo "ERROR: Failed to encrypt $VAULT_FILE with Ansible Vault."
  exit 1
fi

echo "Reminder: $VAULT_FILE should be listed in .gitignore so it's never committed to the repo."
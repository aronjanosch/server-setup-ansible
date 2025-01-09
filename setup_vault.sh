#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# This script:
# 1. Copies secret_template.yml to secret.yml
# 2. Prompts the user to fill in each placeholder from non-commented lines
# 3. Replaces those placeholders in secret.yml
# 4. Encrypts secret.yml using Ansible Vault
# 5. Leaves secret.yml (now encrypted) ignored by git
#
# Requirements:
#  - Ansible installed (for ansible-vault)
#  - For Mac users who set hashed passwords: "pip install passlib" if you see crypt issues
# -----------------------------------------------------------------------------------

set -e  # Exit on error

TEMPLATE_FILE="group_vars/all/secret_template.yml"
VAULT_FILE="group_vars/all/secret.yml"

if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "ERROR: Template file $TEMPLATE_FILE not found!"
  exit 1
fi

echo "Copying $TEMPLATE_FILE -> $VAULT_FILE..."
cp "$TEMPLATE_FILE" "$VAULT_FILE"

# Extract placeholders from lines that are NOT commented out.
# -vE '^\s*#' excludes lines starting with "#"
# -oP 'PLACEHOLDER_[A-Za-z0-9_]+' finds tokens like PLACEHOLDER_SOMETHING
# sort -u ensures each placeholder is prompted once.
PLACEHOLDERS=$(grep -vE '^\s*#' "$TEMPLATE_FILE" | grep -oP 'PLACEHOLDER_[A-Za-z0-9_]+' | sort -u)

if [ -z "$PLACEHOLDERS" ]; then
  echo "No placeholders found in non-commented lines. Nothing to replace."
else
  echo "Detected placeholders: $PLACEHOLDERS"

  # For each unique placeholder, prompt user once.
  for placeholder in $PLACEHOLDERS; do
    # Remove the "PLACEHOLDER_" prefix to create a friendlier prompt.
    varname="${placeholder#PLACEHOLDER_}"

    # Prompt silently (-s) so password input doesn't echo. Remove the -s if you want to see typed text.
    read -srp "Enter value for $varname: " userval
    echo ""

    # Replace placeholder everywhere it appears in the vault file.
    # Using '%' as the sed delimiter to handle special chars in the userval.
    sed -i "s%$placeholder%$userval%g" "$VAULT_FILE"
  done
fi

echo "All placeholders replaced in $VAULT_FILE."

# Encrypt the vault file with Ansible Vault
# This will prompt you for a Vault password.
ansible-vault encrypt "$VAULT_FILE"

echo "Vault file $VAULT_FILE is now encrypted."
echo "Reminder: $VAULT_FILE should be listed in .gitignore so it's never committed to the repo."
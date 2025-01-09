# Ansible Server Configuration

This repository contains an **Ansible** project for configuring a newly installed server with the following features:

- **Roles** for modular configuration (e.g., `common`, `user`, `security`, `docker`, `extras`)
- **Support for passwordless sudo** (for the main user)
- **Optional Docker installation**
- **Secure secrets management** via **Ansible Vault**
- **Dynamic script** to populate and encrypt vault secrets

---

## Table of Contents

- [Ansible Server Configuration](#ansible-server-configuration)
  - [Table of Contents](#table-of-contents)
  - [Quick Start](#quick-start)
  - [Group and Host Variables](#group-and-host-variables)
  - [Securing Secrets with Vault](#securing-secrets-with-vault)
  - [Running the Playbook](#running-the-playbook)
  - [FAQ / Common Issues](#faq--common-issues)

---

### Key Files

- **`run.yml`**: The top-level playbook that includes all roles in sequence.
- **`inventory/production.yml`**: Defines your hosts.
- **`group_vars/all/vars.yml`**: General, non-sensitive defaults (e.g., `user_name`, `install_docker`).
- **`group_vars/all/secret_template.yml`**: Placeholder-based template for secrets.
- **`group_vars/all/secret.yml`**: The **encrypted** vault file (ignored by Git).

---

## Quick Start

1. **Clone this repo**:
   ```bash
   git clone https://github.com/yourusername/my-ansible-playbook.git
   cd my-ansible-playbook
   ```
2. **Install required dependencies**:
   - [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
   - If you’re on macOS and need password hashing, install [passlib](https://pypi.org/project/passlib/):
     ```bash
     pip install passlib
     ```
3. **Configure your inventory** in `inventory/production.yml`:
   ```yaml
   all:
     children:
       all_servers:
         hosts:
           myserver:
             ansible_host: 192.168.1.100
   ```
4. **Adjust any variables** in `group_vars/all/vars.yml`:
   ```yaml
   user_name: "aron"
   install_docker: true
   ```
5. **Set up your secrets** by running `./setup_vault.sh`.
6. **Run the playbook**:
   ```bash
   ansible-playbook run.yml --ask-vault-pass
   ```

---

## Group and Host Variables

- **`vars.yml`** (non-sensitive):
  - `user_name`: Name of the primary user (default: `aron`)
  - `install_docker`: Boolean to toggle Docker install.
  - `packages`: A list of basic packages to install (in the `common` role).

- **`secret_template.yml`** (template, public):
  - Contains placeholder variables like `PLACEHOLDER_USER_PASSWORD`.

- **`secret.yml`** (encrypted, ignored by Git):
  - Generated from the template and holds real secrets like `user_password`.
  - Must be decrypted at runtime with `--ask-vault-pass` or a vault password file.

---

## Securing Secrets with Vault

1. **Edit** `group_vars/all/secret_template.yml` if you want to add more placeholders.
2. **Run** `./setup_vault.sh`:
   - The script prompts you for values for each placeholder (ignoring commented lines).
   - Replaces placeholders in a newly copied `secret.yml`.
   - Encrypts `secret.yml` with Ansible Vault.
3. **Use** `--ask-vault-pass` or `--vault-password-file` to decrypt secrets at playbook runtime.

Ensure `.gitignore` includes:
```
group_vars/all/secret.yml
```
so the **encrypted** file is never committed to the repository in plaintext.

---

## Running the Playbook

A typical command looks like:

```bash
ansible-playbook run.yml -i inventory/production.yml --ask-vault-pass
```

- **`run.yml`** includes roles in this order: `common`, `user`, `security`, `docker`, `extras`.
- If you have Docker turned on (`install_docker: true`), it will install Docker. Otherwise, the role is skipped.

### Overriding Variables at Runtime

If you want to override a variable without editing files, use `--extra-vars`:

```bash
ansible-playbook run.yml 
  -i inventory/production.yml 
  --ask-vault-pass 
  --extra-vars "install_docker=false"
```

This would skip the Docker role on that run.

---

## FAQ / Common Issues

1. **“`crypt.crypt not supported on Mac OS X/Darwin`”**  
   - Install **passlib**: `pip install passlib`
   - Or skip password hashing by removing the password from your user configuration (e.g., if using SSH keys only).

2. **Permissions / sudo errors**  
   - Check you have `become: yes` in `run.yml`.
   - Confirm your Ansible SSH user can sudo.

3. **Vault password lost**  
   - If you lose your vault password, you cannot decrypt `secret.yml`.
   - You would have to regenerate it from the template (or from backups).

4. **Multi-Environment**  
   - If you manage multiple environments (e.g., staging, production), create separate inventory files and group var directories.

---

**Happy automating!**

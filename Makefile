# Makefile for Ansible Windows PowerShell Automation Framework
# Provides convenient commands for development, testing, and deployment

.PHONY: help install test lint security deploy clean docs
.DEFAULT_GOAL := help

# Variables
PYTHON := python3
PIP := pip3
ANSIBLE_PLAYBOOK := ansible-playbook
ANSIBLE_VAULT := ansible-vault
ENVIRONMENT ?= development
INVENTORY := inventory/$(ENVIRONMENT)/hosts.yml
VAULT_FILE := group_vars/all/vault.yml

help: ## Show this help message
	@echo "Ansible Windows PowerShell Automation Framework"
	@echo ""
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*##"; printf "%-20s %s\n", "Command", "Description"} /^[a-zA-Z_-]+:.*?##/ { printf "%-20s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install: ## Install dependencies and setup environment
	@echo "Installing dependencies..."
	$(PIP) install -r requirements.txt
	@echo "Dependencies installed successfully"

test: ## Run all tests
	@echo "Running test suite..."
	$(PYTHON) -m pytest tests/ -v
	@echo "Tests completed"

ping: ## Test connectivity to Windows hosts
	@echo "Testing connectivity to $(ENVIRONMENT) hosts..."
	@ansible -i $(INVENTORY) windows -m win_ping --ask-vault-pass

deploy-provision: ## Deploy server provisioning playbook
	@echo "Deploying server provisioning to $(ENVIRONMENT)..."
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/infrastructure/server-provision.yml --ask-vault-pass

deploy-security: ## Deploy security baseline playbook
	@echo "Deploying security baseline to $(ENVIRONMENT)..."
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/security/cis-baseline.yml --ask-vault-pass

status: ## Show current environment status
	@echo "=== Ansible Windows PowerShell Automation Status ==="
	@echo "Current Environment: $(ENVIRONMENT)"
	@echo "Inventory File: $(INVENTORY)"
	@echo "Vault File: $(VAULT_FILE)"

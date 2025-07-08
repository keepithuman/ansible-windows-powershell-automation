# IAG Quick Reference - Windows Ansible Automation

## 🚀 Quick Setup Commands

### Step 1: Create Repository
```bash
iag repository create \
  --name "ansible-windows-powershell-automation" \
  --description "Enterprise Ansible automation framework for Windows systems" \
  --url "https://github.com/keepithuman/ansible-windows-powershell-automation.git" \
  --reference "main"
```

### Step 2: Create Core Services

#### Windows Server Provisioning
```bash
iag service create \
  --service-type "ansible-playbook" \
  --name "windows-server-provisioning" \
  --repository "ansible-windows-powershell-automation" \
  --description "Comprehensive Windows server provisioning service" \
  --playbook "playbooks/infrastructure/server-provision.yml" \
  --inventory "inventory/development/hosts.yml" \
  --extra-vars "environment_name=development,provision_batch_size=5" \
  --tags "infrastructure,provisioning,windows"
```

#### Security Baseline
```bash
iag service create \
  --service-type "ansible-playbook" \
  --name "windows-security-baseline" \
  --repository "ansible-windows-powershell-automation" \
  --description "CIS security baseline implementation" \
  --playbook "playbooks/security/cis-baseline.yml" \
  --inventory "inventory/development/hosts.yml" \
  --extra-vars "compliance_framework=cis,security_level=high" \
  --tags "security,compliance,cis"
```

#### IIS Deployment
```bash
iag service create \
  --service-type "ansible-playbook" \
  --name "windows-iis-deployment" \
  --repository "ansible-windows-powershell-automation" \
  --description "IIS web server deployment and configuration" \
  --playbook "playbooks/applications/iis-deployment.yml" \
  --inventory "inventory/development/hosts.yml" \
  --limit "web_servers" \
  --extra-vars "security_level=high" \
  --tags "applications,iis,webserver"
```

#### Update Management
```bash
iag service create \
  --service-type "ansible-playbook" \
  --name "windows-update-management" \
  --repository "ansible-windows-powershell-automation" \
  --description "Windows update management with rollback" \
  --playbook "playbooks/maintenance/windows-updates.yml" \
  --inventory "inventory/development/hosts.yml" \
  --extra-vars "update_batch_size=25%,auto_reboot=true" \
  --tags "maintenance,updates,patching"
```

## 🔧 Service Management Commands

### List and Verify Services
```bash
# List all services
iag service list

# Show service details
iag service show windows-server-provisioning

# Validate service configuration
iag service validate windows-server-provisioning
```

### Execute Services
```bash
# Run server provisioning
iag job run \
  --service "windows-server-provisioning" \
  --parameters '{
    "inventory_file": "inventory/production/hosts.yml",
    "environment_name": "production",
    "target_hosts": "web_servers"
  }'

# Run with dry-run mode
iag job run \
  --service "windows-security-baseline" \
  --parameters '{
    "dry_run": true,
    "verbosity": 3
  }'
```

### Monitor Jobs
```bash
# List running jobs
iag job list --status running

# Get job details and logs
iag job show JOB_ID

# Follow real-time logs
iag job logs JOB_ID --follow
```

## 🔐 Security Configuration

### Configure Credentials
```bash
# Ansible vault password
iag credential create \
  --name "ansible-vault-password" \
  --type "password" \
  --description "Vault password for Windows automation" \
  --value "YOUR_VAULT_PASSWORD"

# Windows domain credentials
iag credential create \
  --name "windows-domain-admin" \
  --type "username-password" \
  --username "DOMAIN\\ansible-service" \
  --password "SECURE_PASSWORD"
```

## 📊 Environment-Specific Services

### Production Services
```bash
# Production provisioning with max security
iag service create \
  --service-type "ansible-playbook" \
  --name "windows-server-provisioning-prod" \
  --repository "ansible-windows-powershell-automation" \
  --playbook "playbooks/infrastructure/server-provision.yml" \
  --inventory "inventory/production/hosts.yml" \
  --extra-vars "environment_name=production,security_level=maximum"

# Production security baseline
iag service create \
  --service-type "ansible-playbook" \
  --name "windows-security-baseline-prod" \
  --repository "ansible-windows-powershell-automation" \
  --playbook "playbooks/security/cis-baseline.yml" \
  --inventory "inventory/production/hosts.yml" \
  --extra-vars "environment_name=production,compliance_framework=cis"
```

## 🔄 Workflow Creation

### Complete Deployment Workflow
```bash
iag workflow create \
  --name "windows-complete-deployment" \
  --description "Complete Windows deployment workflow" \
  --steps '[
    {
      "service": "windows-server-provisioning",
      "name": "Server Setup"
    },
    {
      "service": "windows-security-baseline", 
      "name": "Security Hardening"
    },
    {
      "service": "windows-update-management",
      "name": "Apply Updates"
    }
  ]'
```

## 📋 Common Service Parameters

### Required Parameters
- `inventory_file`: Target inventory (`inventory/production/hosts.yml`)
- `environment_name`: Environment (`development`, `staging`, `production`)
- `ansible_vault_password`: Vault password (use credential reference)

### Optional Parameters
- `target_hosts`: Specific hosts/groups to target
- `batch_size`: Processing batch size
- `dry_run`: Check mode (default: false)
- `verbosity`: Output verbosity (1-4)
- `extra_tags`: Additional tags to run
- `skip_tags`: Tags to skip

## 🎯 Quick Execution Examples

### Development Testing
```bash
# Test connectivity
iag job run --service "windows-server-provisioning" \
  --parameters '{"dry_run": true, "target_hosts": "test_server"}'

# Deploy to dev web servers
iag job run --service "windows-iis-deployment" \
  --parameters '{"inventory_file": "inventory/development/hosts.yml"}'
```

### Production Deployment
```bash
# Provision production servers
iag job run --service "windows-server-provisioning-prod" \
  --parameters '{"target_hosts": "new_servers", "batch_size": "3"}'

# Apply security to all production
iag job run --service "windows-security-baseline-prod" \
  --parameters '{"target_hosts": "all"}'
```

---

**📖 For detailed documentation, see the full README.md**
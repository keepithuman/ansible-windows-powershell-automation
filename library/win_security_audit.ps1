#!powershell
# Custom Ansible module for Windows security auditing
# Performs comprehensive security assessment and compliance checking

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        check_users = @{ type = "bool"; default = $true }
        check_services = @{ type = "bool"; default = $true }
        check_registry = @{ type = "bool"; default = $true }
        check_firewall = @{ type = "bool"; default = $true }
        check_updates = @{ type = "bool"; default = $true }
        check_shares = @{ type = "bool"; default = $true }
        compliance_framework = @{ type = "str"; default = "general"; choices = @("general", "cis", "stig", "pci") }
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$check_users = $module.Params.check_users
$check_services = $module.Params.check_services
$check_registry = $module.Params.check_registry
$check_firewall = $module.Params.check_firewall
$check_updates = $module.Params.check_updates
$check_shares = $module.Params.check_shares
$compliance_framework = $module.Params.compliance_framework

$result = @{
    security_findings = @()
    compliance_score = 0
    total_checks = 0
    passed_checks = 0
    failed_checks = 0
}

function Add-SecurityFinding {
    param(
        [string]$Category,
        [string]$Check,
        [string]$Status,
        [string]$Description,
        [string]$Severity = "Medium",
        [string]$Recommendation = ""
    )
    
    $result.security_findings += @{
        category = $Category
        check = $Check
        status = $Status
        description = $Description
        severity = $Severity
        recommendation = $Recommendation
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    $result.total_checks++
    if ($Status -eq "PASS") {
        $result.passed_checks++
    } else {
        $result.failed_checks++
    }
}

try {
    # User Account Security Checks
    if ($check_users) {
        # Check for built-in accounts status
        $adminAccount = Get-LocalUser -Name "Administrator" -ErrorAction SilentlyContinue
        if ($adminAccount -and $adminAccount.Enabled) {
            Add-SecurityFinding -Category "User Accounts" -Check "Built-in Administrator" -Status "FAIL" `
                -Description "Built-in Administrator account is enabled" `
                -Severity "High" -Recommendation "Disable built-in Administrator account"
        } else {
            Add-SecurityFinding -Category "User Accounts" -Check "Built-in Administrator" -Status "PASS" `
                -Description "Built-in Administrator account is disabled"
        }
        
        $guestAccount = Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
        if ($guestAccount -and $guestAccount.Enabled) {
            Add-SecurityFinding -Category "User Accounts" -Check "Guest Account" -Status "FAIL" `
                -Description "Guest account is enabled" `
                -Severity "Medium" -Recommendation "Disable Guest account"
        } else {
            Add-SecurityFinding -Category "User Accounts" -Check "Guest Account" -Status "PASS" `
                -Description "Guest account is disabled"
        }
    }
    
    # Service Security Checks
    if ($check_services) {
        # Check for unnecessary services
        $unnecessaryServices = @("Fax", "TelnetD", "RemoteRegistry", "SNMP")
        $foundUnnecessary = @()
        
        foreach ($serviceName in $unnecessaryServices) {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service -and $service.Status -eq "Running") {
                $foundUnnecessary += $serviceName
            }
        }
        
        if ($foundUnnecessary.Count -gt 0) {
            Add-SecurityFinding -Category "Services" -Check "Unnecessary Services" -Status "FAIL" `
                -Description "Found running unnecessary services: $($foundUnnecessary -join ', ')" `
                -Severity "Medium" -Recommendation "Stop and disable unnecessary services"
        } else {
            Add-SecurityFinding -Category "Services" -Check "Unnecessary Services" -Status "PASS" `
                -Description "No unnecessary services found running"
        }
    }
    
    # Registry Security Checks
    if ($check_registry) {
        # Check UAC settings
        $uacEnabled = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue
        if ($uacEnabled -and $uacEnabled.EnableLUA -eq 1) {
            Add-SecurityFinding -Category "Registry" -Check "UAC Enabled" -Status "PASS" `
                -Description "User Account Control is enabled"
        } else {
            Add-SecurityFinding -Category "Registry" -Check "UAC Enabled" -Status "FAIL" `
                -Description "User Account Control is disabled" `
                -Severity "High" -Recommendation "Enable User Account Control"
        }
        
        # Check for auto-logon
        $autoLogon = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -ErrorAction SilentlyContinue
        if ($autoLogon -and $autoLogon.AutoAdminLogon -eq "1") {
            Add-SecurityFinding -Category "Registry" -Check "Auto Logon" -Status "FAIL" `
                -Description "Automatic logon is enabled" `
                -Severity "High" -Recommendation "Disable automatic logon"
        } else {
            Add-SecurityFinding -Category "Registry" -Check "Auto Logon" -Status "PASS" `
                -Description "Automatic logon is disabled"
        }
    }
    
    # Firewall Security Checks
    if ($check_firewall) {
        try {
            $firewallStatus = Get-NetFirewallProfile | Where-Object { $_.Enabled -eq $false }
            if ($firewallStatus.Count -gt 0) {
                Add-SecurityFinding -Category "Firewall" -Check "Firewall Status" -Status "FAIL" `
                    -Description "Windows Firewall is disabled for some profiles" `
                    -Severity "High" -Recommendation "Enable Windows Firewall for all profiles"
            } else {
                Add-SecurityFinding -Category "Firewall" -Check "Firewall Status" -Status "PASS" `
                    -Description "Windows Firewall is enabled for all profiles"
            }
        }
        catch {
            Add-SecurityFinding -Category "Firewall" -Check "Firewall Status" -Status "FAIL" `
                -Description "Unable to check firewall status" `
                -Severity "Medium" -Recommendation "Manually verify firewall configuration"
        }
    }
    
    # Windows Update Security Checks
    if ($check_updates) {
        try {
            # Check Windows Update service
            $wuService = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
            if ($wuService -and $wuService.Status -eq "Running") {
                Add-SecurityFinding -Category "Updates" -Check "Update Service" -Status "PASS" `
                    -Description "Windows Update service is running"
            } else {
                Add-SecurityFinding -Category "Updates" -Check "Update Service" -Status "FAIL" `
                    -Description "Windows Update service is not running" `
                    -Severity "High" -Recommendation "Start and configure Windows Update service"
            }
        }
        catch {
            Add-SecurityFinding -Category "Updates" -Check "Update Assessment" -Status "FAIL" `
                -Description "Unable to check for updates: $($_.Exception.Message)" `
                -Severity "Medium" -Recommendation "Verify Windows Update configuration"
        }
    }
    
    # File Share Security Checks
    if ($check_shares) {
        try {
            $shares = Get-SmbShare | Where-Object { $_.Name -notin @("ADMIN$", "C$", "IPC$", "print$") }
            if ($shares.Count -eq 0) {
                Add-SecurityFinding -Category "File Shares" -Check "Share Security" -Status "PASS" `
                    -Description "No custom file shares found"
            } else {
                Add-SecurityFinding -Category "File Shares" -Check "Share Security" -Status "PASS" `
                    -Description "Found $($shares.Count) custom file shares - manual review recommended"
            }
        }
        catch {
            Add-SecurityFinding -Category "File Shares" -Check "Share Security" -Status "FAIL" `
                -Description "Unable to enumerate file shares" `
                -Severity "Low" -Recommendation "Manually verify share permissions"
        }
    }
    
    # Calculate compliance score
    if ($result.total_checks -gt 0) {
        $result.compliance_score = [math]::Round(($result.passed_checks / $result.total_checks) * 100, 2)
    }
    
    # Determine overall security posture
    $criticalFindings = ($result.security_findings | Where-Object { $_.severity -eq "High" -and $_.status -eq "FAIL" }).Count
    $mediumFindings = ($result.security_findings | Where-Object { $_.severity -eq "Medium" -and $_.status -eq "FAIL" }).Count
    
    if ($criticalFindings -eq 0 -and $mediumFindings -le 2) {
        $result.security_posture = "Good"
    } elseif ($criticalFindings -le 2 -and $mediumFindings -le 5) {
        $result.security_posture = "Fair"
    } else {
        $result.security_posture = "Poor"
    }
    
    $result.summary = @{
        total_findings = $result.security_findings.Count
        critical_issues = $criticalFindings
        medium_issues = $mediumFindings
        compliance_score = $result.compliance_score
        security_posture = $result.security_posture
        framework = $compliance_framework
        scan_date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    $module.Result.security_audit = $result
    $module.Result.changed = $false
    
} catch {
    $module.FailJson("Security audit failed: $($_.Exception.Message)")
}

$module.ExitJson()
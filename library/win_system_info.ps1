#!powershell
# Custom Ansible module for comprehensive Windows system information
# Returns detailed system metrics for monitoring and reporting

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        gather_performance = @{ type = "bool"; default = $true }
        gather_services = @{ type = "bool"; default = $true }
        gather_processes = @{ type = "bool"; default = $false }
        gather_network = @{ type = "bool"; default = $true }
        gather_storage = @{ type = "bool"; default = $true }
        gather_updates = @{ type = "bool"; default = $false }
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$gather_performance = $module.Params.gather_performance
$gather_services = $module.Params.gather_services
$gather_processes = $module.Params.gather_processes
$gather_network = $module.Params.gather_network
$gather_storage = $module.Params.gather_storage
$gather_updates = $module.Params.gather_updates

$result = @{}

try {
    # Basic system information
    $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
    $operatingSystem = Get-WmiObject -Class Win32_OperatingSystem
    $processor = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
    
    $result.system = @{
        name = $computerSystem.Name
        domain = $computerSystem.Domain
        workgroup = $computerSystem.Workgroup
        manufacturer = $computerSystem.Manufacturer
        model = $computerSystem.Model
        total_physical_memory_gb = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
        number_of_processors = $computerSystem.NumberOfProcessors
        number_of_logical_processors = $computerSystem.NumberOfLogicalProcessors
    }
    
    $result.operating_system = @{
        name = $operatingSystem.Name.Split('|')[0]
        version = $operatingSystem.Version
        build_number = $operatingSystem.BuildNumber
        service_pack = $operatingSystem.ServicePackMajorVersion
        architecture = $operatingSystem.OSArchitecture
        install_date = $operatingSystem.InstallDate
        last_boot_time = $operatingSystem.LastBootUpTime
        uptime_days = [math]::Round(((Get-Date) - $operatingSystem.ConvertToDateTime($operatingSystem.LastBootUpTime)).TotalDays, 2)
    }
    
    $result.processor = @{
        name = $processor.Name
        manufacturer = $processor.Manufacturer
        max_clock_speed = $processor.MaxClockSpeed
        number_of_cores = $processor.NumberOfCores
        number_of_logical_processors = $processor.NumberOfLogicalProcessors
    }
    
    # Performance information
    if ($gather_performance) {
        $memory = Get-WmiObject -Class Win32_OperatingSystem
        
        $result.performance = @{
            memory = @{
                total_gb = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
                available_gb = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
                used_gb = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 2)
                used_percentage = [math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 2)
            }
            page_file = @{
                total_gb = [math]::Round($memory.TotalVirtualMemorySize / 1MB, 2)
                available_gb = [math]::Round($memory.FreeVirtualMemory / 1MB, 2)
                used_percentage = [math]::Round((($memory.TotalVirtualMemorySize - $memory.FreeVirtualMemory) / $memory.TotalVirtualMemorySize) * 100, 2)
            }
        }
    }
    
    # Storage information
    if ($gather_storage) {
        $disks = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        $result.storage = @()
        
        foreach ($disk in $disks) {
            $result.storage += @{
                drive_letter = $disk.DeviceID
                label = $disk.VolumeName
                file_system = $disk.FileSystem
                total_gb = [math]::Round($disk.Size / 1GB, 2)
                free_gb = [math]::Round($disk.FreeSpace / 1GB, 2)
                used_gb = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
                used_percentage = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
            }
        }
    }
    
    # Network information
    if ($gather_network) {
        $adapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        $result.network = @()
        
        foreach ($adapter in $adapters) {
            $result.network += @{
                description = $adapter.Description
                ip_addresses = $adapter.IPAddress
                subnet_masks = $adapter.IPSubnet
                default_gateways = $adapter.DefaultIPGateway
                dns_servers = $adapter.DNSServerSearchOrder
                dhcp_enabled = $adapter.DHCPEnabled
                mac_address = $adapter.MACAddress
            }
        }
    }
    
    # Services information
    if ($gather_services) {
        $services = Get-Service
        $result.services = @{
            total = $services.Count
            running = ($services | Where-Object { $_.Status -eq "Running" }).Count
            stopped = ($services | Where-Object { $_.Status -eq "Stopped" }).Count
        }
        
        # Critical services status
        $criticalServices = @(
            "Spooler", "Schedule", "EventLog", "Themes", "W32Time", 
            "WinRM", "Dhcp", "Dnscache", "LanmanWorkstation", "LanmanServer"
        )
        
        $result.critical_services = @{}
        foreach ($serviceName in $criticalServices) {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service) {
                $result.critical_services[$serviceName] = @{
                    status = $service.Status.ToString()
                    start_type = (Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'").StartMode
                }
            }
        }
    }
    
    # Windows Updates information
    if ($gather_updates) {
        try {
            $updateSession = New-Object -ComObject 'Microsoft.Update.Session'
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
            
            $result.updates = @{
                available_count = $searchResult.Updates.Count
                last_search_date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
        catch {
            $result.updates = @{
                error = "Failed to retrieve update information: $($_.Exception.Message)"
            }
        }
    }
    
    # Windows Features information
    $features = Get-WindowsFeature | Where-Object { $_.InstallState -eq "Installed" }
    $result.windows_features = @{
        installed_count = $features.Count
        features = @($features | Select-Object Name, DisplayName | ForEach-Object { @{ name = $_.Name; display_name = $_.DisplayName } })
    }
    
    # Event log summary
    $eventLogs = @("Application", "System", "Security")
    $result.event_logs = @{}
    
    foreach ($logName in $eventLogs) {
        try {
            $log = Get-WinEvent -LogName $logName -MaxEvents 1 -ErrorAction SilentlyContinue
            if ($log) {
                $errors = (Get-WinEvent -FilterHashtable @{LogName=$logName; Level=1,2; StartTime=(Get-Date).AddDays(-1)} -ErrorAction SilentlyContinue).Count
                $warnings = (Get-WinEvent -FilterHashtable @{LogName=$logName; Level=3; StartTime=(Get-Date).AddDays(-1)} -ErrorAction SilentlyContinue).Count
                
                $result.event_logs[$logName] = @{
                    last_entry = $log.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                    errors_last_24h = $errors
                    warnings_last_24h = $warnings
                }
            }
        }
        catch {
            $result.event_logs[$logName] = @{
                error = "Failed to read log: $($_.Exception.Message)"
            }
        }
    }
    
    $module.Result.system_info = $result
    $module.Result.changed = $false
    
} catch {
    $module.FailJson("Failed to gather system information: $($_.Exception.Message)")
}

$module.ExitJson()
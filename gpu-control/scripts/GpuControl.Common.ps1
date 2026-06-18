Set-StrictMode -Version 2.0

$script:GpuControlRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$script:GpuPolicyPath = Join-Path $script:GpuControlRoot 'config\gpu-policy.json'
$script:GpuPolicyExamplePath = Join-Path $script:GpuControlRoot 'config\gpu-policy.example.json'
$script:RegistryPath = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'

function Get-GpuControlRoot {
    return $script:GpuControlRoot
}

function Get-GpuPolicy {
    $policyPath = $script:GpuPolicyPath
    if (-not (Test-Path -LiteralPath $policyPath)) {
        $policyPath = $script:GpuPolicyExamplePath
    }

    if (-not (Test-Path -LiteralPath $policyPath)) {
        throw "Policy file not found. Create config\gpu-policy.json from config\gpu-policy.example.json."
    }

    return Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json
}

function Resolve-GpuControlPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RelativePath
    )

    return Join-Path $script:GpuControlRoot $RelativePath
}

function Ensure-GpuControlDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Get-GpuControlLogPath {
    $policy = Get-GpuPolicy
    $logDir = Resolve-GpuControlPath $policy.paths.logDirectory
    Ensure-GpuControlDirectory $logDir
    return Join-Path $logDir 'gpu-control.log'
}

function Write-GpuControlLog {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath (Get-GpuControlLogPath) -Value $line -Encoding UTF8
}

function ConvertTo-GpuPreferenceValue {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Auto', 'PowerSaving', 'HighPerformance')]
        [string] $Preference
    )

    switch ($Preference) {
        'PowerSaving' { return 'GpuPreference=1;' }
        'HighPerformance' { return 'GpuPreference=2;' }
        default { return $null }
    }
}

function ConvertFrom-GpuPreferenceValue {
    param(
        [AllowNull()]
        [string] $Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return 'Auto'
    }

    if ($Value -match 'GpuPreference=2') {
        return 'HighPerformance'
    }

    if ($Value -match 'GpuPreference=1') {
        return 'PowerSaving'
    }

    return 'Unknown'
}

function Get-GpuVendorLabel {
    param(
        [AllowNull()]
        [string] $Name
    )

    if ($Name -match 'NVIDIA') {
        return 'NVIDIA GPU'
    }

    if ($Name -match 'Intel') {
        return 'Intel GPU'
    }

    if ($Name -match 'AMD|Radeon') {
        return 'AMD GPU'
    }

    return 'Other display adapter'
}

function Get-MonitorRoleLabel {
    param(
        [Parameter(Mandatory = $true)]
        [object] $Monitor,

        [Parameter(Mandatory = $true)]
        [object] $Policy
    )

    if ($Monitor.InstanceName -match $Policy.display.internalDisplayPattern) {
        return 'Internal'
    }

    foreach ($pattern in $Policy.display.externalDisplayPatterns) {
        if ($Monitor.InstanceName -match $pattern) {
            return 'External'
        }
    }

    return 'Unknown'
}

function ConvertTo-NormalizedMonitorInstanceId {
    param(
        [AllowNull()]
        [string] $InstanceId
    )

    if ([string]::IsNullOrWhiteSpace($InstanceId)) {
        return $null
    }

    return ($InstanceId -replace '_\d+$', '').ToUpperInvariant()
}

function ConvertTo-SanitizedUserGpuPreferenceSummary {
    $prefs = Get-UserGpuPreferences
    $rows = @()
    foreach ($key in ($prefs.Keys | Sort-Object)) {
        $rows += [pscustomobject]@{
            Preference = ConvertFrom-GpuPreferenceValue $prefs[$key]
        }
    }

    [pscustomobject]@{
        EntryCount = @($rows).Count
        ByPreference = @($rows | Group-Object Preference | Sort-Object Name | ForEach-Object {
            [pscustomobject]@{
                Preference = $_.Name
                Count = $_.Count
            }
        })
    }
}

function ConvertTo-SanitizedPolicyChangeSummary {
    param(
        [AllowNull()]
        [object[]] $Changes
    )

    $rows = @($Changes | ForEach-Object {
        [pscustomobject]@{
            Action = $_.Action
            Preference = $_.Preference
            Preview = [bool] $_.Preview
        }
    })

    [pscustomobject]@{
        ChangeCount = @($rows).Count
        ByActionPreference = @($rows | Group-Object Action, Preference | Sort-Object Name | ForEach-Object {
            $parts = $_.Name -split ', ', 2
            [pscustomobject]@{
                Action = $parts[0]
                Preference = if ($parts.Count -gt 1) { $parts[1] } else { $null }
                Count = $_.Count
            }
        })
    }
}

function ConvertTo-SanitizedProcessList {
    param(
        [AllowNull()]
        [object[]] $Processes
    )

    @($Processes | ForEach-Object {
        [pscustomobject]@{
            Id = $_.Id
            ProcessName = $_.ProcessName
            ProtectedOnEject = [bool] $_.ProtectedOnEject
            Source = $_.Source
        }
    })
}

function ConvertTo-SanitizedGpuPolicy {
    param(
        [Parameter(Mandatory = $true)]
        [object] $Policy
    )

    $apps = @($Policy.applications)
    [pscustomobject]@{
        schemaVersion = $Policy.schemaVersion
        profileName = 'Sanitized hybrid GPU policy'
        paths = [pscustomobject]@{
            backupDirectoryConfigured = -not [string]::IsNullOrWhiteSpace($Policy.paths.backupDirectory)
            logDirectoryConfigured = -not [string]::IsNullOrWhiteSpace($Policy.paths.logDirectory)
            reportDirectoryConfigured = -not [string]::IsNullOrWhiteSpace($Policy.paths.reportDirectory)
            supportBundleDirectoryConfigured = -not [string]::IsNullOrWhiteSpace($Policy.paths.supportBundleDirectory)
        }
        health = [pscustomobject]@{
            lookbackMinutes = $Policy.health.lookbackMinutes
            whea17DegradedThreshold = $Policy.health.whea17DegradedThreshold
            tdrDegradedThreshold = $Policy.health.tdrDegradedThreshold
            nvidiaNamePatternConfigured = -not [string]::IsNullOrWhiteSpace($Policy.health.nvidiaNamePattern)
            intelNamePatternConfigured = -not [string]::IsNullOrWhiteSpace($Policy.health.intelNamePattern)
        }
        display = [pscustomobject]@{
            hasInternalDisplayPattern = -not [string]::IsNullOrWhiteSpace($Policy.display.internalDisplayPattern)
            externalDisplayPatternCount = @($Policy.display.externalDisplayPatterns).Count
        }
        policy = $Policy.policy
        applicationCount = @($apps).Count
        applicationsByCategory = @($apps | Group-Object category | Sort-Object Name | ForEach-Object {
            [pscustomobject]@{
                Category = $_.Name
                Count = $_.Count
            }
        })
    }
}

function ConvertTo-SanitizedGpuControlState {
    param(
        [Parameter(Mandatory = $true)]
        [object] $State
    )

    $policy = Get-GpuPolicy
    [pscustomobject]@{
        Timestamp = $null
        TimestampRedacted = $true
        State = $State.State
        DisplayMode = $State.DisplayMode
        IsDegraded = $State.IsDegraded
        DegradedReasons = $State.DegradedReasons
        NvidiaOnline = $State.NvidiaOnline
        IntelOnline = $State.IntelOnline
        Controllers = @($State.Controllers | ForEach-Object {
            [pscustomobject]@{
                Adapter = Get-GpuVendorLabel $_.Name
                Status = $_.Status
                HasActiveResolution = ($null -ne $_.CurrentHorizontalResolution -or $null -ne $_.CurrentVerticalResolution)
            }
        })
        Monitors = @($State.Monitors | ForEach-Object {
            [pscustomobject]@{
                Role = Get-MonitorRoleLabel -Monitor $_ -Policy $policy
                Connected = $_.Connected
                HasDesktopArea = $_.HasDesktopArea
                Active = $_.Active
            }
        })
        ConnectedMonitorCount = $State.ConnectedMonitorCount
        DesktopActiveMonitorCount = $State.DesktopActiveMonitorCount
        ActiveMonitorCount = $State.ActiveMonitorCount
        InternalMonitorCount = $State.InternalMonitorCount
        ExternalMonitorCount = $State.ExternalMonitorCount
        Events = [pscustomobject]@{
            LookbackMinutes = $State.Events.LookbackMinutes
            Whea17Count = $State.Events.Whea17Count
            NvidiaWhea17Count = $State.Events.NvidiaWhea17Count
            IntelWhea17Count = $State.Events.IntelWhea17Count
            Tdr4101Count = $State.Events.Tdr4101Count
            LiveKernelRelatedCount = $State.Events.LiveKernelRelatedCount
        }
        Cuda = [pscustomobject]@{
            Available = $State.Cuda.Available
            Summary = if ($State.Cuda.Available) { 'nvidia-smi OK' } else { 'nvidia-smi unavailable or failed' }
        }
        UserGpuPreferences = ConvertTo-SanitizedUserGpuPreferenceSummary
    }
}

function Get-VideoControllers {
    Get-CimInstance Win32_VideoController |
        Select-Object Name, PNPDeviceID, DriverVersion, Status,
            CurrentHorizontalResolution, CurrentVerticalResolution,
            VideoModeDescription
}

function Get-DisplayMonitors {
    $monitors = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue
    $desktopMonitors = @{}
    foreach ($desktopMonitor in @(Get-CimInstance Win32_DesktopMonitor -ErrorAction SilentlyContinue)) {
        $key = ConvertTo-NormalizedMonitorInstanceId $desktopMonitor.PNPDeviceID
        if (-not [string]::IsNullOrWhiteSpace($key)) {
            $desktopMonitors[$key] = $desktopMonitor
        }
    }

    foreach ($monitor in $monitors) {
        $name = ($monitor.UserFriendlyName | Where-Object { $_ -ne 0 } | ForEach-Object { [char] $_ }) -join ''
        $serial = ($monitor.SerialNumberID | Where-Object { $_ -ne 0 } | ForEach-Object { [char] $_ }) -join ''
        $key = ConvertTo-NormalizedMonitorInstanceId $monitor.InstanceName
        $desktopMonitor = $null
        if (-not [string]::IsNullOrWhiteSpace($key) -and $desktopMonitors.ContainsKey($key)) {
            $desktopMonitor = $desktopMonitors[$key]
        }

        $hasDesktopArea = $false
        $screenWidth = $null
        $screenHeight = $null
        if ($desktopMonitor) {
            $screenWidth = $desktopMonitor.ScreenWidth
            $screenHeight = $desktopMonitor.ScreenHeight
            $hasDesktopArea = $null -ne $screenWidth -and $null -ne $screenHeight -and [int] $screenWidth -gt 0 -and [int] $screenHeight -gt 0
        }

        [pscustomobject]@{
            InstanceName = $monitor.InstanceName
            Name = $name
            Serial = $serial
            Connected = [bool] $monitor.Active
            HasDesktopArea = $hasDesktopArea
            ScreenWidth = $screenWidth
            ScreenHeight = $screenHeight
            Active = $hasDesktopArea
        }
    }
}

function Get-GpuEventSummary {
    param(
        [int] $LookbackMinutes = 30
    )

    $start = (Get-Date).AddMinutes(-1 * $LookbackMinutes)
    $wheaRows = @()
    $tdrRows = @()

    $wheaEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ProviderName = 'Microsoft-Windows-WHEA-Logger'
        Id = 17
        StartTime = $start
    } -ErrorAction SilentlyContinue

    foreach ($event in $wheaEvents) {
        $device = [regex]::Match($event.Message, 'PCI\\VEN_[0-9A-Fa-f&_;A-Za-z0-9\\]+').Value
        if ([string]::IsNullOrWhiteSpace($device)) {
            $device = '(not parsed)'
        }

        $wheaRows += [pscustomobject]@{
            Time = $event.TimeCreated
            Device = $device
            Message = $event.Message
        }
    }

    $tdrEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ProviderName = 'Display'
        Id = 4101
        StartTime = $start
    } -ErrorAction SilentlyContinue

    foreach ($event in $tdrEvents) {
        $tdrRows += [pscustomobject]@{
            Time = $event.TimeCreated
            Message = $event.Message
        }
    }

    $liveKernelEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        StartTime = $start
    } -ErrorAction SilentlyContinue | Where-Object {
        $_.ProviderName -like '*Kernel*' -and $_.Message -match 'LiveKernel|display|graphics|nvlddmkm|igdkmd'
    }

    [pscustomobject]@{
        LookbackMinutes = $LookbackMinutes
        Whea17Count = @($wheaRows).Count
        NvidiaWhea17Count = @($wheaRows | Where-Object { $_.Device -match 'VEN_10DE' }).Count
        IntelWhea17Count = @($wheaRows | Where-Object { $_.Device -match 'VEN_8086' }).Count
        Tdr4101Count = @($tdrRows).Count
        LiveKernelRelatedCount = @($liveKernelEvents).Count
        Whea17ByDevice = @($wheaRows | Group-Object Device | Sort-Object Count -Descending | ForEach-Object {
            [pscustomobject]@{
                Count = $_.Count
                Device = $_.Name
            }
        })
        TdrEvents = @($tdrRows)
    }
}

function Get-CudaStatus {
    $nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    if (-not $nvidiaSmi) {
        return [pscustomobject]@{
            Available = $false
            Command = $null
            Summary = 'nvidia-smi not found'
            Raw = @()
        }
    }

    try {
        $raw = & $nvidiaSmi.Source --query-gpu=name,driver_version,pci.bus_id,temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv,noheader 2>&1
        return [pscustomobject]@{
            Available = ($LASTEXITCODE -eq 0)
            Command = $nvidiaSmi.Source
            Summary = if ($LASTEXITCODE -eq 0) { 'nvidia-smi OK' } else { 'nvidia-smi returned non-zero exit code' }
            Raw = @($raw)
        }
    }
    catch {
        return [pscustomobject]@{
            Available = $false
            Command = $nvidiaSmi.Source
            Summary = $_.Exception.Message
            Raw = @()
        }
    }
}

function Get-UserGpuPreferences {
    if (-not (Test-Path -LiteralPath $script:RegistryPath)) {
        return @{}
    }

    $item = Get-ItemProperty -LiteralPath $script:RegistryPath
    $result = @{}
    foreach ($property in $item.PSObject.Properties) {
        if ($property.Name -like 'PS*') {
            continue
        }

        $result[$property.Name] = [string] $property.Value
    }

    return $result
}

function Export-UserGpuPreferenceSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $parent = Split-Path -Parent $Path
    Ensure-GpuControlDirectory $parent

    $prefs = Get-UserGpuPreferences
    $rows = @()
    foreach ($key in ($prefs.Keys | Sort-Object)) {
        $rows += [pscustomobject]@{
            Path = $key
            Value = $prefs[$key]
            Preference = ConvertFrom-GpuPreferenceValue $prefs[$key]
        }
    }

    $snapshot = [pscustomobject]@{
        CreatedAt = (Get-Date).ToString('o')
        RegistryPath = $script:RegistryPath
        Entries = $rows
    }

    $snapshot | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-InitialBackupPath {
    $policy = Get-GpuPolicy
    $backupDir = Resolve-GpuControlPath $policy.paths.backupDirectory
    Ensure-GpuControlDirectory $backupDir
    return Join-Path $backupDir 'initial-user-gpu-preferences.json'
}

function Ensure-InitialGpuPreferenceBackup {
    $path = Get-InitialBackupPath
    if (-not (Test-Path -LiteralPath $path)) {
        Export-UserGpuPreferenceSnapshot -Path $path
        Write-GpuControlLog "Created initial UserGpuPreferences backup: $path"
    }

    return $path
}

function Restore-UserGpuPreferenceSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [switch] $Preview
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Backup not found: $Path"
    }

    $snapshot = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json

    if ($Preview) {
        return [pscustomobject]@{
            Action = 'Restore'
            Preview = $true
            Backup = $Path
            EntryCount = @($snapshot.Entries).Count
        }
    }

    if (-not (Test-Path -LiteralPath $script:RegistryPath)) {
        New-Item -Path $script:RegistryPath -Force | Out-Null
    }

    $current = Get-UserGpuPreferences
    foreach ($key in $current.Keys) {
        Remove-ItemProperty -LiteralPath $script:RegistryPath -Name $key -ErrorAction SilentlyContinue
    }

    foreach ($entry in $snapshot.Entries) {
        if (-not [string]::IsNullOrWhiteSpace($entry.Value)) {
            New-ItemProperty -LiteralPath $script:RegistryPath -Name $entry.Path -Value $entry.Value -PropertyType String -Force | Out-Null
        }
    }

    Write-GpuControlLog "Restored UserGpuPreferences from backup: $Path"
    return [pscustomobject]@{
        Action = 'Restore'
        Preview = $false
        Backup = $Path
        EntryCount = @($snapshot.Entries).Count
    }
}

function Get-GpuControlState {
    $policy = Get-GpuPolicy
    $controllers = @(Get-VideoControllers)
    $monitors = @(Get-DisplayMonitors)
    $events = Get-GpuEventSummary -LookbackMinutes ([int] $policy.health.lookbackMinutes)
    $cuda = Get-CudaStatus

    $nvidiaControllers = @($controllers | Where-Object { $_.Name -match $policy.health.nvidiaNamePattern -and $_.Status -eq 'OK' })
    $intelControllers = @($controllers | Where-Object { $_.Name -match $policy.health.intelNamePattern -and $_.Status -eq 'OK' })
    $activeMonitors = @($monitors | Where-Object { $_.Active })
    $connectedMonitors = @($monitors | Where-Object { $_.Connected })
    $internalMonitors = @($activeMonitors | Where-Object { $_.InstanceName -match $policy.display.internalDisplayPattern })
    $externalMonitors = @()
    foreach ($monitor in $activeMonitors) {
        foreach ($pattern in $policy.display.externalDisplayPatterns) {
            if ($monitor.InstanceName -match $pattern) {
                $externalMonitors += $monitor
                break
            }
        }
    }

    $displayModeName = 'InternalOnly'
    if (@($externalMonitors).Count -gt 0 -and @($internalMonitors).Count -gt 0) {
        $displayModeName = 'Extended'
    }
    elseif (@($externalMonitors).Count -gt 0 -and @($internalMonitors).Count -eq 0) {
        $displayModeName = 'ExternalOnly'
    }
    elseif (@($internalMonitors).Count -gt 0) {
        $displayModeName = 'InternalOnly'
    }
    elseif (@($activeMonitors).Count -gt 0) {
        $displayModeName = 'UnknownActiveDisplay'
    }
    else {
        $displayModeName = 'NoDesktopDisplay'
    }

    $nvidiaOnline = @($nvidiaControllers).Count -gt 0
    $isDegraded = $false
    $degradedReasons = @()

    if ($nvidiaOnline -and $events.NvidiaWhea17Count -ge [int] $policy.health.whea17DegradedThreshold) {
        $isDegraded = $true
        $degradedReasons += "NVIDIA WHEA 17 count $($events.NvidiaWhea17Count) >= threshold $($policy.health.whea17DegradedThreshold) in $($events.LookbackMinutes) minutes"
    }

    if ($nvidiaOnline -and $events.Tdr4101Count -ge [int] $policy.health.tdrDegradedThreshold) {
        $isDegraded = $true
        $degradedReasons += "Display TDR 4101 count $($events.Tdr4101Count) >= threshold $($policy.health.tdrDegradedThreshold) in $($events.LookbackMinutes) minutes"
    }

    $stateName = 'Detached'
    if ($nvidiaOnline) {
        if ($isDegraded) {
            $stateName = 'Attached-Degraded'
        }
        elseif ($displayModeName -eq 'Extended') {
            $stateName = 'Attached-Extended'
        }
        elseif ($displayModeName -eq 'ExternalOnly') {
            $stateName = 'Attached-ExternalOnly'
        }
        else {
            $stateName = 'Attached-InternalOnly'
        }
    }

    [pscustomobject]@{
        Timestamp = (Get-Date).ToString('o')
        State = $stateName
        DisplayMode = $displayModeName
        IsDegraded = $isDegraded
        DegradedReasons = $degradedReasons
        NvidiaOnline = $nvidiaOnline
        IntelOnline = @($intelControllers).Count -gt 0
        Controllers = $controllers
        Monitors = $monitors
        ConnectedMonitorCount = @($connectedMonitors).Count
        DesktopActiveMonitorCount = @($activeMonitors).Count
        ActiveMonitorCount = @($activeMonitors).Count
        InternalMonitorCount = @($internalMonitors).Count
        ExternalMonitorCount = @($externalMonitors).Count
        Events = $events
        Cuda = $cuda
        UserGpuPreferences = Get-UserGpuPreferences
    }
}

function Get-PolicyPreferenceForApp {
    param(
        [Parameter(Mandatory = $true)]
        [object] $Application,

        [Parameter(Mandatory = $true)]
        [string] $State
    )

    if ($Application.category -eq 'AlwaysIntel') {
        return 'PowerSaving'
    }

    if ($Application.category -eq 'Auto') {
        return 'Auto'
    }

    if ($Application.category -eq 'PreferNvidiaWhenHealthy') {
        if ($State -in @('Attached-InternalOnly', 'Attached-Extended', 'Attached-ExternalOnly')) {
            return 'HighPerformance'
        }

        return 'Auto'
    }

    return 'Auto'
}

function Set-UserGpuPreference {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ApplicationPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Auto', 'PowerSaving', 'HighPerformance')]
        [string] $Preference,

        [switch] $Preview
    )

    $value = ConvertTo-GpuPreferenceValue $Preference
    if ($Preview) {
        return [pscustomobject]@{
            Path = $ApplicationPath
            Preference = $Preference
            RegistryValue = $value
            Action = if ($Preference -eq 'Auto') { 'RemovePreference' } else { 'SetPreference' }
            Preview = $true
        }
    }

    if (-not (Test-Path -LiteralPath $script:RegistryPath)) {
        New-Item -Path $script:RegistryPath -Force | Out-Null
    }

    if ($Preference -eq 'Auto') {
        Remove-ItemProperty -LiteralPath $script:RegistryPath -Name $ApplicationPath -ErrorAction SilentlyContinue
    }
    else {
        New-ItemProperty -LiteralPath $script:RegistryPath -Name $ApplicationPath -Value $value -PropertyType String -Force | Out-Null
    }

    return [pscustomobject]@{
        Path = $ApplicationPath
        Preference = $Preference
        RegistryValue = $value
        Action = if ($Preference -eq 'Auto') { 'RemovePreference' } else { 'SetPreference' }
        Preview = $false
    }
}

function Get-NvidiaComputeProcesses {
    $nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    if (-not $nvidiaSmi) {
        return @()
    }

    $raw = & $nvidiaSmi.Source --query-compute-apps=pid,process_name,used_memory --format=csv,noheader,nounits 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $raw) {
        return @()
    }

    foreach ($line in $raw) {
        $parts = $line -split ',', 3
        if ($parts.Count -lt 2) {
            continue
        }

        $processId = 0
        [void] [int]::TryParse($parts[0].Trim(), [ref] $processId)
        [pscustomobject]@{
            Source = 'nvidia-smi compute'
            Id = $processId
            ProcessName = Split-Path -Leaf $parts[1].Trim()
            Path = $parts[1].Trim()
            UsedMemoryMiB = if ($parts.Count -ge 3) { $parts[2].Trim() } else { $null }
        }
    }
}

function Get-NvidiaLikelyProcesses {
    $policy = Get-GpuPolicy
    $state = Get-GpuControlState
    $configuredPaths = @{}
    foreach ($app in $policy.applications) {
        $desired = Get-PolicyPreferenceForApp -Application $app -State $state.State
        if ($desired -eq 'HighPerformance') {
            $configuredPaths[$app.path.ToLowerInvariant()] = $app
        }
    }

    $results = @()
    foreach ($process in Get-Process -ErrorAction SilentlyContinue) {
        $path = $null
        try {
            $path = $process.Path
        }
        catch {
            $path = $null
        }

        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        $key = $path.ToLowerInvariant()
        if ($configuredPaths.ContainsKey($key)) {
            $app = $configuredPaths[$key]
            $results += [pscustomobject]@{
                Source = 'configured high-performance app'
                Id = $process.Id
                ProcessName = $process.ProcessName
                Path = $path
                ProtectedOnEject = [bool] $app.protectedOnEject
                AppName = $app.name
            }
        }
    }

    $compute = @(Get-NvidiaComputeProcesses)
    foreach ($item in $compute) {
        $already = @($results | Where-Object { $_.Id -eq $item.Id }).Count -gt 0
        if (-not $already) {
            $results += [pscustomobject]@{
                Source = $item.Source
                Id = $item.Id
                ProcessName = $item.ProcessName
                Path = $item.Path
                ProtectedOnEject = $true
                AppName = $item.ProcessName
            }
        }
    }

    return $results | Sort-Object Id -Unique
}

function New-GpuControlShortcut {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [string] $ScriptPath,

        [string] $Arguments = ''
    )

    $desktop = [Environment]::GetFolderPath('Desktop')
    $shortcutPath = Join-Path $desktop "$Name.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" $Arguments"
    $shortcut.WorkingDirectory = $script:GpuControlRoot
    $shortcut.Save()
    return $shortcutPath
}

function Get-GpuControlTaskName {
    return 'GpuControl Apply Policy At Logon'
}

function Get-GpuControlDeviceTaskName {
    return 'GpuControl Apply Policy On Device Change'
}

function Get-GpuControlTaskPath {
    return '\GpuControl\'
}

function Register-GpuControlLogonTask {
    param(
        [switch] $Preview
    )

    $taskName = Get-GpuControlTaskName
    $taskPath = Get-GpuControlTaskPath
    $applyScript = Join-Path $script:GpuControlRoot 'scripts\Apply-GpuPolicy.ps1'
    $powershell = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$applyScript`""

    if ($Preview) {
        return [pscustomobject]@{
            Action = 'RegisterLogonTask'
            TaskName = $taskName
            TaskPath = $taskPath
            Preview = $true
        }
    }

    $action = New-ScheduledTaskAction -Execute $powershell -Argument $arguments
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

    Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $action -Trigger $trigger -Settings $settings -Description 'Apply lightweight hybrid GPU policy at user logon.' -Force | Out-Null

    return [pscustomobject]@{
        Action = 'RegisterLogonTask'
        TaskName = $taskName
        TaskPath = $taskPath
        Preview = $false
    }
}

function Register-GpuControlDeviceEventTask {
    param(
        [switch] $Preview
    )

    $taskName = Get-GpuControlDeviceTaskName
    $taskPath = Get-GpuControlTaskPath
    $fullTaskName = "$taskPath$taskName"
    $applyScript = Join-Path $script:GpuControlRoot 'scripts\Apply-GpuPolicy.ps1'
    $powershell = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    $taskRun = "`"$powershell`" -NoProfile -ExecutionPolicy Bypass -File `"$applyScript`""
    $eventQuery = "*[System[Provider[@Name='Microsoft-Windows-Kernel-PnP'] and (EventID=400 or EventID=410 or EventID=411 or EventID=420 or EventID=430)]]"

    if ($Preview) {
        return [pscustomobject]@{
            Action = 'RegisterDeviceEventTask'
            TaskName = $taskName
            TaskPath = $taskPath
            Preview = $true
        }
    }

    $args = @(
        '/Create',
        '/TN', $fullTaskName,
        '/TR', $taskRun,
        '/SC', 'ONEVENT',
        '/EC', 'System',
        '/MO', $eventQuery,
        '/F'
    )

    $output = & schtasks.exe @args 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to register device event task: $output"
    }

    return [pscustomobject]@{
        Action = 'RegisterDeviceEventTask'
        TaskName = $taskName
        TaskPath = $taskPath
        Preview = $false
    }
}

function Unregister-GpuControlLogonTask {
    param(
        [switch] $Preview
    )

    $taskName = Get-GpuControlTaskName
    $taskPath = Get-GpuControlTaskPath
    $task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
    if (-not $task) {
        return [pscustomobject]@{
            Action = 'UnregisterLogonTask'
            TaskName = $taskName
            TaskPath = $taskPath
            Preview = [bool] $Preview
            Status = 'NotFound'
        }
    }

    if ($Preview) {
        return [pscustomobject]@{
            Action = 'UnregisterLogonTask'
            TaskName = $taskName
            TaskPath = $taskPath
            Preview = $true
            Status = 'WouldRemove'
        }
    }

    Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false
    return [pscustomobject]@{
        Action = 'UnregisterLogonTask'
        TaskName = $taskName
        TaskPath = $taskPath
        Preview = $false
        Status = 'Removed'
    }
}

function Unregister-GpuControlDeviceEventTask {
    param(
        [switch] $Preview
    )

    $taskName = Get-GpuControlDeviceTaskName
    $taskPath = Get-GpuControlTaskPath
    $task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
    if (-not $task) {
        return [pscustomobject]@{
            Action = 'UnregisterDeviceEventTask'
            TaskName = $taskName
            TaskPath = $taskPath
            Preview = [bool] $Preview
            Status = 'NotFound'
        }
    }

    if ($Preview) {
        return [pscustomobject]@{
            Action = 'UnregisterDeviceEventTask'
            TaskName = $taskName
            TaskPath = $taskPath
            Preview = $true
            Status = 'WouldRemove'
        }
    }

    Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false
    return [pscustomobject]@{
        Action = 'UnregisterDeviceEventTask'
        TaskName = $taskName
        TaskPath = $taskPath
        Preview = $false
        Status = 'Removed'
    }
}

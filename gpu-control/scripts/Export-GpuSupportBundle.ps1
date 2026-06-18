[CmdletBinding()]
param(
    [string] $OutputDirectory,
    [switch] $NoZip,
    [switch] $IncludePrivateDetails
)

. "$PSScriptRoot\GpuControl.Common.ps1"

$policy = Get-GpuPolicy
if (-not $OutputDirectory) {
    $bundleRoot = Resolve-GpuControlPath $policy.paths.supportBundleDirectory
    Ensure-GpuControlDirectory $bundleRoot
    $OutputDirectory = Join-Path $bundleRoot ('gpu-support-{0}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
}

Ensure-GpuControlDirectory $OutputDirectory

$state = Get-GpuControlState
$exportState = if ($IncludePrivateDetails) { $state } else { ConvertTo-SanitizedGpuControlState -State $state }
$exportState | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'gpu-state.json') -Encoding UTF8

if ($IncludePrivateDetails) {
    $policy | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'gpu-policy.json') -Encoding UTF8
    Export-UserGpuPreferenceSnapshot -Path (Join-Path $OutputDirectory 'user-gpu-preferences-current.json')
}
else {
    ConvertTo-SanitizedGpuPolicy -Policy $policy |
        ConvertTo-Json -Depth 10 |
        Set-Content -LiteralPath (Join-Path $OutputDirectory 'gpu-policy.sanitized.json') -Encoding UTF8
    ConvertTo-SanitizedUserGpuPreferenceSummary |
        ConvertTo-Json -Depth 6 |
        Set-Content -LiteralPath (Join-Path $OutputDirectory 'user-gpu-preferences-summary.json') -Encoding UTF8
}

$summaryPath = Join-Path $OutputDirectory 'summary.txt'
@(
    "GPU support bundle"
    "Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "State: $($state.State)"
    "Display mode: $($state.DisplayMode)"
    "NVIDIA online: $($state.NvidiaOnline)"
    "Intel online: $($state.IntelOnline)"
    "Connected monitors: $($state.ConnectedMonitorCount)"
    "Desktop-active monitors: $($state.DesktopActiveMonitorCount) (internal: $($state.InternalMonitorCount), external: $($state.ExternalMonitorCount))"
    "NVIDIA WHEA 17 in lookback: $($state.Events.NvidiaWhea17Count)"
    "Intel WHEA 17 in lookback: $($state.Events.IntelWhea17Count)"
    "Display TDR 4101 in lookback: $($state.Events.Tdr4101Count)"
    "CUDA summary: $($state.Cuda.Summary)"
    "Private details included: $([bool] $IncludePrivateDetails)"
    ""
    "Degraded reasons:"
) | Set-Content -LiteralPath $summaryPath -Encoding UTF8

if (@($state.DegradedReasons).Count -gt 0) {
    $state.DegradedReasons | Add-Content -LiteralPath $summaryPath -Encoding UTF8
}
else {
    "None" | Add-Content -LiteralPath $summaryPath -Encoding UTF8
}

if ($IncludePrivateDetails) {
    Get-CimInstance Win32_OperatingSystem |
        Select-Object Caption, Version, BuildNumber, OSArchitecture, LastBootUpTime |
        ConvertTo-Json -Depth 4 |
        Set-Content -LiteralPath (Join-Path $OutputDirectory 'os.json') -Encoding UTF8

    Get-CimInstance Win32_ComputerSystem |
        Select-Object Manufacturer, Model, SystemType, TotalPhysicalMemory |
        ConvertTo-Json -Depth 4 |
        Set-Content -LiteralPath (Join-Path $OutputDirectory 'computer-system.json') -Encoding UTF8

    Get-CimInstance Win32_BIOS |
        Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate |
        ConvertTo-Json -Depth 4 |
        Set-Content -LiteralPath (Join-Path $OutputDirectory 'bios.json') -Encoding UTF8

    powercfg /query SCHEME_CURRENT SUB_PCIEXPRESS ASPM > (Join-Path $OutputDirectory 'powercfg-pcie-aspm.txt') 2>&1

    if (Test-Path -LiteralPath (Get-GpuControlLogPath)) {
        Copy-Item -LiteralPath (Get-GpuControlLogPath) -Destination (Join-Path $OutputDirectory 'gpu-control.log') -Force
    }
}

$zipPath = $null
if (-not $NoZip) {
    $zipPath = "$OutputDirectory.zip"
    if (Test-Path -LiteralPath $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }
    Compress-Archive -Path (Join-Path $OutputDirectory '*') -DestinationPath $zipPath -Force
    if (-not (Test-Path -LiteralPath $zipPath)) {
        throw "Failed to create support bundle zip: $zipPath"
    }
}

Write-GpuControlLog "Exported support bundle: $OutputDirectory"

[pscustomobject]@{
    OutputDirectory = $OutputDirectory
    ZipPath = $zipPath
    State = $state.State
    IsDegraded = $state.IsDegraded
} | Format-List

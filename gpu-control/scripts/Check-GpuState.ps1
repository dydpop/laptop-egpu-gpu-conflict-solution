[CmdletBinding()]
param(
    [string] $OutputPath,
    [switch] $Json,
    [switch] $IncludePrivateDetails
)

. "$PSScriptRoot\GpuControl.Common.ps1"

$state = Get-GpuControlState
$outputState = if ($IncludePrivateDetails) { $state } else { ConvertTo-SanitizedGpuControlState -State $state }

if ($OutputPath) {
    $parent = Split-Path -Parent $OutputPath
    if ($parent) {
        Ensure-GpuControlDirectory $parent
    }
    $outputState | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
}

if ($Json) {
    $outputState | ConvertTo-Json -Depth 8
    return
}

Write-Host "GPU state: $($state.State)"
Write-Host "NVIDIA online: $($state.NvidiaOnline)"
Write-Host "Intel online: $($state.IntelOnline)"
Write-Host "Active monitors: $($state.ActiveMonitorCount) (internal: $($state.InternalMonitorCount), external: $($state.ExternalMonitorCount))"
if ($state.IsDegraded) {
    Write-Host "Health: DEGRADED" -ForegroundColor Yellow
    foreach ($reason in $state.DegradedReasons) {
        Write-Host " - $reason" -ForegroundColor Yellow
    }
}
else {
    Write-Host "Health: OK"
}

Write-Host ""
Write-Host "Display adapters:"
if ($IncludePrivateDetails) {
    $state.Controllers | Format-Table Name, Status, DriverVersion, CurrentHorizontalResolution, CurrentVerticalResolution -AutoSize
}
else {
    $outputState.Controllers | Format-Table Adapter, Status, HasActiveResolution -AutoSize
}

Write-Host ""
Write-Host "Active monitors:"
if ($IncludePrivateDetails) {
    $state.Monitors | Where-Object { $_.Active } | Format-Table InstanceName, Name, Serial -AutoSize
}
else {
    $outputState.Monitors | Where-Object { $_.Active } | Format-Table Role, Active -AutoSize
}

Write-Host ""
Write-Host "Recent events ($($state.Events.LookbackMinutes) minutes):"
Write-Host " - NVIDIA WHEA 17: $($state.Events.NvidiaWhea17Count)"
Write-Host " - Intel WHEA 17: $($state.Events.IntelWhea17Count)"
Write-Host " - Display TDR 4101: $($state.Events.Tdr4101Count)"

if ($IncludePrivateDetails -and @($state.Events.Whea17ByDevice).Count -gt 0) {
    $state.Events.Whea17ByDevice | Format-Table Count, Device -AutoSize
}

Write-Host ""
Write-Host "CUDA / nvidia-smi:"
Write-Host " - $($state.Cuda.Summary)"
foreach ($line in @($state.Cuda.Raw)) {
    if (-not $IncludePrivateDetails) {
        continue
    }
    Write-Host " - $line"
}

if (-not $IncludePrivateDetails) {
    Write-Host ""
    Write-Host "Private details are hidden by default. Use -IncludePrivateDetails only for local troubleshooting or redacted vendor reports."
}

if ($OutputPath) {
    Write-Host ""
    Write-Host "JSON report written to: $OutputPath"
}

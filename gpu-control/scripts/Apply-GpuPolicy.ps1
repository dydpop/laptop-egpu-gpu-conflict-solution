[CmdletBinding()]
param(
    [switch] $WhatIf,
    [switch] $Json,
    [switch] $IncludePrivateDetails
)

. "$PSScriptRoot\GpuControl.Common.ps1"

$policy = Get-GpuPolicy
$state = Get-GpuControlState
$changes = @()

if (-not $WhatIf) {
    Ensure-InitialGpuPreferenceBackup | Out-Null
}

foreach ($app in $policy.applications) {
    $desired = Get-PolicyPreferenceForApp -Application $app -State $state.State

    if ($desired -eq 'Auto' -and -not [bool] $policy.policy.setAutoEntries) {
        $changes += Set-UserGpuPreference -ApplicationPath $app.path -Preference Auto -Preview:$WhatIf
        continue
    }

    $changes += Set-UserGpuPreference -ApplicationPath $app.path -Preference $desired -Preview:$WhatIf
}

$result = [pscustomobject]@{
    Timestamp = (Get-Date).ToString('o')
    State = $state.State
    DisplayMode = $state.DisplayMode
    IsDegraded = $state.IsDegraded
    DegradedReasons = $state.DegradedReasons
    Preview = [bool] $WhatIf
    ChangeCount = @($changes).Count
    Changes = if ($IncludePrivateDetails) { $changes } else { $null }
    ChangeSummary = if ($IncludePrivateDetails) { $null } else { ConvertTo-SanitizedPolicyChangeSummary -Changes $changes }
}

if (-not $WhatIf) {
    Write-GpuControlLog "Applied GPU policy for state $($state.State), display mode $($state.DisplayMode); changes=$(@($changes).Count)"
}

if ($Json) {
    $result | ConvertTo-Json -Depth 8
    return
}

Write-Host "Detected state: $($state.State)"
Write-Host "Display mode: $($state.DisplayMode)"
if ($state.IsDegraded) {
    Write-Host "State is degraded; high-performance entries are removed or left Auto by policy." -ForegroundColor Yellow
    foreach ($reason in $state.DegradedReasons) {
        Write-Host " - $reason" -ForegroundColor Yellow
    }
}

if ($WhatIf) {
    Write-Host "Preview only. No registry changes were made." -ForegroundColor Cyan
}
else {
    Write-Host "Policy applied. Initial backup: $(Get-InitialBackupPath)"
}

if ($IncludePrivateDetails) {
    $changes | Format-Table Action, Preference, Path -AutoSize
}
else {
    ConvertTo-SanitizedPolicyChangeSummary -Changes $changes |
        Select-Object ChangeCount |
        Format-Table -AutoSize
    Write-Host ""
    (ConvertTo-SanitizedPolicyChangeSummary -Changes $changes).ByActionPreference | Format-Table -AutoSize
    Write-Host "Application paths are hidden by default. Use -IncludePrivateDetails only for local troubleshooting."
}

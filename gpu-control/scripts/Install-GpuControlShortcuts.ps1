[CmdletBinding()]
param()

. "$PSScriptRoot\GpuControl.Common.ps1"

$scripts = @{
    'GPU State' = Join-Path $PSScriptRoot 'Check-GpuState.ps1'
    'Apply GPU Policy' = Join-Path $PSScriptRoot 'Apply-GpuPolicy.ps1'
    'Prepare eGPU Eject' = Join-Path $PSScriptRoot 'Prepare-EgpuEject.ps1'
    'Export GPU Support Bundle' = Join-Path $PSScriptRoot 'Export-GpuSupportBundle.ps1'
    'Rollback GPU Policy' = Join-Path $PSScriptRoot 'Rollback-GpuPolicy.ps1'
}

$created = @()
foreach ($entry in $scripts.GetEnumerator()) {
    $args = if ($entry.Key -eq 'Prepare eGPU Eject') { '-OpenDeviceEject' } else { '' }
    $created += New-GpuControlShortcut -Name $entry.Key -ScriptPath $entry.Value -Arguments $args
}

Write-GpuControlLog "Installed desktop shortcuts: $($created -join '; ')"
$created | ForEach-Object { Write-Host "Created shortcut: $_" }

Write-Host ""
Write-Host "Tip: desktop shortcuts are optional. Install-GpuControl.ps1 does not create them unless -CreateDesktopShortcuts is used."

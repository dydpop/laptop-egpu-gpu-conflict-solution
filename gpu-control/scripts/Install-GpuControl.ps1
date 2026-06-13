[CmdletBinding()]
param(
    [switch] $WhatIf,
    [switch] $CreateDesktopShortcuts,
    [switch] $SkipLogonTask,
    [switch] $SkipDeviceEventTask
)

. "$PSScriptRoot\GpuControl.Common.ps1"

$created = @()

if ($CreateDesktopShortcuts) {
    $scripts = @{
        'GPU State' = Join-Path $PSScriptRoot 'Check-GpuState.ps1'
        'Apply GPU Policy' = Join-Path $PSScriptRoot 'Apply-GpuPolicy.ps1'
        'Prepare eGPU Eject' = Join-Path $PSScriptRoot 'Prepare-EgpuEject.ps1'
        'Export GPU Support Bundle' = Join-Path $PSScriptRoot 'Export-GpuSupportBundle.ps1'
        'Rollback GPU Policy' = Join-Path $PSScriptRoot 'Rollback-GpuPolicy.ps1'
    }

    foreach ($entry in $scripts.GetEnumerator()) {
        $arguments = if ($entry.Key -eq 'Prepare eGPU Eject') { '-OpenDeviceEject' } else { '' }
        if ($WhatIf) {
            $created += [pscustomobject]@{
                Action = 'CreateShortcut'
                Name = $entry.Key
                Script = $entry.Value
                Preview = $true
            }
        }
        else {
            $shortcut = New-GpuControlShortcut -Name $entry.Key -ScriptPath $entry.Value -Arguments $arguments
            $created += [pscustomobject]@{
                Action = 'CreateShortcut'
                Name = $entry.Key
                Path = $shortcut
                Preview = $false
            }
        }
    }
}

if (-not $SkipLogonTask) {
    try {
        $created += Register-GpuControlLogonTask -Preview:$WhatIf
    }
    catch {
        $created += [pscustomobject]@{
            Action = 'RegisterLogonTask'
            Preview = [bool] $WhatIf
            Status = 'Failed'
            Message = $_.Exception.Message
        }
    }
}

if (-not $SkipDeviceEventTask) {
    try {
        $created += Register-GpuControlDeviceEventTask -Preview:$WhatIf
    }
    catch {
        $created += [pscustomobject]@{
            Action = 'RegisterDeviceEventTask'
            Preview = [bool] $WhatIf
            Status = 'Failed'
            Message = $_.Exception.Message
        }
    }
}

if (-not $WhatIf) {
    $shortcutState = if ($CreateDesktopShortcuts) { 'with desktop shortcuts' } else { 'without desktop shortcuts' }
    Write-GpuControlLog "Installed GPU control tasks $shortcutState."
}

$created | Format-Table -AutoSize

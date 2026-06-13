[CmdletBinding()]
param(
    [switch] $RestorePreferences,
    [switch] $RemovePackage,
    [switch] $WhatIf
)

. "$PSScriptRoot\GpuControl.Common.ps1"

$actions = @()

$actions += Unregister-GpuControlLogonTask -Preview:$WhatIf
$actions += Unregister-GpuControlDeviceEventTask -Preview:$WhatIf

if ($RestorePreferences) {
    $backup = Get-InitialBackupPath
    if (Test-Path -LiteralPath $backup) {
        $actions += Restore-UserGpuPreferenceSnapshot -Path $backup -Preview:$WhatIf
    }
    else {
        $actions += [pscustomobject]@{
            Action = 'Restore'
            Path = $backup
            Preview = [bool] $WhatIf
            Status = 'NoBackupFound'
        }
    }
}

$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutNames = @(
    'GPU State.lnk',
    'Apply GPU Policy.lnk',
    'Prepare eGPU Eject.lnk',
    'Export GPU Support Bundle.lnk',
    'Rollback GPU Policy.lnk'
)

foreach ($name in $shortcutNames) {
    $shortcut = Join-Path $desktop $name
    if (Test-Path -LiteralPath $shortcut) {
        if ($WhatIf) {
            $actions += [pscustomobject]@{ Action = 'RemoveShortcut'; Path = $shortcut; Preview = $true }
        }
        else {
            Remove-Item -LiteralPath $shortcut -Force
            $actions += [pscustomobject]@{ Action = 'RemoveShortcut'; Path = $shortcut; Preview = $false }
        }
    }
}

if ($RemovePackage) {
    $root = Get-GpuControlRoot
    if ($WhatIf) {
        $actions += [pscustomobject]@{ Action = 'RemovePackage'; Path = $root; Preview = $true }
    }
    else {
        Write-Host "Package removal requested. Close this PowerShell window after completion if removal fails because scripts are in use."
        Remove-Item -LiteralPath $root -Recurse -Force
        $actions += [pscustomobject]@{ Action = 'RemovePackage'; Path = $root; Preview = $false }
    }
}

$actions | Format-Table -AutoSize

[CmdletBinding()]
param(
    [switch] $WhatIf
)

. "$PSScriptRoot\GpuControl.Common.ps1"

$backup = Get-InitialBackupPath
if (-not (Test-Path -LiteralPath $backup)) {
    [pscustomobject]@{
        Action = 'Restore'
        Preview = [bool] $WhatIf
        Backup = $backup
        Status = 'NoBackupFound'
        Message = 'No initial backup exists yet. Run Apply-GpuPolicy.ps1 once to create it before rollback is needed.'
    } | Format-List
    return
}

$result = Restore-UserGpuPreferenceSnapshot -Path $backup -Preview:$WhatIf
$result | Format-List

[CmdletBinding()]
param(
    [switch] $OpenDeviceEject,
    [switch] $Json,
    [switch] $IncludePrivateDetails
)

. "$PSScriptRoot\GpuControl.Common.ps1"

$state = Get-GpuControlState
$processes = @(Get-NvidiaLikelyProcesses)

$result = [pscustomobject]@{
    Timestamp = (Get-Date).ToString('o')
    State = $state.State
    NvidiaOnline = $state.NvidiaOnline
    Processes = if ($IncludePrivateDetails) { $processes } else { ConvertTo-SanitizedProcessList -Processes $processes }
    PrivateDetailsIncluded = [bool] $IncludePrivateDetails
    Recommendation = if (@($processes).Count -gt 0) {
        'Close or stop listed processes before ejecting the eGPU.'
    }
    else {
        'No configured or compute NVIDIA users detected. Use the Windows safe eject UI before unplugging.'
    }
}

if ($Json) {
    $result | ConvertTo-Json -Depth 8
    return
}

Write-Host "GPU state: $($state.State)"
if (-not $state.NvidiaOnline) {
    Write-Host "NVIDIA eGPU is not online."
    return
}

if (@($processes).Count -gt 0) {
    Write-Host "Possible NVIDIA users detected. Close the ones you consider safe before ejecting:" -ForegroundColor Yellow
    if ($IncludePrivateDetails) {
        $processes | Format-Table Id, ProcessName, ProtectedOnEject, Source, Path -AutoSize
    }
    else {
        ConvertTo-SanitizedProcessList -Processes $processes | Format-Table -AutoSize
        Write-Host "Process paths are hidden by default. Use -IncludePrivateDetails only for local troubleshooting."
    }
}
else {
    Write-Host "No configured or compute NVIDIA users detected."
}

Write-Host ""
Write-Host "Use Windows native safe-eject UI before unplugging the eGPU."
Write-Host "This script does not kill processes by default."

if ($OpenDeviceEject) {
    Start-Process -FilePath "$env:SystemRoot\System32\rundll32.exe" -ArgumentList 'shell32.dll,Control_RunDLL hotplug.dll' -WindowStyle Normal
}
else {
    Write-Host "Run with -OpenDeviceEject to open the Windows safe-remove devices dialog."
}

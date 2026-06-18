# Case Study: Hybrid GPU Conflicts on a Laptop with an External Desktop NVIDIA GPU Enclosure

## Context

This toolkit was built for a Windows laptop that needs both mobility and high-performance external graphics. To avoid exposing personally linkable device details, this public case study keeps only sanitized hardware categories:

- Windows ultrabook
- Intel integrated GPU
- NVIDIA desktop-class external GPU
- USB4/Thunderbolt-class eGPU enclosure
- Windows 11

The goal is not to force every process onto NVIDIA forever. The required behavior is:

- When the eGPU is detached, fall back to Intel.
- When the eGPU is attached and healthy, prefer NVIDIA for games, AI, CUDA, video, and heavy graphics workloads.
- Keep browsers, chat apps, office tools, terminals, and lightweight utilities on Intel.
- When an external monitor is connected directly to the NVIDIA eGPU, let NVIDIA handle that display path and heavy work.
- In external-only mode with the laptop lid closed, prefer NVIDIA while keeping Intel available as a fallback.
- If things break, export a support bundle, roll back preferences, and uninstall the toolkit.
- Desktop shortcuts are not created by default. Use `-CreateDesktopShortcuts` only if they are wanted.

## Root Cause Model

This failure mode is rarely caused by a single setting. Two layers interact:

1. **Transport layer**: an eGPU sits behind a USB4/Thunderbolt/PCIe tunnel. Corrected PCIe errors, transient disconnects, re-enumeration, power instability, or driver recovery can surface as device loss to graphics APIs.
2. **Application layer**: many applications choose a GPU once at startup. Launchers, WebView/CEF helpers, game binaries, renderers, and CUDA workers may be separate executables. Some applications do not recover cleanly from `DXGI_ERROR_DEVICE_REMOVED`, TDR, or adapter reset.

Disabling Intel, hardcoding everything to NVIDIA, or applying global PCIe workarounds would undermine hot-plug behavior and laptop portability.

## State Machine

The toolkit runs only on manual invocation, logon, device-change events, or support bundle export. It does not use high-frequency polling.

| State | Condition | Policy |
| --- | --- | --- |
| `Detached` | NVIDIA offline | Remove or avoid PreferNvidia entries; use Intel |
| `Attached-InternalOnly` | NVIDIA online, internal panel only | Prefer NVIDIA for heavy workloads; keep light apps on Intel |
| `Attached-Extended` | Internal panel plus NVIDIA external display | Prefer NVIDIA for external-display/heavy workloads; keep internal-panel light work on Intel |
| `Attached-ExternalOnly` | Lid closed or external-only display | Prefer NVIDIA for graphics and compute; keep Intel as fallback |
| `Attached-Degraded` | WHEA 17, TDR, or reset evidence is increasing | Stop assigning new heavy workloads to NVIDIA |

Monitor detection separates connected devices from desktop-active displays. EDID visibility only means Windows can still see the monitor device; it does not prove the monitor is part of the current desktop. A black, powered-off, or desktop-disabled external display should be treated as internal-only use.

## Why Current-User Graphics Preferences

On modern Windows versions, per-app GPU choice is primarily controlled by Windows graphics preferences. The toolkit therefore changes only:

```text
HKCU\Software\Microsoft\DirectX\UserGpuPreferences
```

Benefits:

- Low risk and easy rollback.
- Preserves Intel + NVIDIA coexistence.
- Does not affect other Windows users.
- Does not need a tray app.
- Does not disable devices or modify BIOS settings.

## Common Operations

### Check State

```powershell
Set-Location .\gpu-control
.\scripts\Check-GpuState.ps1
```

### Preview Policy

```powershell
.\scripts\Apply-GpuPolicy.ps1 -WhatIf
```

### Apply Policy

```powershell
.\scripts\Apply-GpuPolicy.ps1
```

The first real application backs up the original `UserGpuPreferences` values.

### Before Hot-Unplug

```powershell
.\scripts\Prepare-EgpuEject.ps1 -OpenDeviceEject
```

The script lists processes that may be using NVIDIA and opens the native Windows eject entry point. It does not kill processes by default.

### Export a Support Bundle

```powershell
.\scripts\Export-GpuSupportBundle.ps1
```

Support bundles are useful for vendors, communities, or future troubleshooting. Read [SECURITY.md](../SECURITY.md) before sharing one publicly.

### Roll Back

```powershell
.\scripts\Rollback-GpuPolicy.ps1
```

### Uninstall

```powershell
.\scripts\Uninstall-GpuControl.ps1 -RestorePreferences -RemovePackage
```

## Non-Goals

- Do not disable the Intel iGPU.
- Do not force every program onto NVIDIA forever.
- Do not modify BIOS settings.
- Do not modify system-wide display drivers.
- Do not change TDR timeout registry values by default.
- Do not use `pciexpress forcedisable`.
- Do not promise that a running graphics application survives eGPU removal.

## When Hardware-Level Troubleshooting Is Still Needed

If WHEA-Logger 17, TDR, or device-removed events keep increasing, investigate:

- USB4/Thunderbolt cables and ports
- eGPU enclosure firmware
- GPU power delivery and PSU headroom
- NVIDIA and Intel driver versions
- BIOS and USB4/Thunderbolt firmware
- External monitor connection path
- Per-application rendering API and launch flags

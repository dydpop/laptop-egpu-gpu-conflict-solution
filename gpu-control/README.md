# Windows 混合 GPU 动态策略与回滚方案

## Windows Hybrid GPU Dynamic Policy and Rollback Toolkit

这个目录是 Intel 集成显卡 + NVIDIA eGPU 的轻量控制包。它不禁用核显、不改 BIOS、不改系统驱动，也不使用 `pciexpress forcedisable`。默认只修改当前用户的 Windows 图形偏好：

This directory contains the lightweight control toolkit for an Intel integrated GPU + NVIDIA eGPU setup. It does not disable the iGPU, modify BIOS settings, replace system drivers, or use destructive PCIe workarounds. By default it changes only the current user's Windows graphics preferences:

```text
HKCU\Software\Microsoft\DirectX\UserGpuPreferences
```

## 状态模型 / State Model

- `Detached`：NVIDIA eGPU 不在线，只使用 Intel。 / NVIDIA eGPU is offline; use Intel.
- `Attached-InternalOnly`：NVIDIA 在线，只用笔记本内屏；游戏、图形和 AI 程序可优先 NVIDIA。 / NVIDIA is online with the internal panel only; games, graphics, and AI apps may prefer NVIDIA.
- `Attached-Extended`：内屏 + 插在 NVIDIA 上的副屏同时使用；重负载优先 NVIDIA，轻应用保留 Intel。 / Internal panel plus an external display on NVIDIA; heavy workloads prefer NVIDIA while light apps stay on Intel.
- `Attached-ExternalOnly`：合盖或只用副屏；NVIDIA 作为主要图形设备，Intel 保留为 fallback。 / Lid-closed or external-only mode; NVIDIA is primary while Intel remains a fallback.
- `Attached-Degraded`：NVIDIA 在线但 WHEA 17、TDR 或设备重置异常增长；暂停把新重负载推到 NVIDIA。 / NVIDIA is online but WHEA 17, TDR, or reset evidence is increasing; stop assigning new heavy workloads to NVIDIA.

`Connected monitors` 只表示 Windows 能看到显示器设备/EDID；`Desktop-active monitors` 才表示屏幕当前有桌面区域和分辨率。外屏黑屏、关闭或未被 Windows 用作桌面时，不应触发 `Attached-Extended`。即使 `State` 因 WHEA/TDR 变成 `Attached-Degraded`，`Display mode` 仍会单独给出实际显示模式。 / `Connected monitors` means Windows can see the monitor device/EDID; `Desktop-active monitors` means the screen currently has a desktop area and resolution. A black, powered-off, or desktop-disabled external display should not trigger `Attached-Extended`. Even when `State` becomes `Attached-Degraded` because of WHEA/TDR, `Display mode` still reports the actual display mode separately.

## 常用命令 / Common Commands

更完整的中文使用说明见 [../docs/USAGE.zh-CN.md](../docs/USAGE.zh-CN.md)。

在 PowerShell 中运行 / Run in PowerShell:

```powershell
Set-Location .\gpu-control
Copy-Item .\config\gpu-policy.example.json .\config\gpu-policy.json

# 只读检查当前状态 / Read-only state check
.\scripts\Check-GpuState.ps1

# 预览将要应用的图形偏好，不改系统 / Preview policy changes
.\scripts\Apply-GpuPolicy.ps1 -WhatIf

# 应用策略。第一次运行会自动备份原始 UserGpuPreferences。 / Apply policy and create the initial backup on first run
.\scripts\Apply-GpuPolicy.ps1

# 拔 eGPU 前检查可能占用 NVIDIA 的进程，并打开 Windows 原生弹出设备界面 / Prepare for eGPU eject
.\scripts\Prepare-EgpuEject.ps1 -OpenDeviceEject

# 导出支持包，适合上传给厂商/社区/下一个排查者 / Export a support bundle
.\scripts\Export-GpuSupportBundle.ps1

# 回滚到首次实际应用策略前的图形偏好 / Roll back graphics preferences
.\scripts\Rollback-GpuPolicy.ps1

# 创建登录任务、设备变化触发任务；默认不创建桌面快捷方式 / Install scheduled tasks; desktop shortcuts are opt-in
.\scripts\Install-GpuControl.ps1

# 如确实需要桌面快捷方式 / If desktop shortcuts are wanted
.\scripts\Install-GpuControl.ps1 -CreateDesktopShortcuts
```

`config\gpu-policy.json` 是本机私有配置，可能包含应用路径和显示器匹配规则。公开分享时只提交 `config\gpu-policy.example.json`。

`config\gpu-policy.json` is a local private file that may contain application paths and monitor matching rules. Share only `config\gpu-policy.example.json` publicly.

## 回滚和删除 / Rollback and Removal

只回滚图形偏好。备份在第一次运行 `Apply-GpuPolicy.ps1` 时自动创建；如果还没应用过策略，回滚脚本会提示没有备份且不会改系统。

Rollback only graphics preferences. The first real `Apply-GpuPolicy.ps1` run creates the backup. If no backup exists, the rollback script reports that and does not change the system.

```powershell
.\scripts\Rollback-GpuPolicy.ps1
```

回滚图形偏好并删除可选桌面快捷方式、登录计划任务、设备变化触发任务：

Rollback graphics preferences and remove optional desktop shortcuts, the logon task, and the device-change task:

```powershell
.\scripts\Uninstall-GpuControl.ps1 -RestorePreferences
```

回滚并删除整个脚本包 / Roll back and remove the whole package:

```powershell
.\scripts\Uninstall-GpuControl.ps1 -RestorePreferences -RemovePackage
```

## 支持包内容 / Support Bundle Contents

`Export-GpuSupportBundle.ps1` 会在 `support-bundles\` 中生成目录和 zip，包含：

`Export-GpuSupportBundle.ps1` creates a directory and zip under `support-bundles\` with:

- `summary.txt`
- `gpu-state.json`
- `gpu-policy.sanitized.json`
- `user-gpu-preferences-summary.json`

默认支持包是脱敏的。只有显式加 `-IncludePrivateDetails` 才会包含原始 `gpu-policy.json`、完整图形偏好、系统/BIOS/电脑型号、电源策略和日志。

Support bundles are sanitized by default. Use `-IncludePrivateDetails` only for local troubleshooting or carefully redacted vendor reports.

## 重要边界 / Limits

脚本可以在启动前选择 GPU 偏好，但不能把已经运行的 DirectX/Vulkan/CUDA 程序从 NVIDIA 无感迁移到 Intel。拔 eGPU 前应先关闭正在使用 NVIDIA 的程序，再通过 Windows 原生“安全删除硬件/弹出设备”流程断开。

The scripts can set GPU preferences before an app starts, but cannot live-migrate an already-running DirectX/Vulkan/CUDA process from NVIDIA to Intel. Before unplugging the eGPU, close processes that use NVIDIA and then use the native Windows safe-eject flow.
